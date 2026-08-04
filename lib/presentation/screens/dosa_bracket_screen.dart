import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../domain/dosa_schedule.dart';
import '../../domain/tax_calculator.dart';
import '../state/app_controller.dart';
import '../widgets/kiosk_widgets.dart';
import 'summary_screen.dart';

/// Selección del tramo de permanencia que la aeronave va a pagar.
///
/// Cada botón muestra el importe de la tarifa y hasta qué día y hora quedaría
/// cubierta la estadía si se eligiera en este momento. Esa misma fecha se
/// imprime luego en la factura.
class DosaBracketScreen extends StatelessWidget {
  const DosaBracketScreen({
    super.key,
    required this.quote,
    required this.tariff,
  });

  final TaxQuote quote;

  /// Tarifa del modelo de la aeronave. Nunca es `null` aquí: la pantalla solo
  /// se muestra cuando el modelo está tabulado.
  final DosaTariff tariff;

  void _choose(BuildContext context, DosaBracket bracket) {
    final AppController controller = context.read<AppController>();
    final TaxQuote priced = AppController.calculator.withBracket(
      quote,
      tariff: tariff,
      bracket: bracket,
      paidAt: DateTime.now(),
    );
    controller.audit(
      'TARIFA_SELECCIONADA',
      '${priced.registration} — ${bracket.name} — '
          '${Formatters.money(priced.dosa)}',
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SummaryScreen(quote: priced)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final DateTime now = DateTime.now();

    return KioskScaffold(
      title: s.chooseBracketTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.chooseBracketSubtitle,
            style: TextStyle(fontSize: 17, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          // Dos columnas en pantallas amplias, una en las angostas: seis
          // opciones apiladas serían una lista demasiado larga en tablet.
          LayoutBuilder(
            builder: (context, constraints) {
              final bool twoColumns = constraints.maxWidth >= 620;
              final double itemWidth = twoColumns
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final DosaBracket bracket in DosaBracket.values)
                    SizedBox(
                      width: itemWidth,
                      child: _BracketTile(
                        label: s.bracketName(bracket.index),
                        amount: dosaAmountForBracket(tariff, bracket),
                        coversUntilLabel: s.coversUntil,
                        validUntil: dosaValidUntil(now, bracket),
                        onTap: () => _choose(context, bracket),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          KioskSecondaryButton(
            label: s.cancel,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}

/// Botón de un tramo: nombre, importe y vigencia resultante.
class _BracketTile extends StatelessWidget {
  const _BracketTile({
    required this.label,
    required this.amount,
    required this.coversUntilLabel,
    required this.validUntil,
    required this.onTap,
  });

  final String label;
  final double amount;
  final String coversUntilLabel;
  final DateTime validUntil;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: AppTheme.softShadow(opacity: 0.07),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$coversUntilLabel: '
                      '${Formatters.date(validUntil)} '
                      '${Formatters.time(validUntil)}',
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                Formatters.money(amount),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
