import '../database/skytax_database.dart';
import '../models/models.dart';

/// Usuarios del sistema y autenticación.
class UserRepository {
  UserRepository(this._dbase);

  final SkyTaxDatabase _dbase;

  Future<List<AppUser>> getAll() async {
    final rows = await _dbase.database.query('users', orderBy: 'username');
    return rows.map(AppUser.fromMap).toList();
  }

  /// Devuelve el usuario si las credenciales son correctas; `null` si no.
  Future<AppUser?> authenticate(String username, String password) async {
    final rows = await _dbase.database.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username.trim(), SkyTaxDatabase.hashPassword(password)],
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<bool> usernameExists(String username, {int? excludeId}) async {
    final rows = await _dbase.database.query(
      'users',
      columns: ['id'],
      where: excludeId == null ? 'username = ?' : 'username = ? AND id != ?',
      whereArgs: excludeId == null
          ? [username.trim()]
          : [username.trim(), excludeId],
    );
    return rows.isNotEmpty;
  }

  Future<int> insert(AppUser user, String password) async {
    final Map<String, Object?> map = user.toMap()
      ..remove('id')
      ..['password_hash'] = SkyTaxDatabase.hashPassword(password);
    return _dbase.database.insert('users', map);
  }

  /// Actualiza el usuario; si [newPassword] es `null` conserva la contraseña.
  Future<void> update(AppUser user, {String? newPassword}) async {
    final Map<String, Object?> map = user.toMap()..remove('id');
    if (newPassword != null && newPassword.isNotEmpty) {
      map['password_hash'] = SkyTaxDatabase.hashPassword(newPassword);
    }
    await _dbase.database
        .update('users', map, where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> delete(int id) async {
    await _dbase.database.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
