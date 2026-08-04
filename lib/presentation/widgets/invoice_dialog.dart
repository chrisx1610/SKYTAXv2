import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/models.dart';
import '../../domain/invoicing.dart';
import 'kiosk_widgets.dart';

/// Muestra el contenido del archivo TXT de una factura.
///
/// Si el archivo ya no existe en disco, reconstruye el documento a partir
/// del registro de la base de datos.
Future<void> showInvoiceDialog(
  BuildContext context,
  Invoice invoice,
  AppStrings s,
) async {
  String content;
  bool fromFile = true;
  try {
    content = await File(invoice.filePath).readAsString();
  } catch (e) {
    AppLogger.instance
        .warning('Factura ${invoice.number}: archivo no disponible ($e)');
    content = buildInvoiceText(invoice, s);
    fromFile = false;
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
            if (!fromFile)
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
        if (fromFile && Platform.isWindows)
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
