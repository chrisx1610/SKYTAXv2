import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../domain/tax_calculator.dart';
import '../state/app_controller.dart';
import '../widgets/kiosk_widgets.dart';
import 'offline_guard.dart';
import 'payment_method_screen.dart';

/// Resumen del cálculo antes de pagar.
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.quote});

  final TaxQuote quote;

  @override
  Widget build(BuildContext context) {
    final AppController controller = context.watch<AppController>();
    final AppStrings s = controller.strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool offline = !controller.online;

    // Ancho útil dentro del scaffold (tope de 860 menos el relleno lateral).
    // Se calcula con MediaQuery y no con un LayoutBuilder porque dentro del
    // FittedBox las restricciones dejan de reflejar la pantalla real.
    final double contentWidth =
        MediaQuery.sizeOf(context).width.clamp(0.0, 860.0) - 48;

    return KioskScaffold(
      title: s.summaryTitle,
      // El resumen se lee de una sola vista: nunca se desplaza. Si el
      // desglose crece (aviso sin red, tarifa ausente, permanencia) el
      // FittedBox reduce el bloque completo en lugar de sacar una barra.
      scrollable: false,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: contentWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatusChip(
                icon: quote.isLocal
                    ? Icons.home_work_rounded
                    : Icons.connecting_airports_rounded,
                label: quote.isLocal
                    ? s.localAircraftNote
                    : s.foreignAircraftNote,
                background: quote.isLocal
                    ? scheme.secondaryContainer
                    : scheme.tertiaryContainer,
                foreground: quote.isLocal
                    ? scheme.onSecondaryContainer
                    : scheme.onTertiaryContainer,
              ),
              // Aeronave foránea cuyo modelo no está tabulado: la DOSA quedó en
              // cero y hay que advertirlo en lugar de cobrar de menos en silencio.
              if (quote.missingTariff) ...[
                const SizedBox(height: 12),
                StatusChip(
                  icon: Icons.warning_amber_rounded,
                  label: s.missingTariffWarning,
                  background: scheme.errorContainer,
                  foreground: scheme.onErrorContainer,
                ),
              ],
              // Sin red el cobro es imposible: se avisa antes de que el usuario
              // llegue al botón y descubra que no puede pagar.
              if (offline) ...[
                const SizedBox(height: 12),
                const OfflineNotice(),
              ],
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      SummaryRow(
                        label: s.registrationShort,
                        value: quote.registration,
                      ),
                      SummaryRow(
                        label: s.modelLabel,
                        value: quote.aircraftModel,
                      ),
                      SummaryRow(
                        label: s.passengersShort,
                        value: '${quote.passengers}',
                      ),
                      // Los infantes van aparte: no tributan, y sin verlos el
                      // subtotal parecería no cuadrar con los pasajeros a bordo.
                      if (quote.infants > 0)
                        SummaryRow(
                          label: s.infantsShort,
                          value: '−${quote.infants}',
                        ),
                      const Divider(height: 24),
                      SummaryRow(
                        label:
                            '${s.airportTaxLabel} (${quote.payingPassengers} × ${Formatters.money(quote.taxRate)})',
                        value: Formatters.money(quote.taxSubtotal),
                      ),
                      if (quote.hasDosa)
                        SummaryRow(
                          label: s.dosaLabel,
                          value: Formatters.money(quote.dosa),
                        ),
                      // Permanencia acumulada y tramo aplicado: solo tienen
                      // sentido cuando la aeronave difirió el pago.
                      if (quote.elapsed > Duration.zero)
                        SummaryRow(
                          label: s.stayLabel,
                          value: Formatters.stay(quote.elapsed),
                        ),
                      if (quote.dosaBracket != null)
                        SummaryRow(
                          label: s.bracketLabel,
                          value: s.bracketName(quote.dosaBracket!.index),
                        ),
                      // Vigencia de la estadía pagada: el mismo dato que se
                      // imprimirá en la factura.
                      if (quote.validUntil != null)
                        SummaryRow(
                          label: s.validUntilLabel,
                          value:
                              '${Formatters.date(quote.validUntil!)} '
                              '${Formatters.time(quote.validUntil!)}',
                        ),
                      const Divider(height: 24),
                      SummaryRow(
                        label: s.totalToPay,
                        value: Formatters.money(quote.total),
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              KioskActionBar(
                secondaryLabel: s.cancel,
                onSecondary: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                primaryLabel: s.continueLabel,
                primaryIcon: Icons.arrow_forward_rounded,
                // Sin red no se entra al cobro: la aeronave queda registrada
                // como pendiente y el usuario vuelve cuando se restablezca.
                onPrimary: () => offline
                    ? deferBecauseOffline(context, quote)
                    : Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PaymentMethodScreen(quote: quote),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
