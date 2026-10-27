import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../domain/tax_calculator.dart';
import '../state/app_controller.dart';
import '../widgets/kiosk_widgets.dart';
import 'card_payment_screen.dart';
import 'mobile_payment_screen.dart';
import 'offline_guard.dart';

/// Selección del método de pago: Tarjeta o Pago Móvil.
class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key, required this.quote});

  final TaxQuote quote;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  /// Evita registrar la aeronave como pendiente dos veces si llegan varios
  /// avisos de red seguidos.
  bool _handledOffline = false;

  @override
  Widget build(BuildContext context) {
    final AppController controller = context.watch<AppController>();
    final AppStrings s = controller.strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TaxQuote quote = widget.quote;
    final bool offline = !controller.online;

    // La red pudo caerse entre el resumen y esta pantalla. No se puede
    // navegar durante el build, de ahí que se espere al final del cuadro.
    if (offline && !_handledOffline) {
      _handledOffline = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) deferBecauseOffline(context, quote);
      });
    }

    return KioskScaffold(
      title: s.paymentTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.totalToPay,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.money(quote.total),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w800,
              color: AppTheme.gold,
              letterSpacing: -1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (offline) ...[
            const SizedBox(height: 24),
            const OfflineNotice(),
          ],
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool wide = constraints.maxWidth > 560;
              final List<Widget> cards = [
                BigChoiceCard(
                  icon: Icons.credit_card_rounded,
                  label: s.methodCard,
                  sublabel: s.insertCard,
                  enabled: !offline,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CardPaymentScreen(quote: quote),
                    ),
                  ),
                ),
                BigChoiceCard(
                  icon: Icons.phone_android_rounded,
                  label: s.methodMobile,
                  sublabel: s.referenceLabel,
                  enabled: !offline,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MobilePaymentScreen(quote: quote),
                    ),
                  ),
                ),
              ];
              if (wide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 24),
                      Expanded(child: cards[1]),
                    ],
                  ),
                );
              }
              // Estiradas al ancho disponible: sin esto cada tarjeta se
              // ajusta a su propio texto y quedan de distinto tamano.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [cards[0], const SizedBox(height: 20), cards[1]],
              );
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 64,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text(s.cancel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta compartida por las pantallas de pago para mostrar el monto.
class AmountBanner extends StatelessWidget {
  const AmountBanner({super.key, required this.quote});

  final TaxQuote quote;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${s.registrationShort}: ${quote.registration}',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onPrimaryContainer),
          ),
          Text(
            Formatters.money(quote.total),
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

/// Método de pago como constantes compartidas.
abstract final class PaymentMethods {
  static const String card = Invoice.methodCard;
  static const String mobile = Invoice.methodMobile;
}
