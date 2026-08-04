import 'package:sqflite/sqflite.dart';

import '../database/skytax_database.dart';
import '../models/models.dart';

/// Consultas y mantenimiento de aeronaves del aeropuerto local.
class AircraftRepository {
  AircraftRepository(this._dbase);

  final SkyTaxDatabase _dbase;

  static const String _baseQuery =
      'SELECT id, registration, model, capacity FROM aircraft';

  Future<List<Aircraft>> getAll() async {
    final rows =
        await _dbase.database.rawQuery('$_baseQuery ORDER BY registration');
    return rows.map(Aircraft.fromMap).toList();
  }

  /// Busca una matrícula en la base de datos local (sin distinguir
  /// mayúsculas). Devuelve `null` si la aeronave no pertenece a este
  /// aeropuerto.
  Future<Aircraft?> findByRegistration(String registration) async {
    final rows = await _dbase.database.rawQuery(
      '$_baseQuery WHERE UPPER(registration) = ?',
      [registration.trim().toUpperCase()],
    );
    if (rows.isEmpty) return null;
    return Aircraft.fromMap(rows.first);
  }

  Future<bool> registrationExists(String registration, {int? excludeId}) async {
    final rows = await _dbase.database.query(
      'aircraft',
      columns: ['id'],
      where: excludeId == null
          ? 'UPPER(registration) = ?'
          : 'UPPER(registration) = ? AND id != ?',
      whereArgs: excludeId == null
          ? [registration.trim().toUpperCase()]
          : [registration.trim().toUpperCase(), excludeId],
    );
    return rows.isNotEmpty;
  }

  Future<int> insert(Aircraft aircraft) async {
    final Map<String, Object?> map = aircraft.toMap()..remove('id');
    return _dbase.database.insert('aircraft', map);
  }

  Future<void> update(Aircraft aircraft) async {
    await _dbase.database.update(
      'aircraft',
      aircraft.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [aircraft.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> delete(int id) async {
    await _dbase.database.delete('aircraft', where: 'id = ?', whereArgs: [id]);
  }
}
