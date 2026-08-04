import 'package:flutter/material.dart';

import '../../core/app_paths.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/skytax_database.dart';
import '../../data/local_config.dart';
import '../../data/models/models.dart';
import '../../data/repositories/aircraft_repository.dart';
import '../../data/repositories/audit_repository.dart';
import '../../data/repositories/dosa_tariff_repository.dart';
import '../../data/repositories/pending_payment_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/dosa_schedule.dart';
import '../../domain/invoicing.dart';
import '../../domain/payment_simulator.dart';
import '../../domain/tax_calculator.dart';

/// Estado global de la aplicación.
///
/// Orquesta la configuración local, la base de datos del aeropuerto, los
/// repositorios y los servicios de dominio (cálculo, pago y facturación).
class AppController extends ChangeNotifier {
  AppController({required this.paths}) {
    _dbase = SkyTaxDatabase(dataDirectory: paths.data);
    _configStore = LocalConfigStore(baseDirectory: paths.base);
    aircraft = AircraftRepository(_dbase);
    users = UserRepository(_dbase);
    invoices = InvoiceRepository(_dbase);
    settings = SettingsRepository(_dbase);
    auditLog = AuditRepository(_dbase);
    dosaTariffs = DosaTariffRepository(_dbase);
    pendingPayments = PendingPaymentRepository(_dbase);
    invoiceOutput = TxtInvoiceOutput(directory: paths.facturas);
  }

  final AppPaths paths;

  late final SkyTaxDatabase _dbase;
  late final LocalConfigStore _configStore;

  late final AircraftRepository aircraft;
  late final UserRepository users;
  late final InvoiceRepository invoices;
  late final SettingsRepository settings;
  late final AuditRepository auditLog;
  late final DosaTariffRepository dosaTariffs;
  late final PendingPaymentRepository pendingPayments;

  /// Puerto de emisión de facturas (implementación TXT para la demo).
  late final InvoiceOutput invoiceOutput;

  static const TaxCalculator calculator = TaxCalculator();
  final PaymentSimulator payments = const PaymentSimulator();

  LocalConfig config = LocalConfig.defaults;
  AppStrings strings = AppStrings.es;
  Locale locale = const Locale('es');
  double taxRate = 15;
  AppUser? currentAdmin;

  /// Usuario registrado en la auditoría para la operación actual.
  String get auditUser => currentAdmin?.username ?? 'kiosco';

  Future<void> bootstrap() async {
    config = await _configStore.load();
    await _dbase.open(config.airportCode);
    await _reloadSettings();
    AppLogger.instance
        .info('SkyTax iniciado en ${config.airportDisplay}');
  }

  Future<void> _reloadSettings() async {
    taxRate = await settings.getDouble(SettingsRepository.keyTaxRate, 15);
  }

  void setLanguage(String code) {
    strings = code == 'en' ? AppStrings.en : AppStrings.es;
    locale = Locale(code == 'en' ? 'en' : 'es');
    notifyListeners();
  }

  Future<void> audit(String action, String details) async {
    try {
      await auditLog.log(AuditEntry(
        createdAt: DateTime.now(),
        username: auditUser,
        action: action,
        details: details,
        airportCode: config.airportCode,
      ));
    } catch (e, st) {
      AppLogger.instance.error('No se pudo registrar auditoría', e, st);
    }
  }

  /// Busca la matrícula en la base de datos local y calcula los impuestos
  /// según las reglas de negocio (DOSA automática para aeronaves foráneas).
  Future<TaxQuote> consult({
    required String registration,
    required String typedModel,
    required int passengers,
  }) async {
    await _reloadSettings();
    final Aircraft? found = await aircraft.findByRegistration(registration);

    // El modelo efectivo decide qué fila de la tabla DOSA aplica.
    final String model =
        (found?.model ?? typedModel).trim();
    final DosaTariff? tariff = await tariffForModel(model);

    // Si la aeronave difirió el pago, la permanencia se cuenta desde que
    // cargó sus datos; si paga en el momento, la permanencia es cero y le
    // corresponde el tramo «hasta 2 horas».
    final PendingPayment? pending =
        await pendingPayments.findByRegistration(registration);
    final Duration elapsed =
        pending?.elapsedUntil(DateTime.now()) ?? Duration.zero;

    final TaxQuote quote = calculator.quote(
      registration: registration,
      typedModel: typedModel,
      passengers: passengers,
      aircraft: found,
      taxRate: taxRate,
      dosaTariff: tariff,
      elapsed: elapsed,
    );
    AppLogger.instance.info(
      'Consulta ${quote.registration}: '
      '${quote.isLocal ? 'local' : 'foránea (DOSA)'} — '
      'total ${quote.total.toStringAsFixed(2)}',
    );
    return quote;
  }

  /// Busca la tarifa DOSA del modelo indicado, sin distinguir mayúsculas ni
  /// espacios sobrantes. Devuelve `null` si el modelo no está tabulado.
  ///
  /// La usa también la pantalla de selección de tramo: sin tarifa no hay
  /// importes que ofrecer y el flujo salta directo al resumen.
  Future<DosaTariff?> tariffForModel(String model) async {
    final String needle = model.trim().toLowerCase();
    if (needle.isEmpty) return null;
    final List<DosaTariff> all = await dosaTariffs.getAll();
    for (final DosaTariff t in all) {
      if (t.model.trim().toLowerCase() == needle) return t;
    }
    return null;
  }

  /// El usuario eligió pagar más tarde: la aeronave queda registrada como
  /// pendiente y el reloj de permanencia empieza a correr desde ahora.
  ///
  /// Si ya figuraba como pendiente se conserva el registro original, de modo
  /// que diferir el pago varias veces no reinicia el conteo.
  Future<PendingPayment> deferPayment(TaxQuote quote) async {
    final PendingPayment saved = await pendingPayments.upsert(
      PendingPayment(
        registration: quote.registration,
        model: quote.aircraftModel,
        passengers: quote.passengers,
        createdAt: DateTime.now(),
      ),
    );
    await audit(
      'PAGO_DIFERIDO',
      'Aeronave ${saved.registration} quedó pendiente de pago',
    );
    AppLogger.instance
        .info('Pago diferido: ${saved.registration} desde ${saved.createdAt}');
    return saved;
  }

  /// Registra el pago: asigna número de factura, emite el documento a través
  /// del puerto de salida, persiste la factura y deja rastro de auditoría.
  Future<Invoice> finalizeSale(TaxQuote quote, String paymentMethod) async {
    final int seq = await settings.nextInvoiceSequence();
    final DateTime now = DateTime.now();
    Invoice invoice = Invoice(
      number: Formatters.invoiceNumber(seq),
      createdAt: now,
      airportCode: config.airportCode,
      airportName: config.airportName,
      registration: quote.registration,
      aircraftModel: quote.aircraftModel,
      passengers: quote.passengers,
      taxRate: quote.taxRate,
      taxSubtotal: quote.taxSubtotal,
      dosa: quote.dosa,
      total: quote.total,
      paymentMethod: paymentMethod,
      filePath: '',
      createdBy: auditUser,
      // La vigencia se cuenta desde el pago, no desde que se eligió el tramo:
      // entre ambos momentos median los pasos de método de pago y cobro, y la
      // factura quedaría diciendo que caduca antes de haberse emitido.
      validUntil: quote.dosaBracket == null
          ? null
          : dosaValidUntil(now, quote.dosaBracket!),
    );
    final String path = await invoiceOutput.emit(invoice, strings);
    invoice = invoice.copyWith(filePath: path);
    await invoices.insert(invoice);
    // La deuda quedó saldada: la aeronave sale de la lista de pendientes y su
    // reloj de permanencia se detiene.
    await pendingPayments.deleteByRegistration(invoice.registration);
    await audit(
      'PAGO',
      'Factura ${invoice.number} — ${invoice.registration} — '
          '${strings.paymentMethodName(paymentMethod)} — '
          'total ${Formatters.money(invoice.total)}',
    );
    AppLogger.instance.info('Factura generada: $path');
    return invoice;
  }

  Future<bool> adminLogin(String username, String password) async {
    final AppUser? user = await users.authenticate(username, password);
    if (user == null || !user.isAdmin) {
      await audit('LOGIN_FALLIDO', 'Intento de acceso con usuario "$username"');
      return false;
    }
    currentAdmin = user;
    await audit('LOGIN', 'Acceso al panel administrativo');
    notifyListeners();
    return true;
  }

  Future<void> adminLogout() async {
    await audit('LOGOUT', 'Salida del panel administrativo');
    currentAdmin = null;
    notifyListeners();
  }

  /// Actualiza en memoria los datos del administrador autenticado
  /// (tras editar su nombre o usuario desde el panel).
  void refreshCurrentAdmin(AppUser user) {
    if (currentAdmin?.id == user.id) {
      currentAdmin = user;
      notifyListeners();
    }
  }

  Future<void> updateRates({required double newTaxRate}) async {
    await settings.set(SettingsRepository.keyTaxRate, '$newTaxRate');
    await audit(
      'CONFIGURACION',
      'Tasa aeroportuaria: $newTaxRate EUR por pasajero',
    );
    await _reloadSettings();
    notifyListeners();
  }

  /// Cambia el aeropuerto del terminal: guarda la configuración local y abre
  /// (o crea) la base de datos independiente de ese aeropuerto.
  Future<void> changeAirport(String code, String name) async {
    config = LocalConfig(
      airportCode: code.trim().toUpperCase(),
      airportName: name.trim(),
    );
    await _configStore.save(config);
    await _dbase.open(config.airportCode);
    await _reloadSettings();
    await audit('AEROPUERTO', 'Terminal asignado a ${config.airportDisplay}');
    notifyListeners();
  }
}
