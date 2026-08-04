import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/logging/app_logger.dart';

/// Configuración local del terminal (kiosco).
///
/// Identifica el aeropuerto al que pertenece el equipo; con ese código se
/// abre la base de datos correspondiente. Se guarda como JSON junto a los
/// datos de la aplicación.
class LocalConfig {
  const LocalConfig({required this.airportCode, required this.airportName});

  final String airportCode;
  final String airportName;

  static const LocalConfig defaults = LocalConfig(
    airportCode: 'SVMI',
    airportName: 'Maiquetía',
  );

  String get airportDisplay => '$airportCode - $airportName';

  LocalConfig copyWith({String? airportCode, String? airportName}) =>
      LocalConfig(
        airportCode: airportCode ?? this.airportCode,
        airportName: airportName ?? this.airportName,
      );

  Map<String, Object?> toJson() =>
      {'airportCode': airportCode, 'airportName': airportName};

  factory LocalConfig.fromJson(Map<String, Object?> json) => LocalConfig(
        airportCode: json['airportCode'] as String? ?? defaults.airportCode,
        airportName: json['airportName'] as String? ?? defaults.airportName,
      );
}

/// Lectura y escritura de [LocalConfig] en disco.
class LocalConfigStore {
  LocalConfigStore({required this.baseDirectory});

  final String baseDirectory;

  File get _file => File(p.join(baseDirectory, 'config.json'));

  Future<LocalConfig> load() async {
    try {
      if (await _file.exists()) {
        final Map<String, Object?> json =
            jsonDecode(await _file.readAsString()) as Map<String, Object?>;
        return LocalConfig.fromJson(json);
      }
    } catch (e, st) {
      AppLogger.instance.error('No se pudo leer config.json', e, st);
    }
    return LocalConfig.defaults;
  }

  Future<void> save(LocalConfig config) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config.toJson()),
    );
  }
}
