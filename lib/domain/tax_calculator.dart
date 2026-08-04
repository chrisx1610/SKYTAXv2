import '../data/models/models.dart';
import 'dosa_schedule.dart';

/// Resultado del cálculo de impuestos para una consulta.
class TaxQuote {
  const TaxQuote({
    required this.registration,
    required this.aircraftModel,
    required this.passengers,
    required this.taxRate,
    required this.taxSubtotal,
    required this.dosa,
    required this.total,
    required this.isLocal,
    this.elapsed = Duration.zero,
    this.dosaBracket,
    this.missingTariff = false,
    this.validUntil,
  });

  final String registration;
  final String aircraftModel;
  final int passengers;

  /// Tasa aeroportuaria por pasajero.
  final double taxRate;

  /// Tasa aeroportuaria × cantidad de pasajeros.
  final double taxSubtotal;

  /// Monto DOSA aplicado (0 si la aeronave es local).
  final double dosa;
  final double total;

  /// `true` si la matrícula existe en la base de datos del aeropuerto.
  final bool isLocal;

  /// Permanencia acumulada desde que se cargaron los datos. Es cero cuando la
  /// aeronave paga en el momento.
  final Duration elapsed;

  /// Tramo de la tabla DOSA aplicado (`null` si la aeronave es local o si el
  /// modelo no figura en la tabla).
  final DosaBracket? dosaBracket;

  /// `true` cuando la aeronave es foránea —debe pagar DOSA— pero su modelo no
  /// tiene tarifa cargada, de modo que el importe quedó en cero. La interfaz
  /// lo advierte para que el administrador complete la tabla.
  final bool missingTariff;

  /// Fecha y hora hasta la que queda cubierta la estadía pagada. Solo tiene
  /// valor cuando el usuario eligió un tramo en la pantalla de tarifas; se
  /// imprime en la factura.
  final DateTime? validUntil;

  bool get hasDosa => dosa > 0;
}

/// Algoritmo de cálculo de impuestos aeroportuarios.
///
/// Regla 1: si la matrícula existe en la base de datos local, la aeronave
/// pertenece a este aeropuerto y solo paga `tasa × pasajeros`.
///
/// Regla 2: si la matrícula no existe, la aeronave pertenece a otro
/// aeropuerto y paga además la DOSA de forma automática. El operador nunca
/// selecciona los impuestos manualmente.
///
/// Regla 3: el importe de la DOSA sale de la tabla de tarifas del modelo,
/// según la permanencia transcurrida desde que se cargaron los datos. Quien
/// paga en el momento tributa el tramo «hasta 2 horas»; quien difiere el pago
/// tributa el tramo que corresponda a los días acumulados.
class TaxCalculator {
  const TaxCalculator();

  TaxQuote quote({
    required String registration,
    required String typedModel,
    required int passengers,
    required Aircraft? aircraft,
    required double taxRate,
    DosaTariff? dosaTariff,
    Duration elapsed = Duration.zero,
  }) {
    if (passengers <= 0) {
      throw ArgumentError.value(
          passengers, 'passengers', 'Debe ser mayor que cero');
    }
    final bool isLocal = aircraft != null;
    final double subtotal = taxRate * passengers;
    final double dosa = isLocal
        ? 0
        : dosaAmount(tariff: dosaTariff, elapsed: elapsed);
    return TaxQuote(
      registration: registration.trim().toUpperCase(),
      aircraftModel: isLocal ? aircraft.model : typedModel.trim(),
      passengers: passengers,
      taxRate: taxRate,
      taxSubtotal: subtotal,
      dosa: dosa,
      total: subtotal + dosa,
      isLocal: isLocal,
      elapsed: elapsed,
      dosaBracket: (isLocal || dosaTariff == null)
          ? null
          : dosaBracketFor(elapsed),
      missingTariff: !isLocal && dosaTariff == null,
    );
  }

  /// Rehace la cotización con el tramo que el usuario eligió en la pantalla
  /// de tarifas, en lugar del deducido por la permanencia acumulada.
  ///
  /// El importe pasa a ser el de ese tramo y la estadía queda cubierta desde
  /// [paidAt] hasta el tope del tramo, dato que se imprime en la factura.
  TaxQuote withBracket(
    TaxQuote base, {
    required DosaTariff? tariff,
    required DosaBracket bracket,
    required DateTime paidAt,
  }) {
    final double dosa =
        base.isLocal ? 0 : dosaAmountForBracket(tariff ?? _zero, bracket);
    return TaxQuote(
      registration: base.registration,
      aircraftModel: base.aircraftModel,
      passengers: base.passengers,
      taxRate: base.taxRate,
      taxSubtotal: base.taxSubtotal,
      dosa: dosa,
      total: base.taxSubtotal + dosa,
      isLocal: base.isLocal,
      elapsed: base.elapsed,
      dosaBracket: base.isLocal ? null : bracket,
      missingTariff: !base.isLocal && tariff == null,
      validUntil: base.isLocal ? null : dosaValidUntil(paidAt, bracket),
    );
  }

  /// Tarifa neutra para modelos sin tabular: todos los tramos en cero.
  static const DosaTariff _zero = DosaTariff(model: '');
}
