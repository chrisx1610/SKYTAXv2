import '../data/models/models.dart';

/// Resultado de interpretar una hoja de tarifas DOSA.
class DosaTariffImport {
  const DosaTariffImport({
    required this.toInsert,
    required this.skippedExisting,
    required this.unreadableRows,
  });

  /// Tarifas nuevas, listas para guardar.
  final List<DosaTariff> toInsert;

  /// Modelos que ya estaban cargados en la aplicación y no se tocan.
  final List<String> skippedExisting;

  /// Filas que parecían datos pero no se pudieron leer.
  final int unreadableRows;

  bool get isEmpty => toInsert.isEmpty;
}

/// Interpreta la hoja de tarifas DOSA exportada del tabulador oficial.
///
/// Recibe las celdas ya convertidas a texto para no atar esta lógica a
/// ninguna librería de hojas de cálculo: así puede probarse sin abrir un
/// archivo real.
///
/// La hoja trae una fila de encabezados y, debajo, una fila por aeronave con
/// su código, su descripción, el número de tarifa y los importes de los seis
/// tramos de permanencia.
///
/// Las aeronaves que ya tienen tarifa en la aplicación se omiten: la carga
/// masiva sirve para dar de alta lo que falta, nunca para pisar importes que
/// un administrador pudo ajustar a mano.
DosaTariffImport parseDosaTariffSheet(
  List<List<String?>> rows, {
  required Set<String> existingModels,
}) {
  final Set<String> taken = {
    for (final String m in existingModels) m.trim().toLowerCase(),
  };
  final List<DosaTariff> toInsert = [];
  final List<String> skipped = [];
  int unreadable = 0;

  final int headerRow = _headerRowIndex(rows);
  final int codeColumn = headerRow < 0 ? 0 : _codeColumnIndex(rows[headerRow]);

  for (int r = headerRow + 1; r < rows.length; r++) {
    final List<String?> row = rows[r];
    if (codeColumn >= row.length) continue;

    final String model = (row[codeColumn] ?? '').trim();
    if (model.isEmpty) continue;

    // Los seis importes son los últimos seis números de la fila. Tomarlos
    // desde el final —y no por posición fija— deja fuera el número de
    // tarifa y aguanta que la hoja lleve columnas descriptivas de más.
    final List<double> amounts = _trailingAmounts(row, 6);
    if (amounts.length < 6) {
      unreadable++;
      continue;
    }

    final String key = model.toLowerCase();
    if (taken.contains(key)) {
      skipped.add(model);
      continue;
    }
    taken.add(key);

    toInsert.add(DosaTariff(
      model: model,
      upTo2Hours: amounts[0],
      oneDay: amounts[1],
      days2To7: amounts[2],
      days8To14: amounts[3],
      days15To21: amounts[4],
      days22To30: amounts[5],
    ));
  }

  return DosaTariffImport(
    toInsert: toInsert,
    skippedExisting: skipped,
    unreadableRows: unreadable,
  );
}

/// Fila de encabezados: la primera que menciona la columna de código.
/// Devuelve -1 si la hoja no la trae, en cuyo caso se leen todas las filas.
int _headerRowIndex(List<List<String?>> rows) {
  for (int r = 0; r < rows.length && r < 20; r++) {
    for (final String? cell in rows[r]) {
      if (_isCodeHeader(cell)) return r;
    }
  }
  return -1;
}

int _codeColumnIndex(List<String?> header) {
  for (int c = 0; c < header.length; c++) {
    if (_isCodeHeader(header[c])) return c;
  }
  return 0;
}

bool _isCodeHeader(String? cell) {
  if (cell == null) return false;
  final String v = cell
      .trim()
      .toLowerCase()
      .replaceAll('ó', 'o')
      .replaceAll('í', 'i');
  return v == 'codigo' || v == 'code';
}

/// Los últimos [count] números de la fila, en el orden en que aparecen.
List<double> _trailingAmounts(List<String?> row, int count) {
  final List<double> found = [];
  for (final String? cell in row) {
    final double? value = parseSheetAmount(cell);
    if (value != null) found.add(value);
  }
  if (found.length < count) return const [];
  return found.sublist(found.length - count);
}

/// Convierte el texto de una celda en importe.
///
/// Acepta separador de miles y decimal en cualquiera de los dos usos
/// habituales (`1,439.69` y `1.439,69`): cuando aparecen ambos signos, manda
/// el que esté más a la derecha. Devuelve `null` si la celda no es un número.
double? parseSheetAmount(String? cell) {
  if (cell == null) return null;
  String v = cell.trim();
  if (v.isEmpty) return null;
  // Símbolos de moneda y espacios de agrupación.
  v = v.replaceAll(RegExp(r'[€$\s\u00A0]'), '');
  if (v.isEmpty) return null;

  final int lastDot = v.lastIndexOf('.');
  final int lastComma = v.lastIndexOf(',');
  if (lastDot >= 0 && lastComma >= 0) {
    if (lastDot > lastComma) {
      v = v.replaceAll(',', '');
    } else {
      v = v.replaceAll('.', '').replaceAll(',', '.');
    }
  } else if (lastComma >= 0) {
    // Una sola coma: decimal si deja una o dos cifras detrás, miles si no.
    v = (v.length - lastComma - 1) <= 2
        ? v.replaceAll(',', '.')
        : v.replaceAll(',', '');
  }

  final double? parsed = double.tryParse(v);
  if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;
  return parsed < 0 ? null : parsed;
}
