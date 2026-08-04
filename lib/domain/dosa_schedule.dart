import '../data/models/models.dart';

/// Tramos de permanencia contemplados por la tabla de tarifas DOSA.
enum DosaBracket {
  upTo2Hours,
  oneDay,
  days2To7,
  days8To14,
  days15To21,
  days22To30,
}

/// Selección del tramo de la DOSA según el tiempo transcurrido desde que la
/// aeronave quedó registrada (es decir, desde que el usuario cargó los datos).
///
/// Los límites son inclusivos por arriba: exactamente 2 horas todavía es el
/// primer tramo, y exactamente 7 días sigue siendo «del 2.º al 7.º día».
///
/// Por encima de 30 días no hay tarifa definida en la norma cargada, así que
/// se mantiene la del último tramo (22.º al 30.º día) en lugar de dejar el
/// importe en cero.
DosaBracket dosaBracketFor(Duration elapsed) {
  if (elapsed <= const Duration(hours: 2)) return DosaBracket.upTo2Hours;
  if (elapsed <= const Duration(days: 1)) return DosaBracket.oneDay;
  if (elapsed <= const Duration(days: 7)) return DosaBracket.days2To7;
  if (elapsed <= const Duration(days: 14)) return DosaBracket.days8To14;
  if (elapsed <= const Duration(days: 21)) return DosaBracket.days15To21;
  return DosaBracket.days22To30;
}

/// Permanencia que cubre cada tramo, contada desde el momento del pago.
///
/// Es el tope del tramo: quien paga «del 2.º al 7.º día» queda cubierto
/// durante 7 días completos.
Duration dosaBracketDuration(DosaBracket bracket) => switch (bracket) {
      DosaBracket.upTo2Hours => const Duration(hours: 2),
      DosaBracket.oneDay => const Duration(days: 1),
      DosaBracket.days2To7 => const Duration(days: 7),
      DosaBracket.days8To14 => const Duration(days: 14),
      DosaBracket.days15To21 => const Duration(days: 21),
      DosaBracket.days22To30 => const Duration(days: 30),
    };

/// Instante hasta el que es válida una estadía pagada en [paidAt] por
/// [bracket]. Es la fecha y hora que se imprime en la factura.
DateTime dosaValidUntil(DateTime paidAt, DosaBracket bracket) =>
    paidAt.add(dosaBracketDuration(bracket));

/// Importe de [tariff] correspondiente a [bracket].
double dosaAmountForBracket(DosaTariff tariff, DosaBracket bracket) =>
    tariff.brackets[bracket.index];

/// Importe de la DOSA para una permanencia dada.
///
/// La tabla de tarifas es la única fuente del importe. Si el modelo de la
/// aeronave no figura en ella ([tariff] es `null`) no hay precio que aplicar y
/// se devuelve cero; la pantalla de resumen avisa de la situación para que no
/// pase inadvertida.
double dosaAmount({
  required DosaTariff? tariff,
  required Duration elapsed,
}) {
  if (tariff == null) return 0;
  return dosaAmountForBracket(tariff, dosaBracketFor(elapsed));
}
