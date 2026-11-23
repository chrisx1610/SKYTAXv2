import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_paths.dart';
import 'core/logging/app_logger.dart';
import 'core/platform/database_factory.dart';
import 'presentation/state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SQLite según la plataforma: FFI en Windows/Linux, plugin nativo en
  // Android y WebAssembly + IndexedDB en el navegador.
  configureDatabaseFactory();

  final AppPaths paths = await AppPaths.resolve();
  await AppLogger.instance.init(paths.logs);

  final AppController controller = AppController(paths: paths);
  await controller.bootstrap();

  runApp(SkyTaxApp(controller: controller));
}
