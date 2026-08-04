import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

/// Registro de eventos y errores de la aplicación.
///
/// Escribe en consola (modo debug) y en un archivo `skytax.log` dentro del
/// directorio de datos de la aplicación.
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  File? _file;

  Future<void> init(String logsDirectory) async {
    try {
      final Directory dir = Directory(logsDirectory);
      await dir.create(recursive: true);
      _file = File(p.join(dir.path, 'skytax.log'));
    } catch (e) {
      debugPrint('AppLogger: no se pudo inicializar el archivo de log: $e');
    }
  }

  void info(String message) => _write('INFO', message);

  void warning(String message) => _write('WARN', message);

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    final StringBuffer buffer = StringBuffer(message);
    if (error != null) buffer.write(' | $error');
    if (stackTrace != null) buffer.write('\n$stackTrace');
    _write('ERROR', buffer.toString());
  }

  void _write(String level, String message) {
    final String stamp =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final String line = '[$stamp] [$level] $message';
    debugPrint(line);
    try {
      _file?.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // El log nunca debe interrumpir la operación del sistema.
    }
  }
}
