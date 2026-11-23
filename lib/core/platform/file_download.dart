/// Descarga de archivos generados por la aplicación (facturas, reportes).
///
/// Solo tiene efecto en el navegador, donde no hay sistema de archivos al
/// que escribir: el archivo se entrega como una descarga normal.
library;

export 'file_download_io.dart'
    if (dart.library.js_interop) 'file_download_web.dart';
