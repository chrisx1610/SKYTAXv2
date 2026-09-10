import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Grosor máximo de una barra. Por encima dejan de leerse como marcas y
/// pasan a parecer bloques de color.
const double _maxBarWidth = 46;

/// Una barra del gráfico: su etiqueta de eje, el valor y el texto exacto que
/// se muestra al mantener pulsado.
class BarDatum {
  const BarDatum({
    required this.axisLabel,
    required this.value,
    required this.tooltip,
  });

  /// Etiqueta bajo la barra. Puede ocultarse si no hay sitio.
  final String axisLabel;

  final double value;

  /// Valor exacto, ya formateado, para la ayuda emergente.
  final String tooltip;
}

/// Gráfico de barras de una sola serie.
///
/// Una serie por gráfico y un solo eje: dos magnitudes distintas —un conteo y
/// un importe— nunca comparten escala, así que van en dos gráficos separados.
/// Al ser una sola serie no lleva leyenda; el título nombra lo que se mide.
class BarChartCard extends StatelessWidget {
  const BarChartCard({
    super.key,
    required this.title,
    required this.bars,
    required this.color,
    required this.emptyLabel,
    this.height = 180,
  });

  final String title;
  final List<BarDatum> bars;

  /// Color de la serie. Tomado de los tokens del tema, nunca inventado.
  final Color color;

  /// Texto a mostrar cuando no hubo facturación en todo el período.
  final String emptyLabel;

  /// Alto del área de dibujo, sin contar título ni etiquetas del eje.
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double maxValue =
        bars.fold<double>(0, (acc, b) => b.value > acc ? b.value : acc);

    // Con muchas barras las etiquetas se pisan: se muestra una de cada
    // `step` para que el eje siga siendo legible.
    final int step = (bars.length / 7).ceil().clamp(1, 999);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Sin esto la tarjeta se estira a toda la altura disponible y deja
          // un hueco enorme bajo el gráfico.
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            if (bars.isEmpty || maxValue <= 0)
              SizedBox(
                height: height,
                child: Center(
                  child: Text(
                    emptyLabel,
                    style: TextStyle(
                        fontSize: 15, color: scheme.onSurfaceVariant),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Marca fina: con pocas barras se limita su grosor en vez
                    // de repartir todo el ancho, que las volvería bloques.
                    final double slot =
                        (constraints.maxWidth - 2 * (bars.length - 1)) /
                            bars.length;
                    final double barWidth = slot.clamp(1.0, _maxBarWidth);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < bars.length; i++) ...[
                          if (i > 0) const SizedBox(width: 2),
                          Expanded(
                            child: _Bar(
                              datum: bars[i],
                              fraction: bars[i].value / maxValue,
                              // Solo la barra mayor lleva su valor escrito: da
                              // la escala sin llenar el gráfico de números.
                              showValue: bars[i].value == maxValue,
                              color: color,
                              areaHeight: height,
                              width: barWidth,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              // Línea base: sin ella las barras flotarían sin referencia.
              Container(height: 1, color: scheme.outlineVariant),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (int i = 0; i < bars.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        i % step == 0 ? bars[i].axisLabel : '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Barra individual, anclada a la línea base y con la punta redondeada.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.datum,
    required this.fraction,
    required this.showValue,
    required this.color,
    required this.areaHeight,
    required this.width,
  });

  final BarDatum datum;
  final double fraction;
  final bool showValue;
  final Color color;
  final double areaHeight;

  /// Grosor de la barra, ya limitado por el gráfico.
  final double width;

  @override
  Widget build(BuildContext context) {
    // Se reserva sitio arriba para el valor de la barra mayor, de modo que
    // el texto nunca quede recortado por el borde del área.
    const double labelSpace = 22;
    final double usable = areaHeight - labelSpace;
    final double barHeight = (usable * fraction).clamp(fraction > 0 ? 3.0 : 0.0, usable);

    return Tooltip(
      message: '${datum.axisLabel} · ${datum.tooltip}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: labelSpace,
            child: showValue
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      datum.tooltip,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  )
                : null,
          ),
          Container(
            height: barHeight,
            width: width,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
