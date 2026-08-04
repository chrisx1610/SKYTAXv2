import 'package:intl/intl.dart';

/// Formateadores compartidos para montos, fechas y horas.
class Formatters {
  Formatters._();

  static final NumberFormat _money = NumberFormat('#,##0.##', 'en_US');

  /// Formatea un monto como `€1,425` (sin decimales cuando son cero).
  static String money(double value) => '€${_money.format(value)}';

  static String date(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);

  static String time(DateTime dt) => DateFormat('HH:mm').format(dt);

  static String dateTime(DateTime dt) =>
      DateFormat('dd/MM/yyyy HH:mm').format(dt);

  /// Permanencia acumulada en forma compacta: `3 d 4 h`, `2 h 15 min`,
  /// `45 min`. Las abreviaturas son las mismas en español e inglés, de modo
  /// que no requieren traducción.
  static String stay(Duration d) {
    if (d.inDays > 0) {
      final int hours = d.inHours.remainder(24);
      return hours == 0 ? '${d.inDays} d' : '${d.inDays} d $hours h';
    }
    if (d.inHours > 0) {
      final int minutes = d.inMinutes.remainder(60);
      return minutes == 0 ? '${d.inHours} h' : '${d.inHours} h $minutes min';
    }
    return '${d.inMinutes} min';
  }

  /// Número de factura con relleno de ceros: `FACT-000001`.
  static String invoiceNumber(int sequence) =>
      'FACT-${sequence.toString().padLeft(6, '0')}';
}
