import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/input_formatters.dart';
import '../../data/models/models.dart';
import '../../domain/tax_calculator.dart';
import '../state/app_controller.dart';
import '../widgets/kiosk_widgets.dart';
import 'admin/admin_login_screen.dart';
import 'language_screen.dart';
import 'payment_timing_screen.dart';

/// Menú principal: captura de matrícula, tipo de aeronave y pasajeros.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _registration = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _passengers = TextEditingController();
  bool _loading = false;

  /// Último modelo rellenado automáticamente; permite distinguirlo de un
  /// valor escrito a mano para no pisar lo que el usuario haya tecleado.
  String? _autoFilledModel;

  @override
  void initState() {
    super.initState();
    _registration.addListener(_autofillModel);
  }

  @override
  void dispose() {
    _registration.dispose();
    _model.dispose();
    _passengers.dispose();
    super.dispose();
  }

  /// Si la matrícula corresponde a una aeronave basada en este aeropuerto,
  /// rellena el tipo de aeronave con el modelo registrado.
  Future<void> _autofillModel() async {
    final String registration = _registration.text.trim().toUpperCase();
    final AppController controller = context.read<AppController>();
    final Aircraft? aircraft = registration.isEmpty
        ? null
        : await controller.aircraft.findByRegistration(registration);
    if (!mounted) return;
    // La matrícula pudo cambiar mientras se consultaba la base de datos.
    if (_registration.text.trim().toUpperCase() != registration) return;

    if (aircraft != null) {
      // Solo se rellena si el campo está vacío o contiene un valor
      // autocompletado previamente (nunca pisa lo escrito por el usuario).
      if (_model.text.trim().isEmpty || _model.text == _autoFilledModel) {
        _model.text = aircraft.model;
        _autoFilledModel = aircraft.model;
      }
    } else if (_autoFilledModel != null && _model.text == _autoFilledModel) {
      // La matrícula dejó de coincidir: se limpia el valor autocompletado.
      _model.clear();
      _autoFilledModel = null;
    }
  }

  Future<void> _consult() async {
    if (!_formKey.currentState!.validate()) return;
    final AppController controller = context.read<AppController>();
    setState(() => _loading = true);
    try {
      final TaxQuote quote = await controller.consult(
        registration: _registration.text,
        typedModel: _model.text,
        passengers: int.parse(_passengers.text.trim()),
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PaymentTimingScreen(quote: quote),
        ),
      );
      // Al regresar (pago diferido o cancelación) el formulario se limpia
      // para dejar el kiosco listo para la siguiente aeronave.
      if (!mounted) return;
      _formKey.currentState?.reset();
      _registration.clear();
      _model.clear();
      _passengers.clear();
      _autoFilledModel = null;
    } catch (e, st) {
      AppLogger.instance.error('Error en la consulta', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.strings.errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 18),
      );

  @override
  Widget build(BuildContext context) {
    final AppController controller = context.watch<AppController>();
    final AppStrings s = controller.strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    const TextStyle fieldStyle = TextStyle(fontSize: 22);

    return KioskScaffold(
      title: 'SkyTax · ${controller.config.airportDisplay}',
      actions: [
        IconButton(
          tooltip: s.selectLanguage,
          iconSize: 28,
          icon: const Icon(Icons.language_rounded),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const LanguageScreen()),
          ),
        ),
        IconButton(
          tooltip: s.adminPanel,
          iconSize: 28,
          icon: const Icon(Icons.admin_panel_settings_rounded),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AdminLoginScreen()),
          ),
        ),
        const SizedBox(width: 8),
      ],
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.consultTitle,
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  s.consultSubtitle,
                  style: TextStyle(
                      fontSize: 17, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _registration,
                  style: fieldStyle,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [UpperCaseTextFormatter()],
                  decoration: _decoration(s.registrationLabel, 'YV1234'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? s.enterRegistration
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _model,
                  style: fieldStyle,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [UpperCaseTextFormatter()],
                  decoration: _decoration(s.aircraftTypeLabel, 'AC90'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? s.enterAircraftType
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passengers,
                  style: fieldStyle,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration(s.passengersLabel, '95'),
                  validator: (value) {
                    final int? n = int.tryParse((value ?? '').trim());
                    return (n == null || n <= 0) ? s.invalidPassengers : null;
                  },
                  onFieldSubmitted: (_) => _consult(),
                ),
                const SizedBox(height: 32),
                BigActionButton(
                  label: s.consult,
                  icon: _loading ? null : Icons.arrow_forward_rounded,
                  onPressed: _loading ? null : _consult,
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
