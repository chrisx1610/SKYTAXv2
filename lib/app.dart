import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/language_screen.dart';
import 'presentation/state/app_controller.dart';

/// Raíz de la aplicación SkyTax.
class SkyTaxApp extends StatelessWidget {
  const SkyTaxApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppController>.value(
      value: controller,
      child: Consumer<AppController>(
        builder: (context, c, _) => MaterialApp(
          title: 'SkyTax',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          // El kiosco se mantiene en modo claro para máxima legibilidad en
          // terminales muy iluminadas, sin depender del tema del sistema.
          themeMode: ThemeMode.light,
          locale: c.locale,
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LanguageScreen(),
        ),
      ),
    );
  }
}
