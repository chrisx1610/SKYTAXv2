import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/i18n/app_strings.dart';
import '../core/utils/formatters.dart';
import '../data/models/models.dart';

/// Ancho de línea del documento de factura.
const int _width = 42;

String _line(String char) => char * _width;

String _center(String text) {
  if (text.length >= _width) return text;
  return (' ' * ((_width - text.length) ~/ 2)) + text;
}

/// Construye el contenido textual de una factura.
///
/// Es una función pura (sin acceso a disco) para poder probarla de forma
/// aislada y reutilizarla en cualquier salida (archivo, impresora, etc.).
String buildInvoiceText(Invoice invoice, AppStrings s) {
  final StringBuffer b = StringBuffer();
  void writeln([String text = '']) => b.write('$text\r\n');

  writeln(_line('='));
  writeln(_center('SKYTAX'));
  writeln(_center(s.appTagline));
  writeln(_line('='));
  writeln();
  writeln('${s.invoiceNumberLabel}: ${invoice.number}');
  writeln();
  writeln('${s.dateLabel}: ${Formatters.date(invoice.createdAt)}');
  writeln('${s.timeLabel}: ${Formatters.time(invoice.createdAt)}');
  writeln();
  writeln('${s.airportLabel}:');
  writeln('${invoice.airportCode} - ${invoice.airportName}');
  writeln();
  writeln('${s.registrationShort}:');
  writeln(invoice.registration);
  writeln();
  writeln('${s.modelLabel}:');
  writeln(invoice.aircraftModel);
  writeln();
  writeln('${s.passengersShort}:');
  writeln('${invoice.passengers}');
  // Los infantes viajaron pero no tributan: se detallan para que el
  // subtotal cuadre con el total de pasajeros impreso arriba.
  if (invoice.infants > 0) {
    writeln();
    writeln('${s.infantsShort}:');
    writeln('-${invoice.infants}');
  }
  writeln();
  writeln(_line('-'));
  writeln();
  writeln('${s.airportTaxLabel}:');
  writeln(
      '${invoice.payingPassengers} x ${Formatters.money(invoice.taxRate)}');
  writeln();
  writeln('${s.subtotalLabel}:');
  writeln(Formatters.money(invoice.taxSubtotal));
  if (invoice.hasDosa) {
    writeln();
    writeln('${s.dosaLabel}:');
    writeln(Formatters.money(invoice.dosa));
  }
  // Tramo elegido y hasta cuándo cubre la estadía pagada.
  final DateTime? validUntil = invoice.validUntil;
  if (validUntil != null) {
    writeln();
    writeln(_line('-'));
    writeln();
    writeln('${s.validUntilLabel}:');
    writeln('${Formatters.date(validUntil)} ${Formatters.time(validUntil)}');
  }
  writeln();
  writeln(_line('-'));
  writeln();
  writeln(s.totalPaidUpper);
  writeln();
  writeln(Formatters.money(invoice.total));
  writeln();
  writeln(_line('-'));
  writeln();
  writeln('${s.paymentMethodLabel}:');
  writeln();
  writeln(s.paymentMethodName(invoice.paymentMethod));
  writeln();
  writeln(_line('-'));
  writeln();
  writeln(s.invoiceThanks);
  writeln();
  writeln(_line('='));
  return b.toString();
}

/// Puerto de salida de facturas.
///
/// La lógica del sistema solo depende de esta interfaz; para pasar de la
/// factura `.txt` de demostración a una impresora fiscal o facturación
/// electrónica basta con registrar otra implementación, sin tocar el resto
/// del sistema.
abstract class InvoiceOutput {
  /// Emite la factura y devuelve un identificador de salida
  /// (para la implementación TXT, la ruta del archivo generado).
  Future<String> emit(Invoice invoice, AppStrings strings);
}

/// Implementación de demostración: genera `SkyTax/Facturas/FACT-XXXXXX.txt`.
class TxtInvoiceOutput implements InvoiceOutput {
  TxtInvoiceOutput({required this.directory});

  /// Carpeta `SkyTax/Facturas` dentro de los documentos del usuario.
  final String directory;

  @override
  Future<String> emit(Invoice invoice, AppStrings strings) async {
    final Directory dir = Directory(directory);
    await dir.create(recursive: true);
    final File file = File(p.join(dir.path, '${invoice.number}.txt'));
    await file.writeAsString(buildInvoiceText(invoice, strings));
    return file.path;
  }
}
