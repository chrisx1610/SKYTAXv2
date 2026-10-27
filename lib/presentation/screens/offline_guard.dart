import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/tax_calculator.dart';
import '../state/app_controller.dart';
import '../widgets/kiosk_widgets.dart';

/// Aviso de que el terminal se quedó sin red.
///
/// El cálculo de impuestos y la emisión de facturas son locales, pero el
/// cobro sale a internet: sin red no hay datáfono ni pago móvil.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusChip(
          icon: Icons.wifi_off_rounded,
          label: s.offlineTitle,
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
        ),
        const SizedBox(height: 8),
        Text(
          s.offlineNote,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Registra la aeronave como pendiente por falta de red y vuelve al inicio.
///
/// Es la misma vía que «pagar más tarde», de modo que la permanencia empieza
/// a contar desde ahora y el tramo DOSA que se cobre al volver será el que
/// corresponda al tiempo transcurrido. Si la aeronave ya figuraba pendiente,
/// conserva su registro original y el reloj no se reinicia.
Future<void> deferBecauseOffline(BuildContext context, TaxQuote quote) async {
  final AppController controller = context.read<AppController>();
  final AppStrings s = controller.strings;
  // Se toman antes del `await`: después de esperar, este contexto puede
  // haber dejado de existir.
  final NavigatorState navigator = Navigator.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  try {
    await controller.deferPayment(quote);
    await controller.audit(
      'PENDIENTE_SIN_CONEXION',
      '${quote.registration} — cobro no disponible por falta de red',
    );
    navigator.popUntil((route) => route.isFirst);
    messenger.showSnackBar(SnackBar(content: Text(s.offlineDeferred)));
  } catch (e, st) {
    AppLogger.instance.error('No se pudo diferir el pago sin red', e, st);
    messenger.showSnackBar(SnackBar(content: Text(s.errorGeneric)));
  }
}
