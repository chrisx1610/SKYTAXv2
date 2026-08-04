import '../database/skytax_database.dart';
import '../models/models.dart';

/// Registro de auditoría de operaciones del sistema.
class AuditRepository {
  AuditRepository(this._dbase);

  final SkyTaxDatabase _dbase;

  Future<void> log(AuditEntry entry) async {
    await _dbase.database.insert('audit_log', entry.toMap()..remove('id'));
  }

  Future<List<AuditEntry>> getRecent({int limit = 200}) async {
    final rows = await _dbase.database
        .query('audit_log', orderBy: 'id DESC', limit: limit);
    return rows.map(AuditEntry.fromMap).toList();
  }
}
