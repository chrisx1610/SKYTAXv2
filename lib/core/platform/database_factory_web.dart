import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// En el navegador SQLite corre como WebAssembly (`web/sqlite3.wasm`) y
/// guarda los datos en IndexedDB, dentro del propio navegador.
void configureDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
