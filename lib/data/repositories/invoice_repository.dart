import '../database/skytax_database.dart';
import '../models/models.dart';

/// Resumen agregado usado por la sección de reportes.
class InvoiceStats {
  const InvoiceStats({
    required this.count,
    required this.total,
    required this.totalByMethod,
  });

  final int count;
  final double total;
  final Map<String, double> totalByMethod;
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

  Future<InvoiceStats> statsSince(DateTime? since) async {
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

    return InvoiceStats(
      count: (totalRows.first['c'] as num).toInt(),
      total: (totalRows.first['t'] as num).toDouble(),
      totalByMethod: {
        for (final row in methodRows)
          row['payment_method'] as String: (row['t'] as num).toDouble(),
      },
    );
  }
}
