import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../state/app_controller.dart';
import '../../widgets/kiosk_widgets.dart';

enum _Period { today, week, all }

/// Reportes de recaudación con exportación a PDF.
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

  /// Fuente de marca incrustada en el PDF.
  ///
  /// Se embebe en lugar de usar las tipografías estándar del formato porque
  /// estas no cubren con fiabilidad los acentos del español ni el símbolo del
  /// euro que llevan los importes.
  Future<pw.ThemeData> _pdfTheme() async {
    final ByteData data = await rootBundle.load('assets/fonts/IBMPlexSans.ttf');
    final pw.Font font = pw.Font.ttf(data);
    return pw.ThemeData.withFont(base: font, bold: font);
  }

  /// Fila etiqueta/valor del bloque de totales.
  pw.Widget _pdfRow(String label, String value, {bool emphasized = false}) {
    final double size = emphasized ? 14 : 11;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: size)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: size,
              fontWeight: emphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    final InvoiceStats? stats = _stats;
    if (stats == null) return;
    try {
      final DateTime now = DateTime.now();
      final pw.Document doc = pw.Document(
        title: '${s.sectionReports} — ${controller.config.airportCode}',
        author: 'SkyTax',
      );
      const PdfColor brand = PdfColor.fromInt(0xFF1E40AF);
      final pw.ThemeData theme = await _pdfTheme();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'SKYTAX',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: brand,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                s.sectionReports.toUpperCase(),
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: brand, thickness: 1.5),
              pw.SizedBox(height: 16),
              _pdfRow('${s.airportLabel}:', controller.config.airportDisplay),
              _pdfRow('${s.colDate}:', Formatters.dateTime(now)),
              _pdfRow('${s.colUser}:', controller.auditUser),
              _pdfRow('Período:', _periodLabel(s)),
              pw.SizedBox(height: 24),
              // Totales del período, destacados en un recuadro de marca.
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _pdfRow(s.statInvoices, '${stats.count}', emphasized: true),
                    _pdfRow(
                      s.statTotal,
                      Formatters.money(stats.total),
                      emphasized: true,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                s.statByMethod,
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              if (stats.totalByMethod.isEmpty)
                pw.Text(s.noRecords, style: const pw.TextStyle(fontSize: 11))
              else
                pw.Table(
                  border: pw.TableBorder.symmetric(
                    inside: const pw.BorderSide(color: PdfColors.grey300),
                  ),
                  children: [
                    for (final MapEntry<String, double> entry
                        in stats.totalByMethod.entries)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6),
                            child: pw.Text(
                              s.paymentMethodName(entry.key),
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6),
                            child: pw.Text(
                              Formatters.money(entry.value),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.Text(
                'SkyTax · ${controller.config.airportDisplay}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      );

      final Directory dir = Directory(controller.paths.reportes);
      await dir.create(recursive: true);
      final String stamp = DateFormat('yyyyMMdd-HHmmss').format(now);
      final File file = File(p.join(dir.path, 'REPORTE-$stamp.pdf'));
      await file.writeAsBytes(await doc.save());
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
              icon: const Icon(Icons.picture_as_pdf_rounded),
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
