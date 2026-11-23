/// Selección del motor SQLite según la plataforma.
///
/// En escritorio y móvil se usa la implementación nativa (o FFI); en el
/// navegador, SQLite compilado a WebAssembly con persistencia en IndexedDB.
/// La importación condicional evita que el código con `dart:ffi` llegue a
/// la compilación web, donde no existe.
library;

export 'database_factory_io.dart'
    if (dart.library.js_interop) 'database_factory_web.dart';
