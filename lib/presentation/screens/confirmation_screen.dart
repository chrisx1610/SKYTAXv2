import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../state/app_controller.dart';
import '../widgets/invoice_dialog.dart';
import '../widgets/kiosk_widgets.dart';
import 'language_screen.dart';

/// Confirmación final: pago recibido y factura generada.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final AppController controller = context.watch<AppController>();
    final AppStrings s = controller.strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return KioskScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: MediaQuery.of(context).disableAnimations ? 1 : 0,
                end: 1,
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 96,
                  color: AppTheme.success,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.paymentReceived,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            s.invoiceGenerated,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                children: [
                  SummaryRow(
                      label: s.invoiceNumberLabel, value: invoice.number),
                  SummaryRow(
                      label: s.dateLabel,
                      value: Formatters.date(invoice.createdAt)),
                  SummaryRow(
                      label: s.timeLabel,
                      value: Formatters.time(invoice.createdAt)),
                  SummaryRow(
                    label: s.paymentMethodLabel,
                    value: s.paymentMethodName(invoice.paymentMethod),
                  ),
                  const Divider(height: 24),
                  SummaryRow(
                    label: s.totalPaidLabel,
                    value: Formatters.money(invoice.total),
                    emphasized: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          KioskActionBar(
            secondaryLabel: s.viewInvoice,
            secondaryIcon: Icons.receipt_long_rounded,
            onSecondary: () => showInvoiceDialog(context, invoice, s),
            primaryLabel: s.newOperation,
            primaryIcon: Icons.home_rounded,
            onPrimary: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LanguageScreen()),
              (route) => false,
            ),
          ),
        ],
      ),
    );
  }
}
