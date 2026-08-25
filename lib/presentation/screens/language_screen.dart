import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../state/app_controller.dart';
import '../widgets/kiosk_widgets.dart';
import 'menu_screen.dart';

/// Pantalla inicial: selección de idioma (Español / English).
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  void _select(BuildContext context, String code) {
    context.read<AppController>().setLanguage(code);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = context.watch<AppController>();
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final Size viewport = MediaQuery.sizeOf(context);
    final bool shortScreen = viewport.height < 900;
    final double logoSize = (viewport.height * 0.20).clamp(120.0, 280.0);

    // Ancho util dentro del scaffold (tope de 860 menos el relleno lateral).
    // Se calcula aqui, y no con un LayoutBuilder, porque dentro del FittedBox
    // las restricciones dejan de reflejar el tamano real de la pantalla.
    final double contentWidth = viewport.width.clamp(0.0, 860.0) - 48;
    final bool wide = contentWidth > 560;

    final List<Widget> cards = [
      BigChoiceCard(
        image: const _LanguageBadge('ES'),
        label: 'Español',
        onTap: () => _select(context, 'es'),
      ),
      BigChoiceCard(
        image: const _LanguageBadge('EN'),
        label: 'English',
        onTap: () => _select(context, 'en'),
      ),
    ];

    return KioskScaffold(
      // Pantalla de una sola vista: nunca se desplaza. Si el conjunto no cabe
      // a lo alto, el FittedBox lo reduce en bloque en lugar de recortarlo o
      // de sacar una barra de desplazamiento.
      scrollable: false,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: contentWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkyTaxLogo(size: logoSize),
              SizedBox(height: shortScreen ? 24 : 40),
              Text(
                controller.strings.welcomeTouch,
                style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              const Text(
                'Seleccione el idioma · Select your language',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: shortScreen ? 24 : 32),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 24),
                      Expanded(child: cards[1]),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [cards[0], const SizedBox(height: 20), cards[1]],
                ),
              SizedBox(height: shortScreen ? 28 : 48),
              Text(
                controller.config.airportDisplay,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Distintivo con el código del idioma (ES / EN), con el mismo acabado
/// de marca que los emblemas de ícono del resto del kiosco.
class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: Colors.white,
        ),
      ),
    );
  }
}
