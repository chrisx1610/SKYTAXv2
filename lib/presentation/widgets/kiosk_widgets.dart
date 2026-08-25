import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';

/// Estructura base de las pantallas del kiosco: barra superior opcional y
/// contenido centrado con ancho máximo, apto para tablets y monitores.
///
/// El fondo lleva un lavado de marca muy sutil (gradiente + destello superior)
/// para dar profundidad sin restar legibilidad al contenido.
class KioskScaffold extends StatelessWidget {
  const KioskScaffold({
    super.key,
    this.title,
    this.actions,
    this.maxWidth = 860,
    this.scrollable = true,
    this.decorated = true,
    required this.child,
  });

  final String? title;
  final List<Widget>? actions;
  final double maxWidth;
  final bool scrollable;

  /// Aplica el lavado de marca de fondo. Se puede desactivar para pantallas
  /// que ya definen su propio fondo.
  final bool decorated;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: child,
      ),
    );

    final Widget body = SafeArea(
      child: scrollable
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: content),
              ),
            )
          : Center(child: content),
    );

    final Widget scaffold = Scaffold(
      backgroundColor: decorated ? Colors.transparent : null,
      appBar: (title != null || actions != null)
          ? AppBar(title: title == null ? null : Text(title!), actions: actions)
          : null,
      body: body,
    );

    // El lavado de marca envuelve todo el Scaffold (incluida la zona del
    // AppBar transparente); de lo contrario esa franja se vería negra.
    return decorated ? KioskBackground(child: scaffold) : scaffold;
  }
}

/// Lavado de fondo de marca: gradiente claro con un destello azul superior.
class KioskBackground extends StatelessWidget {
  const KioskBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7FAFE), Color(0xFFEFF3FA)],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.15),
            radius: 1.1,
            colors: [Color(0x142563EB), Color(0x002563EB)],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Escala levemente el contenido al presionar, para dar respuesta táctil.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.onTap, required this.builder});

  final VoidCallback? onTap;
  final Widget Function(bool pressed) builder;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: (_pressed && !reduceMotion) ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.builder(_pressed),
      ),
    );
  }
}

/// Botón principal de gran tamaño para uso táctil.
///
/// El botón primario usa el gradiente de marca; la variante [tonal] usa el
/// contenedor secundario del tema.
class BigActionButton extends StatelessWidget {
  const BigActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tonal = false,
    this.height = 72,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool tonal;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool enabled = onPressed != null;

    final Widget text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    );

    if (tonal) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
          ),
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 28),
          label: text,
        ),
      );
    }

    final List<Widget> rowChildren = [
      if (icon != null) ...[Icon(icon, size: 28), const SizedBox(width: 12)],
      Flexible(child: text),
    ];

    return _PressScale(
      onTap: onPressed,
      builder: (pressed) => Container(
        width: double.infinity,
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: enabled ? AppTheme.brandGradient : null,
          color: enabled ? null : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled && !pressed
              ? [
                  BoxShadow(
                    color: AppTheme.brand.withValues(alpha: 0.32),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: enabled ? Colors.white : scheme.onSurfaceVariant,
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              color: enabled ? Colors.white : scheme.onSurfaceVariant,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: rowChildren),
          ),
        ),
      ),
    );
  }
}

/// Barra de acciones con botón secundario (cancelar/atrás) y principal.
///
/// Se adapta al ancho disponible: en pantallas anchas coloca los botones lado
/// a lado; en pantallas angostas (teléfonos) los apila a todo el ancho. En
/// ambos casos el texto nunca se parte en dos líneas.
class KioskActionBar extends StatelessWidget {
  const KioskActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryIcon,
    this.stackBreakpoint = 480,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final IconData? primaryIcon;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData? secondaryIcon;

  /// Ancho por debajo del cual los botones se apilan verticalmente.
  final double stackBreakpoint;

  Widget _primary({required double height}) => SizedBox(
        height: height,
        child: BigActionButton(
          label: primaryLabel,
          icon: primaryIcon,
          onPressed: onPrimary,
          height: height,
        ),
      );

  Widget _secondary({required double height}) => KioskSecondaryButton(
        label: secondaryLabel!,
        icon: secondaryIcon,
        onPressed: onSecondary,
        height: height,
      );

  @override
  Widget build(BuildContext context) {
    if (secondaryLabel == null) {
      return SizedBox(
        width: double.infinity,
        child: _primary(height: 72),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < stackBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _primary(height: 72),
              const SizedBox(height: 12),
              _secondary(height: 64),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 2, child: _secondary(height: 72)),
            const SizedBox(width: 20),
            Expanded(flex: 3, child: _primary(height: 72)),
          ],
        );
      },
    );
  }
}

/// Botón secundario del kiosco (Cancelar, Volver).
///
/// Es la contraparte de [BigActionButton]: mismo tamaño generoso para uso
/// táctil pero con contorno en lugar de relleno. Vive aquí para que el botón
/// de cancelar sea idéntico en todas las pantallas del kiosco.
class KioskSecondaryButton extends StatelessWidget {
  const KioskSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 64,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  static const EdgeInsets _pad =
      EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  @override
  Widget build(BuildContext context) {
    // Una sola línea con puntos suspensivos: el texto nunca se parte a mitad
    // de palabra por estrecha que sea la pantalla.
    final Widget text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
    final ButtonStyle style = OutlinedButton.styleFrom(padding: _pad);

    return SizedBox(
      height: height,
      child: icon == null
          ? OutlinedButton(style: style, onPressed: onPressed, child: text)
          : OutlinedButton.icon(
              style: style,
              onPressed: onPressed,
              icon: Icon(icon, size: 24),
              label: text,
            ),
    );
  }
}

/// Tarjeta de selección grande (idiomas, métodos de pago).
class BigChoiceCard extends StatelessWidget {
  const BigChoiceCard({
    super.key,
    this.icon,
    this.image,
    required this.label,
    this.sublabel,
    required this.onTap,
    this.enabled = true,
  }) : assert(icon != null || image != null, 'Se requiere icon o image');

  final IconData? icon;

  /// Ilustración personalizada (p. ej. una bandera). Cuando se indica,
  /// sustituye al contenedor con ícono.
  final Widget? image;
  final String label;
  final String? sublabel;
  final VoidCallback onTap;

  /// Cuando es `false` la tarjeta se apaga —fondo gris, sin relieve y con el
  /// texto atenuado— y deja de responder al toque, de modo que se vea de un
  /// vistazo que la opción no está disponible.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color muted = scheme.onSurface.withValues(alpha: 0.38);

    return _PressScale(
      onTap: enabled ? onTap : null,
      builder: (pressed) => Container(
        decoration: BoxDecoration(
          color: enabled ? Colors.white : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: pressed ? AppTheme.brand : scheme.outlineVariant,
            width: pressed ? 2 : 1,
          ),
          boxShadow: enabled
              ? AppTheme.softShadow(opacity: pressed ? 0.05 : 0.09)
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            image ??
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: enabled ? AppTheme.brandGradient : null,
                    color: enabled ? null : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: enabled
                        ? [
                            BoxShadow(
                              color: AppTheme.brand.withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 52,
                    color: enabled ? Colors.white : muted,
                  ),
                ),
            const SizedBox(height: 20),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: enabled ? scheme.onSurface : muted,
              ),
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 6),
              // Se reservan siempre dos lineas, ocupelas o no el texto: asi
              // dos tarjetas contiguas miden exactamente lo mismo aunque un
              // subtitulo sea mas largo que el otro.
              SizedBox(
                height: MediaQuery.textScalerOf(context).scale(16) * 1.35 * 2,
                child: Text(
                  sublabel!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    color: enabled ? scheme.onSurfaceVariant : muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fila etiqueta/valor usada en resúmenes y confirmaciones.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: emphasized ? 22 : 18,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
                color: emphasized ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: emphasized ? 28 : 18,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              color: emphasized ? AppTheme.gold : scheme.onSurface,
              letterSpacing: emphasized ? -0.5 : 0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta de estado compacta (aeronave local / foránea, etc.).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: foreground,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logotipo de la aplicación.
///
/// Muestra la imagen de marca `assets/images/skytax_logo.png`. Si el archivo
/// aún no está disponible, dibuja un respaldo con el emblema y el nombre para
/// que la interfaz nunca quede vacía.
class SkyTaxLogo extends StatelessWidget {
  const SkyTaxLogo({super.key, this.size = 220});

  /// Ancho máximo del logotipo.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow(opacity: 0.08),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/images/skytax_logo.png',
          width: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _FallbackLogo(size: size),
        ),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient,
            borderRadius: BorderRadius.circular(size * 0.16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brand.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(Icons.flight_takeoff_rounded,
              size: size * 0.28, color: Colors.white),
        ),
        SizedBox(height: size * 0.08),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Sky'),
              TextSpan(
                text: 'Tax',
                style: TextStyle(color: AppTheme.brand),
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: AppTheme.ink,
          ),
        ),
      ],
    );
  }
}

/// Encabezado de sección del panel administrativo: título + acción opcional.
///
/// En pantallas anchas el título y el botón comparten una fila; en pantallas
/// angostas el botón baja a una segunda línea, de modo que el título nunca
/// se parte letra por letra.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        ?action,
      ],
    );
  }
}

/// Tarjeta de un elemento de listado del panel administrativo.
///
/// Se reorganiza según el ancho disponible: en pantallas amplias coloca
/// emblema, textos y acciones en una sola fila; en pantallas angostas baja
/// las acciones a una segunda línea para que los textos dispongan de todo
/// el ancho y nunca se partan a mitad de palabra.
class AdminListCard extends StatelessWidget {
  const AdminListCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconBackground,
    this.iconColor,
    this.actions = const <Widget>[],
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconBackground;
  final Color? iconColor;
  final List<Widget> actions;
  final VoidCallback? onTap;

  /// Por debajo de este ancho las acciones pasan a una segunda línea.
  static const double _stackBreakpoint = 420;

  /// Por debajo de este ancho el emblema y los márgenes se compactan para
  /// ceder todo el espacio posible a los textos.
  static const double _compactBreakpoint = 360;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool inlineActions =
                constraints.maxWidth >= _stackBreakpoint;
            final bool compact = constraints.maxWidth < _compactBreakpoint;

            final double emblemRadius = compact ? 18 : 24;
            final double gap = compact ? 12 : 16;
            final EdgeInsets padding = EdgeInsets.symmetric(
              horizontal: compact ? 16 : 20,
              vertical: 14,
            );

            final Widget header = Row(
              children: [
                CircleAvatar(
                  radius: emblemRadius,
                  backgroundColor: iconBackground ?? scheme.primaryContainer,
                  child: Icon(
                    icon,
                    size: compact ? 20 : 24,
                    color: iconColor ?? scheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                              fontSize: 15, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );

            return Padding(
              padding: padding,
              child: inlineActions
                  ? Row(children: [Expanded(child: header), ...actions])
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: actions,
                          ),
                        ],
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

/// Tabla de tarifas DOSA por modelo de aeronave.
///
/// Se adapta al ancho disponible: en pantallas amplias muestra una tabla real
/// con desplazamiento horizontal propio (la página nunca se desborda); en
/// pantallas angostas cambia a una tarjeta por modelo con los seis tramos en
/// dos columnas —o una sola si el espacio es mínimo— para que ni las etiquetas
/// ni los importes se partan a mitad de palabra.
class DosaTariffTable extends StatelessWidget {
  const DosaTariffTable({
    super.key,
    required this.tariffs,
    required this.modelLabel,
    required this.bracketLabels,
    required this.editTooltip,
    required this.deleteTooltip,
    this.onEdit,
    this.onDelete,
  });

  final List<DosaTariff> tariffs;
  final String modelLabel;

  /// Los seis encabezados de tramo, en el orden de [DosaTariff.brackets].
  final List<String> bracketLabels;

  final String editTooltip;
  final String deleteTooltip;
  final void Function(DosaTariff)? onEdit;
  final void Function(DosaTariff)? onDelete;

  /// Por debajo de este ancho la tabla se convierte en tarjetas apiladas.
  static const double tableBreakpoint = 900;

  /// Por debajo de este ancho los tramos pasan a una sola columna.
  static const double singleColumnBreakpoint = 320;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= tableBreakpoint
          ? _table(context)
          : _cards(context),
    );
  }

  Widget _table(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, height: 1.2),
        columnSpacing: 26,
        columns: [
          DataColumn(label: Text(modelLabel)),
          for (final String label in bracketLabels)
            DataColumn(label: Text(label)),
          const DataColumn(label: Text('')),
        ],
        rows: [
          for (final DosaTariff t in tariffs)
            DataRow(
              cells: [
                DataCell(
                  Text(t.model,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: onEdit == null ? null : () => onEdit!(t),
                ),
                for (final double amount in t.brackets)
                  DataCell(Text(Formatters.money(amount))),
                DataCell(_actions(scheme, t)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cards(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (final DosaTariff t in tariffs)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            child: InkWell(
              onTap: onEdit == null ? null : () => onEdit!(t),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.model,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        _actions(scheme, t),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool twoColumns =
                            constraints.maxWidth >= singleColumnBreakpoint;
                        final double itemWidth = twoColumns
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            for (int i = 0; i < bracketLabels.length; i++)
                              SizedBox(
                                width: itemWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bracketLabels[i],
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant),
                                    ),
                                    Text(
                                      Formatters.money(t.brackets[i]),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _actions(ColorScheme scheme, DosaTariff t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: editTooltip,
            icon: const Icon(Icons.edit_rounded),
            onPressed: onEdit == null ? null : () => onEdit!(t),
          ),
          IconButton(
            tooltip: deleteTooltip,
            icon: Icon(Icons.delete_rounded, color: scheme.error),
            onPressed: onDelete == null ? null : () => onDelete!(t),
          ),
        ],
      );
}

/// Visor de texto monoespaciado para mostrar el contenido de una factura.
class InvoiceTextViewer extends StatelessWidget {
  const InvoiceTextViewer({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: SingleChildScrollView(
        child: Text(
          content,
          style: const TextStyle(
            fontFamily: 'Consolas',
            fontFamilyFallback: ['Courier New', 'monospace'],
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
