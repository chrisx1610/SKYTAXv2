import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/models.dart';
import '../../domain/payment_simulator.dart';
import '../../domain/tax_calculator.dart';
import '../state/app_controller.dart';
import '../widgets/kiosk_widgets.dart';
import 'confirmation_screen.dart';
import 'payment_method_screen.dart';

/// Pago con tarjeta: simulación de validación → autorización → aprobación.
class CardPaymentScreen extends StatefulWidget {
  const CardPaymentScreen({super.key, required this.quote});

  final TaxQuote quote;

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  StreamSubscription<CardPaymentStep>? _subscription;
  CardPaymentStep? _step;
  bool _finalizing = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final AppController controller = context.read<AppController>();
    _subscription = controller.payments.processCard().listen(
      (step) => setState(() => _step = step),
      onDone: _finalize,
      onError: (Object e, StackTrace st) {
        AppLogger.instance.error('Error en el pago con tarjeta', e, st);
        if (mounted) _showError();
      },
    );
  }

  Future<void> _finalize() async {
    if (_step != CardPaymentStep.approved || _finalizing) return;
    setState(() => _finalizing = true);
    final AppController controller = context.read<AppController>();
    try {
      final Invoice invoice =
          await controller.finalizeSale(widget.quote, PaymentMethods.card);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConfirmationScreen(invoice: invoice),
        ),
      );
    } catch (e, st) {
      AppLogger.instance.error('No se pudo emitir la factura', e, st);
      if (mounted) _showError();
    }
  }

  void _showError() {
    final AppStrings s = context.read<AppController>().strings;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.errorGeneric)));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Widget _stepTile(AppStrings s, CardPaymentStep step, String label) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int current = _step?.index ?? -1;
    final bool done = current > step.index ||
        (step == CardPaymentStep.approved &&
            _step == CardPaymentStep.approved);
    final bool active = current == step.index && !done;

    final Widget leading;
    if (done) {
      leading = Icon(Icons.check_circle_rounded,
          size: 36, color: Colors.green.shade600);
    } else if (active) {
      leading = const SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(strokeWidth: 3.5),
      );
    } else {
      leading = Icon(Icons.circle_outlined,
          size: 32, color: scheme.outlineVariant);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(width: 40, child: Center(child: leading)),
          const SizedBox(width: 20),
          Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: done || active ? FontWeight.w700 : FontWeight.w400,
              color: done || active
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;
    final bool approved = _step == CardPaymentStep.approved;

    return KioskScaffold(
      title: s.cardProcessingTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountBanner(quote: widget.quote),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(
                      Icons.credit_card_rounded,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      s.insertCard,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _stepTile(s, CardPaymentStep.validating, s.stepValidating),
                  _stepTile(
                      s, CardPaymentStep.authorizing, s.stepAuthorizing),
                  _stepTile(s, CardPaymentStep.approved, s.stepApproved),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (!approved)
            SizedBox(
              height: 64,
              child: OutlinedButton(
                onPressed: () {
                  _subscription?.cancel();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(s.cancel),
              ),
            ),
        ],
      ),
    );
  }
}
