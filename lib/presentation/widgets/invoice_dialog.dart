import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/file_download.dart';
import '../../data/models/models.dart';
import '../../domain/invoicing.dart';
import 'kiosk_widgets.dart';

/// Muestra el contenido del archivo TXT de una factura.
///
/// Si el archivo ya no existe en disco, reconstruye el documento a partir
/// del registro de la base de datos. En el navegador no hay archivo: el
/// documento siempre se reconstruye y se ofrece como descarga.
Future<void> showInvoiceDialog(
  BuildContext context,
  Invoice invoice,
  AppStrings s,
) async {
  String content;
  bool fromFile = !kIsWeb;
  if (kIsWeb) {
    content = buildInvoiceText(invoice, s);
  } else {
    try {
      content = await File(invoice.filePath).readAsString();
    } catch (e) {
      AppLogger.instance
          .warning('Factura ${invoice.number}: archivo no disponible ($e)');
      content = buildInvoiceText(invoice, s);
      fromFile = false;
    }
  }
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(invoice.number),
      content: SizedBox(
        width: 480,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!fromFile && !kIsWeb)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  s.fileMissing,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14),
                ),
              ),
            Expanded(child: InvoiceTextViewer(content: content)),
          ],
        ),
      ),
      actions: [
        if (kIsWeb)
          TextButton.icon(
            icon: const Icon(Icons.download_rounded),
            label: Text(s.download),
            onPressed: () => downloadFile(
              utf8.encode(content),
              fileName: '${invoice.number}.txt',
              mimeType: 'text/plain;charset=utf-8',
            ),
          )
        else if (fromFile && Platform.isWindows)
          TextButton.icon(
            icon: const Icon(Icons.folder_open_rounded),
            label: Text(s.openFolder),
            onPressed: () =>
                Process.run('explorer.exe', ['/select,', invoice.filePath]),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.close),
        ),
      ],
    ),
  );
}
