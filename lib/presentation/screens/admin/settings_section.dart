import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../data/models/models.dart';
import '../../../domain/dosa_tariff_import.dart';
import '../../state/app_controller.dart';
import '../../widgets/kiosk_widgets.dart';

/// Configuración de tarifas y del aeropuerto del terminal.
class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key});

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  late final TextEditingController _taxRate;
  late final TextEditingController _airportCode;
  late final TextEditingController _airportName;
  bool _savingRates = false;
  bool _savingAirport = false;

  List<DosaTariff> _tariffs = const [];
  bool _loadingTariffs = true;

  @override
  void initState() {
    super.initState();
    final AppController controller = context.read<AppController>();
    _taxRate = TextEditingController(text: '${controller.taxRate}');
    _airportCode = TextEditingController(text: controller.config.airportCode);
    _airportName = TextEditingController(text: controller.config.airportName);
    _loadTariffs();
  }

  @override
  void dispose() {
    _taxRate.dispose();
    _airportCode.dispose();
    _airportName.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadTariffs() async {
    final AppController controller = context.read<AppController>();
    try {
      final List<DosaTariff> items = await controller.dosaTariffs.getAll();
      if (!mounted) return;
      setState(() {
        _tariffs = items;
        _loadingTariffs = false;
      });
    } catch (e, st) {
      AppLogger.instance
          .error('No se pudieron cargar las tarifas DOSA', e, st);
      if (mounted) setState(() => _loadingTariffs = false);
    }
  }

  /// Alta de una tarifa: primero se pregunta por la via.
  ///
  /// La carga automatica da de alta de golpe toda la tabla oficial; la manual
  /// sirve para una aeronave suelta o para corregir una que falte.
  Future<void> _addTariff() async {
    final _TariffMode? mode = await showDialog<_TariffMode>(
      context: context,
      builder: (_) => const _TariffModeDialog(),
    );
    if (mode == null || !mounted) return;
    if (mode == _TariffMode.manual) {
      await _editTariff();
    } else {
      await _importTariffs();
    }
  }

  /// Carga masiva desde la hoja de tarifas oficial.
  ///
  /// Los modelos que ya tienen tarifa se dejan intactos: el administrador
  /// pudo haberlos ajustado a mano y una importacion no debe pisarlos.
  Future<void> _importTariffs() async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    try {
      final List<PlatformFile> picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      // Lista vacia: el administrador cerro el selector sin elegir nada.
      if (picked.isEmpty || !mounted) return;
      final PlatformFile file = picked.first;
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() => _loadingTariffs = true);
      final xls.Excel book = xls.Excel.decodeBytes(bytes);
      if (book.tables.isEmpty) {
        if (mounted) {
          setState(() => _loadingTariffs = false);
          _snack(s.importFailed);
        }
        return;
      }
      final List<DosaTariff> existing = await controller.dosaTariffs.getAll();
      final Set<String> existingModels = {
        for (final DosaTariff t in existing) t.model,
      };

      // Se recorren todas las hojas y se elige la que mas aeronaves aporta.
      // Tomar la primera a ciegas falla en cuanto el libro trae una portada o
      // una hoja auxiliar por delante de la tabla.
      DosaTariffImport? best;
      for (final xls.Sheet sheet in book.tables.values) {
        final List<List<String?>> rows = [
          for (final List<xls.Data?> row in sheet.rows)
            [for (final xls.Data? cell in row) cell?.value?.toString()],
        ];
        final DosaTariffImport candidate =
            parseDosaTariffSheet(rows, existingModels: existingModels);
        final int recognised =
            candidate.toInsert.length + candidate.skippedExisting.length;
        final int bestSoFar =
            best == null ? -1 : best.toInsert.length + best.skippedExisting.length;
        if (recognised > bestSoFar) best = candidate;
      }
      final DosaTariffImport result = best ??
          const DosaTariffImport(
              toInsert: [], skippedExisting: [], unreadableRows: 0);

      for (final DosaTariff tariff in result.toInsert) {
        await controller.dosaTariffs.insert(tariff);
      }
      if (result.toInsert.isNotEmpty) {
        await controller.audit(
          'DOSA_TARIFAS_IMPORTADAS',
          '${result.toInsert.length} modelos desde ${file.name}',
        );
      }
      await _loadTariffs();
      if (!mounted) return;

      // Resumen con solo los tramos que tienen algo que contar.
      final List<String> parts = [
        s.importedCount(result.toInsert.length),
        if (result.skippedExisting.isNotEmpty)
          s.skippedCount(result.skippedExisting.length),
        if (result.unreadableRows > 0)
          s.unreadableCount(result.unreadableRows),
      ];
      _snack(result.isEmpty && result.skippedExisting.isEmpty
          ? s.importNothingNew
          : parts.join(' · '));
    } catch (e, st) {
      AppLogger.instance.error('No se pudo importar la tabla de tarifas', e, st);
      if (mounted) {
        setState(() => _loadingTariffs = false);
        _snack(s.importFailed);
      }
    }
  }

  Future<void> _editTariff([DosaTariff? existing]) async {
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (_) => _DosaTariffDialog(existing: existing),
    );
    if (saved == true) await _loadTariffs();
  }

  Future<void> _deleteTariff(DosaTariff tariff) async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.delete),
        content: Text(s.confirmDelete(tariff.model)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.dosaTariffs.delete(tariff.id!);
      await controller.audit('DOSA_TARIFA_ELIMINADA', 'Modelo ${tariff.model}');
      await _loadTariffs();
    } catch (e, st) {
      AppLogger.instance.error('No se pudo eliminar la tarifa', e, st);
      if (mounted) _snack(s.errorGeneric);
    }
  }

  Future<void> _saveRates() async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    final double? taxRate = double.tryParse(_taxRate.text.trim());
    if (taxRate == null || taxRate <= 0) {
      _snack(s.invalidNumber);
      return;
    }
    setState(() => _savingRates = true);
    try {
      await controller.updateRates(newTaxRate: taxRate);
      if (mounted) _snack(s.settingsSaved);
    } catch (e, st) {
      AppLogger.instance.error('No se pudo guardar la configuración', e, st);
      if (mounted) _snack(s.errorGeneric);
    } finally {
      if (mounted) setState(() => _savingRates = false);
    }
  }

  Future<void> _saveAirport() async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    final String code = _airportCode.text.trim().toUpperCase();
    final String name = _airportName.text.trim();
    if (code.isEmpty || name.isEmpty) {
      _snack(s.requiredField);
      return;
    }
    setState(() => _savingAirport = true);
    try {
      await controller.changeAirport(code, name);
      _taxRate.text = '${controller.taxRate}';
      await _loadTariffs();
      if (mounted) _snack(s.settingsSaved);
    } catch (e, st) {
      AppLogger.instance.error('No se pudo cambiar el aeropuerto', e, st);
      if (mounted) _snack(s.errorGeneric);
    } finally {
      if (mounted) setState(() => _savingAirport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.sectionSettings,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              _ratesCard(s),
              const SizedBox(height: 24),
              _narrowCard(child: _airportCard(s)),
            ],
          ),
        ),
      ),
    );
  }

  /// Las tarjetas de formulario se mantienen angostas aunque la página sea
  /// ancha; solo la tabla de tarifas aprovecha todo el espacio disponible.
  Widget _narrowCard({required Widget child}) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: child,
        ),
      );

  /// Tarifas del aeropuerto en un único recuadro: la tasa por pasajero y,
  /// debajo, la tabla de tarifas DOSA por modelo que sustituyó al antiguo
  /// importe plano de DOSA.
  Widget _ratesCard(AppStrings s) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // La tasa por pasajero conserva el ancho cómodo de formulario
            // aunque el recuadro sea ancho por la tabla.
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 592),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _taxRate,
                      style: const TextStyle(fontSize: 20),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: s.taxRateField),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 60,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save_rounded),
                        label: Text(s.save),
                        onPressed: _savingRates ? null : _saveRates,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 40),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Text(
                  s.dosaTariffsTitle,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800),
                ),
                FloatingActionButton(
                  heroTag: null,
                  tooltip: s.newDosaTariff,
                  onPressed: _addTariff,
                  child: const Icon(Icons.add_rounded, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loadingTariffs)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_tariffs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    s.noRecords,
                    style:
                        TextStyle(fontSize: 17, color: scheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              DosaTariffTable(
                tariffs: _tariffs,
                modelLabel: s.modelField,
                bracketLabels: _bracketLabels(s),
                editTooltip: s.edit,
                deleteTooltip: s.delete,
                onEdit: _editTariff,
                onDelete: _deleteTariff,
              ),
          ],
        ),
      ),
    );
  }

  Widget _airportCard(AppStrings s) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _airportCode,
              style: const TextStyle(fontSize: 20),
              inputFormatters: [UpperCaseTextFormatter()],
              decoration: InputDecoration(
                  labelText: s.airportCodeField, hintText: 'SVMI'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _airportName,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                  labelText: s.airportNameField, hintText: 'Maiquetía'),
            ),
            const SizedBox(height: 12),
            Text(
              s.airportChangedNote,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 60,
              child: FilledButton.icon(
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(s.save),
                onPressed: _savingAirport ? null : _saveAirport,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Los seis encabezados de tramo, en el orden de [DosaTariff.brackets].
  List<String> _bracketLabels(AppStrings s) => <String>[
        s.colUpTo2h,
        s.colOneDay,
        s.colDays2To7,
        s.colDays8To14,
        s.colDays15To21,
        s.colDays22To30,
      ];
}

/// Alta y edición de una fila de la tabla de tarifas DOSA.
class _DosaTariffDialog extends StatefulWidget {
  const _DosaTariffDialog({this.existing});

  final DosaTariff? existing;

  @override
  State<_DosaTariffDialog> createState() => _DosaTariffDialogState();
}

class _DosaTariffDialogState extends State<_DosaTariffDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _model =
      TextEditingController(text: widget.existing?.model ?? '');
  late final List<TextEditingController> _amounts = List.generate(
    6,
    (i) => TextEditingController(
      text: widget.existing == null
          ? ''
          : _plain(widget.existing!.brackets[i]),
    ),
  );
  String? _modelError;
  bool _saving = false;

  /// Muestra 120 en lugar de 120.0 para que el campo sea cómodo de editar.
  static String _plain(double value) =>
      value == value.roundToDouble() ? '${value.toInt()}' : '$value';

  @override
  void dispose() {
    _model.dispose();
    for (final TextEditingController c in _amounts) {
      c.dispose();
    }
    super.dispose();
  }

  double _valueAt(int index) =>
      double.tryParse(_amounts[index].text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    setState(() => _modelError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final bool duplicated = await controller.dosaTariffs.modelExists(
        _model.text,
        excludeId: widget.existing?.id,
      );
      if (duplicated) {
        setState(() {
          _saving = false;
          _modelError = s.modelExists;
        });
        return;
      }
      final DosaTariff tariff = DosaTariff(
        id: widget.existing?.id,
        model: _model.text.trim(),
        upTo2Hours: _valueAt(0),
        oneDay: _valueAt(1),
        days2To7: _valueAt(2),
        days8To14: _valueAt(3),
        days15To21: _valueAt(4),
        days22To30: _valueAt(5),
      );
      if (widget.existing == null) {
        await controller.dosaTariffs.insert(tariff);
        await controller.audit('DOSA_TARIFA_CREADA', 'Modelo ${tariff.model}');
      } else {
        await controller.dosaTariffs.update(tariff);
        await controller.audit('DOSA_TARIFA_EDITADA', 'Modelo ${tariff.model}');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      AppLogger.instance.error('No se pudo guardar la tarifa DOSA', e, st);
      if (mounted) {
        setState(() {
          _saving = false;
          _modelError = s.errorGeneric;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;
    final List<String> labels = [
      s.colUpTo2h,
      s.colOneDay,
      s.colDays2To7,
      s.colDays8To14,
      s.colDays15To21,
      s.colDays22To30,
    ];

    return AlertDialog(
      title:
          Text(widget.existing == null ? s.newDosaTariff : s.editDosaTariff),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _model,
                  style: const TextStyle(fontSize: 18),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [UpperCaseTextFormatter()],
                  decoration: InputDecoration(
                    labelText: s.modelField,
                    hintText: 'AC90',
                    errorText: _modelError,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? s.requiredField
                      : null,
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool twoColumns = constraints.maxWidth >= 420;
                    final double itemWidth = twoColumns
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < labels.length; i++)
                          SizedBox(
                            width: itemWidth,
                            child: TextFormField(
                              controller: _amounts[i],
                              style: const TextStyle(fontSize: 18),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]')),
                              ],
                              decoration: InputDecoration(
                                labelText: labels[i],
                                suffixText: '€',
                              ),
                              validator: (value) {
                                final String raw =
                                    (value ?? '').trim().replaceAll(',', '.');
                                if (raw.isEmpty) return null;
                                final double? parsed = double.tryParse(raw);
                                if (parsed == null || parsed < 0) {
                                  return s.invalidNumber;
                                }
                                return null;
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(s.save),
        ),
      ],
    );
  }
}


/// Vias de alta de una tarifa DOSA.
enum _TariffMode { auto, manual }

/// Pregunta como se quiere dar de alta la tarifa.
///
/// Las dos opciones van apiladas y a todo el ancho del dialogo: lado a lado
/// se estrechan tanto en un telefono que las palabras se parten por la mitad.
class _TariffModeDialog extends StatelessWidget {
  const _TariffModeDialog();

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;

    return AlertDialog(
      title: Text(s.newTariffModeTitle),
      // Sin ancho fijo: el dialogo se ajusta a la pantalla y solo se le pone
      // un tope para que no quede desmedido en escritorio.
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ChoiceTile(
              label: s.tariffModeAuto,
              onTap: () => Navigator.of(context).pop(_TariffMode.auto),
            ),
            const SizedBox(height: 12),
            ChoiceTile(
              label: s.tariffModeManual,
              onTap: () => Navigator.of(context).pop(_TariffMode.manual),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
      ],
    );
  }
}
