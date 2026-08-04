import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../state/app_controller.dart';
import '../../widgets/kiosk_widgets.dart';

enum _Period { today, week, all }

/// Reportes de recaudación con exportación a TXT.
class ReportsSection extends StatefulWidget {
  const ReportsSection({super.key});

  @override
  State<ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<ReportsSection> {
  _Period _period = _Period.today;
  InvoiceStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime? get _since {
    final DateTime now = DateTime.now();
    switch (_period) {
      case _Period.today:
        return DateTime(now.year, now.month, now.day);
      case _Period.week:
        return now.subtract(const Duration(days: 7));
      case _Period.all:
        return null;
    }
  }

  String _periodLabel(AppStrings s) {
    switch (_period) {
      case _Period.today:
        return s.periodToday;
      case _Period.week:
        return s.period7Days;
      case _Period.all:
        return s.periodAll;
    }
  }

  Future<void> _load() async {
    final AppController controller = context.read<AppController>();
    setState(() => _loading = true);
    try {
      final InvoiceStats stats =
          await controller.invoices.statsSince(_since);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.instance.error('No se pudo calcular el reporte', e, st);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _export() async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    final InvoiceStats? stats = _stats;
    if (stats == null) return;
    try {
      final DateTime now = DateTime.now();
      final StringBuffer b = StringBuffer();
      void writeln([String text = '']) => b.write('$text\r\n');
      writeln('=' * 42);
      writeln('SKYTAX - ${s.sectionReports.toUpperCase()}');
      writeln('=' * 42);
      writeln();
      writeln('${s.airportLabel}: ${controller.config.airportDisplay}');
      writeln('${s.colDate}: ${Formatters.dateTime(now)}');
      writeln('${s.colUser}: ${controller.auditUser}');
      writeln('Período: ${_periodLabel(s)}');
      writeln();
      writeln('-' * 42);
      writeln('${s.statInvoices}: ${stats.count}');
      writeln('${s.statTotal}: ${Formatters.money(stats.total)}');
      writeln();
      writeln('${s.statByMethod}:');
      if (stats.totalByMethod.isEmpty) {
        writeln('  ${s.noRecords}');
      } else {
        for (final MapEntry<String, double> entry
            in stats.totalByMethod.entries) {
          writeln(
              '  ${s.paymentMethodName(entry.key)}: ${Formatters.money(entry.value)}');
        }
      }
      writeln('-' * 42);

      final Directory dir = Directory(controller.paths.reportes);
      await dir.create(recursive: true);
      final String stamp = DateFormat('yyyyMMdd-HHmmss').format(now);
      final File file = File(p.join(dir.path, 'REPORTE-$stamp.txt'));
      await file.writeAsString(b.toString());
      await controller.audit('REPORTE', 'Generado ${file.path}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.reportGenerated} ${file.path}')),
      );
    } catch (e, st) {
      AppLogger.instance.error('No se pudo generar el reporte', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.errorGeneric)));
      }
    }
  }

  Widget _statCard(String label, String value) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 16, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;
    final InvoiceStats? stats = _stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: s.sectionReports,
            action: FilledButton.icon(
              icon: const Icon(Icons.description_rounded),
              label: Text(s.generateReport),
              onPressed: _loading ? null : _export,
            ),
          ),
          const SizedBox(height: 20),
          SegmentedButton<_Period>(
            segments: [
              ButtonSegment(
                  value: _Period.today, label: Text(s.periodToday)),
              ButtonSegment(
                  value: _Period.week, label: Text(s.period7Days)),
              ButtonSegment(value: _Period.all, label: Text(s.periodAll)),
            ],
            selected: {_period},
            onSelectionChanged: (selection) {
              setState(() => _period = selection.first);
              _load();
            },
          ),
          const SizedBox(height: 24),
          if (_loading || stats == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            Row(
              children: [
                _statCard(s.statInvoices, '${stats.count}'),
                const SizedBox(width: 20),
                _statCard(s.statTotal, Formatters.money(stats.total)),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.statByMethod,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (stats.totalByMethod.isEmpty)
                      Text(s.noRecords,
                          style: const TextStyle(fontSize: 16))
                    else
                      for (final MapEntry<String, double> entry
                          in stats.totalByMethod.entries)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s.paymentMethodName(entry.key),
                                style: const TextStyle(fontSize: 17),
                              ),
                              Text(
                                Formatters.money(entry.value),
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
