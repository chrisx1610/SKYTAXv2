import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../state/app_controller.dart';
import '../../widgets/bar_chart_card.dart';
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
        // Siete dias naturales contando hoy: si se restaran 7*24 horas se
        // colaria parte de un octavo dia y la suma de las barras dejaria de
        // cuadrar con el total.
        return DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
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

  /// Granularidad del eje segun el periodo: horas dentro de un dia, dias
  /// dentro de una semana y meses en el historico.
  InvoiceBucketSize get _bucketSize {
    switch (_period) {
      case _Period.today:
        return InvoiceBucketSize.hour;
      case _Period.week:
        return InvoiceBucketSize.day;
      case _Period.all:
        return InvoiceBucketSize.month;
    }
  }

  /// Tramos que debe dibujar el eje, con hueco incluido.
  ///
  /// Se generan aqui y no se toman de la consulta porque los tramos sin
  /// facturacion no vuelven de la base: si solo se pintaran los que tienen
  /// datos, un dia vacio desapareceria y el grafico daria una idea falsa del
  /// ritmo de recaudacion.
  List<(String, String)> _axis(InvoiceStats stats) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    switch (_period) {
      case _Period.today:
        return [
          for (int h = 0; h <= now.hour; h++)
            (
              InvoiceBucketSize.hour.keyOf(today.add(Duration(hours: h))),
              '${h.toString().padLeft(2, '0')}h',
            ),
        ];
      case _Period.week:
        return [
          for (int d = 6; d >= 0; d--)
            (
              InvoiceBucketSize.day.keyOf(today.subtract(Duration(days: d))),
              DateFormat('dd/MM').format(today.subtract(Duration(days: d))),
            ),
        ];
      case _Period.all:
        if (stats.buckets.isEmpty) return const [];
        // El historico arranca en el mes de la primera factura emitida.
        final List<String> keys = stats.buckets.keys.toList()..sort();
        final DateTime first = DateTime.parse('${keys.first}-01');
        final List<(String, String)> axis = [];
        DateTime cursor = DateTime(first.year, first.month);
        while (!cursor.isAfter(DateTime(now.year, now.month))) {
          axis.add((
            InvoiceBucketSize.month.keyOf(cursor),
            DateFormat('MM/yy').format(cursor),
          ));
          cursor = DateTime(cursor.year, cursor.month + 1);
        }
        return axis;
    }
  }

  List<BarDatum> _bars(InvoiceStats stats, {required bool money}) {
    return [
      for (final (String key, String label) in _axis(stats))
        () {
          final InvoiceBucket b = stats.buckets[key] ?? InvoiceBucket.empty;
          return BarDatum(
            axisLabel: label,
            value: money ? b.total : b.count.toDouble(),
            tooltip: money ? Formatters.money(b.total) : '${b.count}',
          );
        }(),
    ];
  }

  Future<void> _load() async {
    final AppController controller = context.read<AppController>();
    setState(() => _loading = true);
    try {
      final InvoiceStats stats =
          await controller.invoices.statsSince(_since, bucket: _bucketSize);
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

  /// Version del grafico de barras para el PDF.
  ///
  /// Se dibuja con cajas en lugar de usar un motor de graficos: la forma es
  /// la misma que en pantalla y evita arrastrar otra dependencia.
  pw.Widget _pdfChart({
    required String title,
    required List<BarDatum> bars,
    required PdfColor color,
    required String emptyLabel,
  }) {
    const double areaHeight = 80;
    const double labelSpace = 12;
    final double maxValue =
        bars.fold<double>(0, (acc, b) => b.value > acc ? b.value : acc);
    final int step = (bars.length / 8).ceil().clamp(1, 999);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (bars.isEmpty || maxValue <= 0)
          pw.Container(
            height: areaHeight,
            alignment: pw.Alignment.center,
            child: pw.Text(
              emptyLabel,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          )
        else ...[
          pw.SizedBox(
            height: areaHeight,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < bars.length; i++) ...[
                  if (i > 0) pw.SizedBox(width: 1),
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.SizedBox(
                          height: labelSpace,
                          child: bars[i].value == maxValue
                              ? pw.FittedBox(
                                  child: pw.Text(
                                    bars[i].tooltip,
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                )
                              : pw.SizedBox(),
                        ),
                        pw.Container(
                          height: ((areaHeight - labelSpace) *
                                  (bars[i].value / maxValue))
                              .clamp(bars[i].value > 0 ? 1.5 : 0.0,
                                  areaHeight - labelSpace),
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.Container(height: 0.5, color: PdfColors.grey400),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              for (int i = 0; i < bars.length; i++) ...[
                if (i > 0) pw.SizedBox(width: 1),
                pw.Expanded(
                  child: pw.Text(
                    i % step == 0 ? bars[i].axisLabel : '',
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                    style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey700),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
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
              pw.SizedBox(height: 22),
              _pdfChart(
                title: s.statInvoices,
                bars: _bars(stats, money: false),
                color: const PdfColor.fromInt(0xFF2563EB),
                emptyLabel: s.noRecords,
              ),
              pw.SizedBox(height: 18),
              _pdfChart(
                title: s.statTotal,
                bars: _bars(stats, money: true),
                color: const PdfColor.fromInt(0xFF9A6B12),
                emptyLabel: s.noRecords,
              ),
              pw.SizedBox(height: 22),
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

      // En movil la carpeta de la aplicacion es privada: el usuario no puede
      // llegar al archivo desde el gestor de archivos, asi que se abre el
      // panel del sistema para que lo guarde o lo envie a donde quiera. En
      // escritorio el PDF ya queda en Documentos y basta con indicar la ruta.
      if (Platform.isAndroid || Platform.isIOS) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/pdf')],
            subject:
                '${s.sectionReports} · ${controller.config.airportDisplay}',
            text: '${s.sectionReports} · ${_periodLabel(s)}',
            // Ancla del menu emergente en tablets; se ignora en telefonos.
            sharePositionOrigin:
                box == null ? null : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.reportGenerated} ${file.path}')),
        );
      }
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
            // Dos graficos y no uno con dos escalas: un conteo y un importe
            // no comparten eje. Lado a lado si hay sitio; apilados si no.
            LayoutBuilder(
              builder: (context, constraints) {
                final Widget issued = BarChartCard(
                  title: s.statInvoices,
                  bars: _bars(stats, money: false),
                  color: AppTheme.brandBright,
                  emptyLabel: s.noRecords,
                );
                final Widget collected = BarChartCard(
                  title: s.statTotal,
                  bars: _bars(stats, money: true),
                  color: AppTheme.gold,
                  emptyLabel: s.noRecords,
                );
                if (constraints.maxWidth < 720) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [issued, const SizedBox(height: 20), collected],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: issued),
                    const SizedBox(width: 20),
                    Expanded(child: collected),
                  ],
                );
              },
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
