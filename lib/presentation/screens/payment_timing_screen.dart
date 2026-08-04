import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../domain/tax_calculator.dart';
import '../state/app_controller.dart';
import '../widgets/kiosk_widgets.dart';
import 'dosa_bracket_screen.dart';
import 'summary_screen.dart';

/// Pregunta si la aeronave paga en el momento o difiere el pago.
///
/// Pagar ahora aplica el tramo «hasta 2 horas» de la tabla DOSA. Diferir el
/// pago registra la aeronave como pendiente y devuelve al usuario a la
/// pantalla inicial; el tiempo empieza a contar desde ese registro y define
/// el tramo que se cobrará cuando regrese.
class PaymentTimingScreen extends StatefulWidget {
  const PaymentTimingScreen({super.key, required this.quote});

  final TaxQuote quote;

  @override
  State<PaymentTimingScreen> createState() => _PaymentTimingScreenState();
}

class _PaymentTimingScreenState extends State<PaymentTimingScreen> {
  bool _saving = false;

  /// Pagar ahora: se ofrece elegir el tramo de permanencia.
  ///
  /// La pantalla de tarifas solo tiene sentido si la aeronave paga DOSA y su
  /// modelo está tabulado; en caso contrario no hay importes que mostrar y se
  /// va directo al resumen, que ya advierte de la tarifa faltante.
  Future<void> _payNow() async {
    final AppController controller = context.read<AppController>();
    final TaxQuote quote = widget.quote;

    setState(() => _saving = true);
    DosaTariff? tariff;
    try {
      if (!quote.isLocal) {
        tariff = await controller.tariffForModel(quote.aircraftModel);
      }
    } catch (e, st) {
      AppLogger.instance.error('No se pudo leer la tarifa DOSA', e, st);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;

    final DosaTariff? found = tariff;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => found == null
            ? SummaryScreen(quote: quote)
            : DosaBracketScreen(quote: quote, tariff: found),
      ),
    );
  }

  Future<void> _payLater() async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    setState(() => _saving = true);
    try {
      await controller.deferPayment(widget.quote);
      if (!mounted) return;
      // Vuelve a la primera interfaz del kiosco.
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.paymentDeferred)),
      );
    } catch (e, st) {
      AppLogger.instance.error('No se pudo diferir el pago', e, st);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.errorGeneric)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = context.watch<AppController>();
    final AppStrings s = controller.strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TaxQuote quote = widget.quote;

    // Si la aeronave ya venía difiriendo el pago, se muestra la permanencia
    // acumulada y el tramo que se le está aplicando.
    final bool hasStay = quote.elapsed > Duration.zero;

    return KioskScaffold(
      title: s.payTimingTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasStay) ...[
            StatusChip(
              icon: Icons.schedule_rounded,
              label: '${s.stayLabel}: ${Formatters.stay(quote.elapsed)}'
                  '${quote.dosaBracket == null ? '' : ' · ${s.bracketName(quote.dosaBracket!.index)}'}',
              background: scheme.tertiaryContainer,
              foreground: scheme.onTertiaryContainer,
            ),
            const SizedBox(height: 20),
          ],
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            // Dos opciones lado a lado en pantallas amplias; apiladas en las
            // angostas, para que ningún texto quede comprimido.
            LayoutBuilder(
              builder: (context, constraints) {
                final Widget now = BigChoiceCard(
                  icon: Icons.payments_rounded,
                  label: s.payNow,
                  onTap: _payNow,
                );
                final Widget later = BigChoiceCard(
                  icon: Icons.schedule_send_rounded,
                  label: s.payLater,
                  onTap: _payLater,
                );
                if (constraints.maxWidth < 620) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [now, const SizedBox(height: 16), later],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: now),
                    const SizedBox(width: 16),
                    Expanded(child: later),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          KioskSecondaryButton(
            label: s.cancel,
            onPressed: _saving
                ? null
                : () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }
}
