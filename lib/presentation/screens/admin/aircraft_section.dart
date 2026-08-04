import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../data/models/models.dart';
import '../../state/app_controller.dart';
import '../../widgets/kiosk_widgets.dart';

/// Mantenimiento de aeronaves con base en este aeropuerto.
class AircraftSection extends StatefulWidget {
  const AircraftSection({super.key});

  @override
  State<AircraftSection> createState() => _AircraftSectionState();
}

class _AircraftSectionState extends State<AircraftSection> {
  List<Aircraft> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AppController controller = context.read<AppController>();
    try {
      final List<Aircraft> items = await controller.aircraft.getAll();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.instance.error('No se pudieron cargar las aeronaves', e, st);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Aircraft? existing]) async {
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AircraftDialog(existing: existing),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(Aircraft aircraft) async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.delete),
        content: Text(s.confirmDelete(aircraft.registration)),
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
    await controller.aircraft.delete(aircraft.id!);
    await controller.audit(
        'AERONAVE_ELIMINADA', 'Matrícula ${aircraft.registration}');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = context.watch<AppController>();
    final AppStrings s = controller.strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: s.sectionAircraft,
            action: FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: Text(s.newAircraft),
              onPressed: () => _edit(),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Text(
                          s.noRecords,
                          style: TextStyle(
                              fontSize: 18,
                              color: scheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final Aircraft aircraft = _items[index];
                          return AdminListCard(
                            icon: Icons.flight_rounded,
                            title:
                                '${aircraft.registration} · ${aircraft.model}',
                            subtitle: aircraft.capacity == null
                                ? null
                                : '${s.passengersShort}: ${aircraft.capacity}',
                            onTap: () => _edit(aircraft),
                            actions: [
                              IconButton(
                                tooltip: s.edit,
                                iconSize: 26,
                                icon: const Icon(Icons.edit_rounded),
                                onPressed: () => _edit(aircraft),
                              ),
                              IconButton(
                                tooltip: s.delete,
                                iconSize: 26,
                                icon: Icon(Icons.delete_rounded,
                                    color: scheme.error),
                                onPressed: () => _delete(aircraft),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _AircraftDialog extends StatefulWidget {
  const _AircraftDialog({this.existing});

  final Aircraft? existing;

  @override
  State<_AircraftDialog> createState() => _AircraftDialogState();
}

class _AircraftDialogState extends State<_AircraftDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _registration =
      TextEditingController(text: widget.existing?.registration ?? '');
  late final TextEditingController _model =
      TextEditingController(text: widget.existing?.model ?? '');
  late final TextEditingController _capacity = TextEditingController(
      text: widget.existing?.capacity?.toString() ?? '');
  String? _registrationError;
  bool _saving = false;

  @override
  void dispose() {
    _registration.dispose();
    _model.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    setState(() => _registrationError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final bool duplicated = await controller.aircraft.registrationExists(
        _registration.text,
        excludeId: widget.existing?.id,
      );
      if (duplicated) {
        setState(() {
          _saving = false;
          _registrationError = s.registrationExists;
        });
        return;
      }
      final Aircraft aircraft = Aircraft(
        id: widget.existing?.id,
        registration: _registration.text.trim().toUpperCase(),
        model: _model.text.trim(),
        capacity: int.tryParse(_capacity.text.trim()),
      );
      if (widget.existing == null) {
        await controller.aircraft.insert(aircraft);
        await controller.audit(
            'AERONAVE_CREADA', 'Matrícula ${aircraft.registration}');
      } else {
        await controller.aircraft.update(aircraft);
        await controller.audit(
            'AERONAVE_EDITADA', 'Matrícula ${aircraft.registration}');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      AppLogger.instance.error('No se pudo guardar la aeronave', e, st);
      if (mounted) {
        setState(() {
          _saving = false;
          _registrationError = s.errorGeneric;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;

    return AlertDialog(
      title: Text(widget.existing == null ? s.newAircraft : s.editAircraft),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _registration,
                style: const TextStyle(fontSize: 18),
                inputFormatters: [UpperCaseTextFormatter()],
                decoration: InputDecoration(
                  labelText: s.registrationLabel,
                  hintText: 'YV1234',
                  errorText: _registrationError,
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? s.requiredField
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _model,
                style: const TextStyle(fontSize: 18),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                decoration: InputDecoration(
                  labelText: s.modelField,
                  hintText: 'AC90',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? s.requiredField
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacity,
                style: const TextStyle(fontSize: 18),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: s.capacityField),
              ),
            ],
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
