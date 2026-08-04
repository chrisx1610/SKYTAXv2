import 'package:sqflite/sqflite.dart';

import '../database/skytax_database.dart';

/// Configuración del aeropuerto almacenada en la base de datos
/// (tasa aeroportuaria y secuencia de facturación).
///
/// La DOSA no vive aquí: sus importes salen de la tabla `dosa_tariffs`, por
/// modelo de aeronave y tramo de permanencia.
class SettingsRepository {
  SettingsRepository(this._dbase);

  final SkyTaxDatabase _dbase;

  static const String keyTaxRate = 'tax_rate';
  static const String keyInvoiceSeq = 'invoice_seq';

  Future<String?> get(String key) async {
    final rows = await _dbase.database
        .query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<double> getDouble(String key, double fallback) async {
    final String? raw = await get(key);
    return double.tryParse(raw ?? '') ?? fallback;
  }

  Future<void> set(String key, String value) async {
    await _dbase.database.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Reserva y devuelve el siguiente número de la secuencia de facturas de
  /// forma atómica.
  Future<int> nextInvoiceSequence() async {
    return _dbase.database.transaction((txn) async {
      final rows = await txn.query('settings',
          where: 'key = ?', whereArgs: [keyInvoiceSeq]);
      final int current =
          rows.isEmpty ? 1 : int.tryParse(rows.first['value'] as String) ?? 1;
      await txn.insert(
        'settings',
        {'key': keyInvoiceSeq, 'value': '${current + 1}'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return current;
    });
  }
}
