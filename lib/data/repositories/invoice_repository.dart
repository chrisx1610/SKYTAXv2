import '../database/skytax_database.dart';
import '../models/models.dart';

/// Granularidad del eje temporal de los gráficos de reportes.
///
/// Las fechas se guardan en ISO 8601, de modo que recortar la cadena por la
/// izquierda basta para agrupar: 7 caracteres dan el mes, 10 el día y 13 la
/// hora. Evita convertir a fecha en SQL, que sqflite no resuelve igual en
/// todas las plataformas.
enum InvoiceBucketSize {
  hour(13),
  day(10),
  month(7);

  const InvoiceBucketSize(this.keyLength);

  /// Caracteres del ISO 8601 que identifican el tramo.
  final int keyLength;

  /// Clave del tramo al que pertenece [moment].
  String keyOf(DateTime moment) =>
      moment.toIso8601String().substring(0, keyLength);
}

/// Facturación acumulada en un tramo del eje temporal.
class InvoiceBucket {
  const InvoiceBucket({required this.count, required this.total});

  final int count;
  final double total;

  /// Tramo sin actividad. Se usa para rellenar los huecos del eje: sin ellos
  /// los días vacíos desaparecerían y el gráfico mentiría sobre el ritmo.
  static const InvoiceBucket empty = InvoiceBucket(count: 0, total: 0);
}

/// Resumen agregado usado por la sección de reportes.
class InvoiceStats {
  const InvoiceStats({
    required this.count,
    required this.total,
    required this.totalByMethod,
    this.buckets = const {},
  });

  final int count;
  final double total;
  final Map<String, double> totalByMethod;

  /// Facturación por tramo temporal, indexada por la clave del tramo.
  final Map<String, InvoiceBucket> buckets;
}

/// Persistencia y consulta de facturas emitidas.
class InvoiceRepository {
  InvoiceRepository(this._dbase);

  final SkyTaxDatabase _dbase;

  Future<int> insert(Invoice invoice) async {
    return _dbase.database.insert('invoices', invoice.toMap()..remove('id'));
  }

  Future<List<Invoice>> getAll({String? search}) async {
    final String? term = (search == null || search.trim().isEmpty)
        ? null
        : '%${search.trim().toUpperCase()}%';
    final rows = await _dbase.database.query(
      'invoices',
      where: term == null
          ? null
          : 'UPPER(registration) LIKE ? OR UPPER(number) LIKE ?',
      whereArgs: term == null ? null : [term, term],
      orderBy: 'id DESC',
    );
    return rows.map(Invoice.fromMap).toList();
  }

  Future<InvoiceStats> statsSince(
    DateTime? since, {
    InvoiceBucketSize bucket = InvoiceBucketSize.day,
  }) async {
    final String where = since == null ? '' : 'WHERE created_at >= ?';
    final List<Object?> args = since == null ? [] : [since.toIso8601String()];

    final totalRows = await _dbase.database.rawQuery(
      'SELECT COUNT(*) AS c, COALESCE(SUM(total), 0) AS t FROM invoices $where',
      args,
    );
    final methodRows = await _dbase.database.rawQuery(
      'SELECT payment_method, COALESCE(SUM(total), 0) AS t '
      'FROM invoices $where GROUP BY payment_method',
      args,
    );
    final bucketRows = await _dbase.database.rawQuery(
      'SELECT substr(created_at, 1, ${bucket.keyLength}) AS k, '
      'COUNT(*) AS c, COALESCE(SUM(total), 0) AS t '
      'FROM invoices $where GROUP BY k ORDER BY k',
      args,
    );

    return InvoiceStats(
      count: (totalRows.first['c'] as num).toInt(),
      total: (totalRows.first['t'] as num).toDouble(),
      totalByMethod: {
        for (final row in methodRows)
          row['payment_method'] as String: (row['t'] as num).toDouble(),
      },
      buckets: {
        for (final row in bucketRows)
          row['k'] as String: InvoiceBucket(
            count: (row['c'] as num).toInt(),
            total: (row['t'] as num).toDouble(),
          ),
      },
    );
  }
}
