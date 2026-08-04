import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../../domain/dosa_schedule.dart';
import '../../state/app_controller.dart';
import '../../widgets/kiosk_widgets.dart';

/// Aeronaves que difirieron el pago.
///
/// Para cada una se calcula, en el momento de consultar, cuánta permanencia
/// lleva acumulada, qué tramo de la tabla DOSA le corresponde y cuánto
/// pagaría hoy. Las filas desaparecen solas cuando la aeronave paga.
class PendingSection extends StatefulWidget {
  const PendingSection({super.key});

  @override
  State<PendingSection> createState() => _PendingSectionState();
}

class _PendingSectionState extends State<PendingSection> {
  List<PendingPayment> _items = const [];
  List<DosaTariff> _tariffs = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AppController controller = context.read<AppController>();
    try {
      final List<PendingPayment> items =
          await controller.pendingPayments.getAll();
      final List<DosaTariff> tariffs = await controller.dosaTariffs.getAll();
      if (!mounted) return;
      setState(() {
        _items = items;
        _tariffs = tariffs;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.instance
          .error('No se pudieron cargar los pagos pendientes', e, st);
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Tarifa del modelo, sin distinguir mayúsculas ni espacios sobrantes.
  DosaTariff? _tariffFor(String model) {
    final String needle = model.trim().toLowerCase();
    for (final DosaTariff t in _tariffs) {
      if (t.model.trim().toLowerCase() == needle) return t;
    }
    return null;
  }

  Future<void> _delete(PendingPayment pending) async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.delete),
        content: Text(s.confirmDelete(pending.registration)),
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
      await controller.pendingPayments
          .deleteByRegistration(pending.registration);
      await controller.audit(
        'PENDIENTE_ELIMINADO',
        'Aeronave ${pending.registration} retirada de la lista de pendientes',
      );
      await _load();
    } catch (e, st) {
      AppLogger.instance.error('No se pudo eliminar el pendiente', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.errorGeneric)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final DateTime now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: s.sectionPending,
            action: IconButton(
              tooltip: s.sectionPending,
              iconSize: 28,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
          ),
          if (!_loading && _items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.pendingCount(_items.length),
              style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Text(
                          s.noRecords,
                          style: TextStyle(
                              fontSize: 18, color: scheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _PendingCard(
                          pending: _items[index],
                          tariff: _tariffFor(_items[index].model),
                          now: now,
                          onDelete: () => _delete(_items[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Ficha de una aeronave pendiente con su permanencia, tramo e importe.
///
/// Se reorganiza según el ancho: los cuatro datos se reparten en dos columnas
/// cuando hay sitio y en una sola en pantallas angostas, de modo que ninguna
/// etiqueta se parta a mitad de palabra.
class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.pending,
    required this.tariff,
    required this.now,
    required this.onDelete,
  });

  final PendingPayment pending;
  final DosaTariff? tariff;
  final DateTime now;
  final VoidCallback onDelete;

  static const double _twoColumnBreakpoint = 420;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final Duration elapsed = pending.elapsedUntil(now);
    final DosaBracket bracket = dosaBracketFor(elapsed);
    final double due = dosaAmount(tariff: tariff, elapsed: elapsed);
    final bool missing = tariff == null;

    final List<(String, String)> facts = [
      (s.pendingSince, Formatters.dateTime(pending.createdAt)),
      (s.stayLabel, Formatters.stay(elapsed)),
      (s.bracketLabel, s.bracketName(bracket.index)),
      (s.passengersShort, '${pending.passengers}'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.tertiaryContainer,
                  child: Icon(Icons.schedule_rounded,
                      color: scheme.onTertiaryContainer),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '${pending.registration} · ${pending.model}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: s.delete,
                  iconSize: 26,
                  icon: Icon(Icons.delete_rounded, color: scheme.error),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final bool twoColumns =
                    constraints.maxWidth >= _twoColumnBreakpoint;
                final double itemWidth = twoColumns
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    for (final (String label, String value) in facts)
                      SizedBox(
                        width: itemWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant),
                            ),
                            Text(
                              value,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const Divider(height: 26),
            // Importe que la aeronave pagaría si se presentara ahora mismo.
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.amountDueToday,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  Formatters.money(due),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: missing ? scheme.error : scheme.primary,
                  ),
                ),
              ],
            ),
            if (missing) ...[
              const SizedBox(height: 10),
              StatusChip(
                icon: Icons.warning_amber_rounded,
                label: s.missingTariffWarning,
                background: scheme.errorContainer,
                foreground: scheme.onErrorContainer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
