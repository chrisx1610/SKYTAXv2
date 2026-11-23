import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Rutas de trabajo de la aplicación, resueltas por plataforma.
///
/// Los datos internos (bases de datos, logs, configuración) viven en el
/// directorio de soporte de la aplicación; las facturas y reportes se
/// guardan en `Documentos/SkyTax/` para que el usuario pueda consultarlos.
class AppPaths {
  const AppPaths({
    required this.base,
    required this.data,
    required this.logs,
    required this.facturas,
    required this.reportes,
  });

  final String base;
  final String data;
  final String logs;
  final String facturas;
  final String reportes;

  static Future<AppPaths> resolve() async {
    // El navegador no tiene sistema de archivos: la base de datos vive en
    // IndexedDB y facturas y reportes se entregan como descargas. Las rutas
    // quedan como nombres lógicos, sin uso real.
    if (kIsWeb) {
      return const AppPaths(
        base: 'web',
        data: 'web',
        logs: 'web',
        facturas: 'web',
        reportes: 'web',
      );
    }
    final String support = (await getApplicationSupportDirectory()).path;
    final String documents = (await getApplicationDocumentsDirectory()).path;
    final String skyTaxDocs = p.join(documents, 'SkyTax');
    return AppPaths(
      base: support,
      data: p.join(support, 'data'),
      logs: p.join(support, 'logs'),
      facturas: p.join(skyTaxDocs, 'Facturas'),
      reportes: p.join(skyTaxDocs, 'Reportes'),
    );
  }
}
