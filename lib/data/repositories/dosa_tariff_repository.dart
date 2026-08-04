import '../database/skytax_database.dart';
import '../models/models.dart';

/// Tabla de tarifas DOSA por modelo de aeronave.
///
/// Cada fila define los importes de los seis tramos de permanencia que el
/// administrador mantiene desde el panel de configuración.
class DosaTariffRepository {
  DosaTariffRepository(this._dbase);

  final SkyTaxDatabase _dbase;

  Future<List<DosaTariff>> getAll() async {
    final rows = await _dbase.database.query('dosa_tariffs', orderBy: 'model');
    return rows.map(DosaTariff.fromMap).toList();
  }

  Future<int> insert(DosaTariff tariff) async {
    final Map<String, Object?> values = tariff.toMap()..remove('id');
    return _dbase.database.insert('dosa_tariffs', values);
  }

  Future<void> update(DosaTariff tariff) async {
    await _dbase.database.update(
      'dosa_tariffs',
      tariff.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [tariff.id],
    );
  }

  Future<void> delete(int id) async {
    await _dbase.database
        .delete('dosa_tariffs', where: 'id = ?', whereArgs: [id]);
  }

  /// `true` si ya hay una tarifa para ese modelo (comparación sin distinguir
  /// mayúsculas), excluyendo opcionalmente la fila que se está editando.
  Future<bool> modelExists(String model, {int? excludeId}) async {
    final rows = await _dbase.database.query(
      'dosa_tariffs',
      where: excludeId == null
          ? 'model = ? COLLATE NOCASE'
          : 'model = ? COLLATE NOCASE AND id <> ?',
      whereArgs:
          excludeId == null ? [model.trim()] : [model.trim(), excludeId],
    );
    return rows.isNotEmpty;
  }
}
