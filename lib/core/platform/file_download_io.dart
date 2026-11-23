import 'dart:typed_data';

/// Fuera del navegador los archivos se escriben en disco con `dart:io`;
/// esta función no debe llamarse.
Future<void> downloadFile(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
}) {
  throw UnsupportedError('downloadFile solo está disponible en web');
}
