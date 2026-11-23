import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// En Windows y Linux SQLite se usa a través de FFI; en Android, el plugin
/// nativo de sqflite ya viene configurado y no hace falta tocar nada.
void configureDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
