import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../domain/tax_calculator.dart';
import '../state/app_controller.dart';
import '../widgets/kiosk_widgets.dart';
import 'confirmation_screen.dart';
import 'payment_method_screen.dart';

/// Pago móvil: muestra los datos del beneficiario y valida la referencia.
class MobilePaymentScreen extends StatefulWidget {
  const MobilePaymentScreen({super.key, required this.quote});

  final TaxQuote quote;

  @override
  State<MobilePaymentScreen> createState() => _MobilePaymentScreenState();
}

class _MobilePaymentScreenState extends State<MobilePaymentScreen> {
  final TextEditingController _reference = TextEditingController();
  bool _verifying = false;
  String? _error;

  static const String _bank = 'Banco de Venezuela (0102)';
  static const String _phone = '0412-5550123';
  static const String _rif = 'G-20009997-4';

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    setState(() {
      _error = null;
      _verifying = true;
    });
    try {
      final bool ok =
          await controller.payments.verifyMobileReference(_reference.text);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _verifying = false;
          _error = s.invalidReference;
        });
        return;
      }
      final Invoice invoice =
          await controller.finalizeSale(widget.quote, PaymentMethods.mobile);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.paymentReceived)));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConfirmationScreen(invoice: invoice),
        ),
      );
    } catch (e, st) {
      AppLogger.instance.error('Error en el pago móvil', e, st);
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = s.errorGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = context.watch<AppController>();
    final AppStrings s = controller.strings;

    return KioskScaffold(
      title: s.methodMobile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountBanner(quote: widget.quote),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.mobileInstructions,
                    style: TextStyle(
                      fontSize: 17,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SummaryRow(label: s.bankLabel, value: _bank),
                  SummaryRow(label: s.phoneLabel, value: _phone),
                  SummaryRow(label: s.rifLabel, value: _rif),
                  SummaryRow(
                    label: s.amountLabel,
                    value: Formatters.money(widget.quote.total),
                    emphasized: true,
                  ),
                  const Divider(height: 32),
                  TextField(
                    controller: _reference,
                    enabled: !_verifying,
                    style: const TextStyle(fontSize: 22),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: InputDecoration(
                      labelText: s.referenceLabel,
                      hintText: s.referenceHint,
                      errorText: _error,
                      labelStyle: const TextStyle(fontSize: 18),
                    ),
                    onSubmitted: (_) => _verifying ? null : _confirm(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          KioskActionBar(
            secondaryLabel: s.cancel,
            onSecondary: _verifying
                ? null
                : () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
            primaryLabel: _verifying ? s.verifyingPayment : s.confirmPayment,
            primaryIcon: _verifying ? null : Icons.check_rounded,
            onPrimary: _verifying ? null : _confirm,
          ),
        ],
      ),
    );
  }
}
