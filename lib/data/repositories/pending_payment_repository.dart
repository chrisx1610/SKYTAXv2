import 'package:sqflite/sqflite.dart';

import '../database/skytax_database.dart';
import '../models/models.dart';

/// Aeronaves que cargaron sus datos y eligieron pagar más tarde.
///
/// La matrícula es única: si la misma aeronave vuelve a diferir el pago, se
/// conserva el registro original para no reiniciar el conteo de permanencia.
class PendingPaymentRepository {
  PendingPaymentRepository(this._dbase);

  final SkyTaxDatabase _dbase;

  Future<List<PendingPayment>> getAll() async {
    final rows = await _dbase.database
        .query('pending_payments', orderBy: 'created_at');
    return rows.map(PendingPayment.fromMap).toList();
  }

  Future<PendingPayment?> findByRegistration(String registration) async {
    final rows = await _dbase.database.query(
      'pending_payments',
      where: 'registration = ? COLLATE NOCASE',
      whereArgs: [registration.trim().toUpperCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PendingPayment.fromMap(rows.first);
  }

  /// Registra la aeronave como pendiente. Si ya existía un registro para esa
  /// matrícula **no lo reemplaza**: el instante original debe conservarse
  /// porque es el que determina el tramo de la DOSA.
  Future<PendingPayment> upsert(PendingPayment pending) async {
    final PendingPayment? existing =
        await findByRegistration(pending.registration);
    if (existing != null) return existing;

    final Map<String, Object?> values = pending.toMap()..remove('id');
    final int id = await _dbase.database.insert(
      'pending_payments',
      values,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return PendingPayment(
      id: id,
      registration: pending.registration,
      model: pending.model,
      passengers: pending.passengers,
      createdAt: pending.createdAt,
    );
  }

  Future<void> deleteByRegistration(String registration) async {
    await _dbase.database.delete(
      'pending_payments',
      where: 'registration = ? COLLATE NOCASE',
      whereArgs: [registration.trim().toUpperCase()],
    );
  }
}
