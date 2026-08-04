import 'package:flutter/material.dart';

/// Sistema visual de SkyTax.
///
/// Paleta *fintech* de confianza (azul institucional + dorado fiscal) sobre
/// fondo claro, tipografía IBM Plex Sans y componentes dimensionados para uso
/// táctil. Se mantiene en modo claro de forma deliberada: un kiosco en una
/// terminal muy iluminada se lee mejor con fondo claro y alto contraste.
class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'IBMPlexSans';

  // ---- Tokens de marca -----------------------------------------------------
  /// Azul institucional principal (acciones, foco, énfasis).
  static const Color brand = Color(0xFF1E40AF);
  static const Color brandBright = Color(0xFF2563EB);

  /// Tinta: color de texto principal y superficies oscuras.
  static const Color ink = Color(0xFF0F172A);

  /// Dorado fiscal, reservado para montos y totales.
  static const Color gold = Color(0xFF9A6B12);

  /// Verde de confirmación (pagos aprobados, aeronave local).
  static const Color success = Color(0xFF0F766E);

  /// Ámbar de atención (aeronave foránea, DOSA aplicada).
  static const Color attention = Color(0xFFB45309);

  static const Color _bg = Color(0xFFF4F7FB);
  static const Color _surface = Colors.white;
  static const Color _surfaceMuted = Color(0xFFEDF1F7);
  static const Color _onMuted = Color(0xFF51607A);
  static const Color _outline = Color(0xFFCBD5E5);
  static const Color _outlineVariant = Color(0xFFE1E8F2);

  /// Gradiente de marca usado en botones principales y acentos.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBright, brand],
  );

  /// Sombra suave y difusa para tarjetas y elementos elevados.
  static List<BoxShadow> softShadow({double opacity = 0.10, double blur = 28}) =>
      [
        BoxShadow(
          color: ink.withValues(alpha: opacity),
          blurRadius: blur,
          offset: Offset(0, blur * 0.32),
        ),
      ];

  static const ColorScheme _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: brand,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDCE6FF),
    onPrimaryContainer: Color(0xFF14275C),
    secondary: success,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD5F0EC),
    onSecondaryContainer: Color(0xFF0A3F3A),
    tertiary: attention,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFCEBD2),
    onTertiaryContainer: Color(0xFF5C340A),
    error: Color(0xFFDC2626),
    onError: Colors.white,
    errorContainer: Color(0xFFFCE2E2),
    onErrorContainer: Color(0xFF7A1414),
    surface: _surface,
    onSurface: ink,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFFAFBFE),
    surfaceContainer: _bg,
    surfaceContainerHigh: _surfaceMuted,
    surfaceContainerHighest: Color(0xFFE7EDF5),
    onSurfaceVariant: _onMuted,
    outline: _outline,
    outlineVariant: _outlineVariant,
    shadow: ink,
    scrim: ink,
    inverseSurface: ink,
    onInverseSurface: Color(0xFFF1F5FB),
    inversePrimary: Color(0xFFAFC4FF),
  );

  static ThemeData light() {
    final ThemeData base = ThemeData(
      colorScheme: _scheme,
      useMaterial3: true,
      fontFamily: _fontFamily,
    );

    final RoundedRectangleBorder buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
    const TextStyle buttonText = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );

    return base.copyWith(
      scaffoldBackgroundColor: _bg,
      textTheme: _textTheme(base.textTheme),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: ink,
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: _surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _surfaceMuted,
          disabledForegroundColor: _onMuted,
          minimumSize: const Size(96, 64),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: buttonShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(96, 64),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: buttonShape,
          textStyle: buttonText,
          side: const BorderSide(color: _outline, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintStyle: const TextStyle(color: Color(0xFF94A0B4)),
        labelStyle: const TextStyle(color: _onMuted),
        floatingLabelStyle: const TextStyle(
          color: brand,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: _onMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: _outlineVariant,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: base.listTileTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        iconColor: _onMuted,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: _surfaceMuted,
        side: BorderSide.none,
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _surface,
        indicatorColor: _scheme.primaryContainer,
        indicatorShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selectedIconTheme: const IconThemeData(color: brand, size: 28),
        unselectedIconTheme: const IconThemeData(color: _onMuted, size: 28),
        selectedLabelTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: brand,
        ),
        unselectedLabelTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _onMuted,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brand,
      ),
      iconTheme: const IconThemeData(color: _onMuted),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base
        .copyWith(
          displaySmall: base.displaySmall
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          headlineMedium: base.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          headlineSmall: base.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleLarge: base.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
          labelLarge: base.labelLarge?.copyWith(letterSpacing: 0.2),
        )
        .apply(
          bodyColor: ink,
          displayColor: ink,
          fontFamily: _fontFamily,
        );
  }
}
