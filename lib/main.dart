import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/app_paths.dart';
import 'core/logging/app_logger.dart';
import 'presentation/state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // En escritorio (Windows/Linux) SQLite se usa a través de FFI;
  // en Android se usa el plugin nativo de sqflite.
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final AppPaths paths = await AppPaths.resolve();
  await AppLogger.instance.init(paths.logs);

  final AppController controller = AppController(paths: paths);
  await controller.bootstrap();

  runApp(SkyTaxApp(controller: controller));
}
