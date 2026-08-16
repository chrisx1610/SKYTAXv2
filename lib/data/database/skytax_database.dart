import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/logging/app_logger.dart';

/// Acceso a la base de datos SQLite de SkyTax.
///
/// Cada aeropuerto tiene una base de datos independiente
/// (`skytax_<codigo>.db`) que almacena únicamente las aeronaves cuya base
/// operacional corresponde a ese aeropuerto, además de su configuración,
/// usuarios, facturas y auditoría.
class SkyTaxDatabase {
  SkyTaxDatabase({required this.dataDirectory});

  /// Directorio donde se guardan los archivos `.db`.
  final String dataDirectory;

  Database? _db;
  String? _openedCode;

  Database get database {
    final Database? db = _db;
    if (db == null) {
      throw StateError('La base de datos no ha sido abierta.');
    }
    return db;
  }

  static String hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  /// Abre (o crea) la base de datos del aeropuerto indicado.
  Future<Database> open(String airportCode) async {
    final String code = airportCode.trim().toUpperCase();
    if (_db != null && _openedCode == code) return _db!;
    await _db?.close();
    _db = null;

    await Directory(dataDirectory).create(recursive: true);
    final String path =
        p.join(dataDirectory, 'skytax_${code.toLowerCase()}.db');

    _db = await openDatabase(
      path,
      version: 8,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => _createSchema(db, code),
      onUpgrade: _upgrade,
    );
    _openedCode = code;
    AppLogger.instance.info('Base de datos abierta: $path');
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    _openedCode = null;
  }

  /// Migraciones entre versiones del esquema.
  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: el administrador inicial pasa de admin/admin123 a
      // Vincent/123456789. Solo se reemplaza si el usuario aún conserva
      // las credenciales de fábrica (no pisa cambios hechos desde el panel).
      await db.update(
        'users',
        {
          'username': 'Vincent',
          'password_hash': hashPassword('123456789'),
        },
        where: 'username = ? AND password_hash = ?',
        whereArgs: ['admin', hashPassword('admin123')],
      );
    }
    if (oldVersion < 3) {
      // v3: se elimina el concepto de operador aéreo. Las tablas se
      // reconstruyen sin sus columnas (SQLite anterior a 3.35 —presente en
      // Android 12 y anteriores— no soporta ALTER TABLE ... DROP COLUMN).
      await db.execute('''
        CREATE TABLE aircraft_v3(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          registration TEXT NOT NULL UNIQUE,
          model TEXT NOT NULL,
          capacity INTEGER
        )
      ''');
      await db.execute('''
        INSERT INTO aircraft_v3(id, registration, model, capacity)
        SELECT id, registration, model, capacity FROM aircraft
      ''');
      await db.execute('DROP TABLE aircraft');
      await db.execute('ALTER TABLE aircraft_v3 RENAME TO aircraft');

      await db.execute('''
        CREATE TABLE invoices_v3(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          number TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL,
          airport_code TEXT NOT NULL,
          airport_name TEXT NOT NULL,
          registration TEXT NOT NULL,
          aircraft_model TEXT NOT NULL,
          passengers INTEGER NOT NULL,
          tax_rate REAL NOT NULL,
          tax_subtotal REAL NOT NULL,
          dosa REAL NOT NULL,
          total REAL NOT NULL,
          payment_method TEXT NOT NULL,
          file_path TEXT NOT NULL,
          created_by TEXT NOT NULL
        )
      ''');
      await db.execute('''
        INSERT INTO invoices_v3(
          id, number, created_at, airport_code, airport_name, registration,
          aircraft_model, passengers, tax_rate, tax_subtotal, dosa, total,
          payment_method, file_path, created_by)
        SELECT
          id, number, created_at, airport_code, airport_name, registration,
          aircraft_model, passengers, tax_rate, tax_subtotal, dosa, total,
          payment_method, file_path, created_by
        FROM invoices
      ''');
      await db.execute('DROP TABLE invoices');
      await db.execute('ALTER TABLE invoices_v3 RENAME TO invoices');

      await db.execute('DROP TABLE IF EXISTS operators');
    }
    if (oldVersion < 4) {
      // v4: la DOSA deja de ser un importe único y pasa a definirse como una
      // tabla de tarifas por modelo de aeronave, escalonada por permanencia.
      await db.execute(_createDosaTariffsSql);
    }
    if (oldVersion < 5) {
      // v5: aeronaves que cargaron datos y eligieron pagar más tarde. La
      // permanencia se mide desde `created_at`.
      await db.execute(_createPendingPaymentsSql);
    }
    if (oldVersion < 6) {
      // v6: el usuario elige el tramo DOSA al pagar, así que la factura
      // guarda hasta cuándo queda cubierta la estadía. ADD COLUMN sí está
      // disponible en las versiones antiguas de SQLite (a diferencia de
      // DROP COLUMN), de modo que basta con ampliar la tabla.
      await db.execute('ALTER TABLE invoices ADD COLUMN valid_until TEXT');
    }
    // v7: la flota de ejemplo de SVMI dejó de sembrarse. No hay nada que
    // migrar —el esquema no cambió—, así que las bases anteriores conservan
    // las aeronaves que ya tuvieran; se dan de baja desde el panel.
    if (oldVersion < 8) {
      // v8: los infantes de 0 a 3 años quedan exentos de la tasa
      // aeroportuaria, así que la factura guarda cuántos viajaban. Las
      // emitidas hasta ahora no distinguían infantes: el valor por omisión
      // deja en cero y su subtotal sigue cuadrando.
      await db.execute(
        'ALTER TABLE invoices ADD COLUMN infants INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  /// Aeronaves con datos cargados que aún no han pagado.
  static const String _createPendingPaymentsSql = '''
    CREATE TABLE IF NOT EXISTS pending_payments(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      registration TEXT NOT NULL UNIQUE,
      model TEXT NOT NULL,
      passengers INTEGER NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';

  /// Tabla de tarifas DOSA por modelo (un importe por tramo de permanencia).
  static const String _createDosaTariffsSql = '''
    CREATE TABLE IF NOT EXISTS dosa_tariffs(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      model TEXT NOT NULL UNIQUE,
      up_to_2h REAL NOT NULL DEFAULT 0,
      one_day REAL NOT NULL DEFAULT 0,
      days_2_7 REAL NOT NULL DEFAULT 0,
      days_8_14 REAL NOT NULL DEFAULT 0,
      days_15_21 REAL NOT NULL DEFAULT 0,
      days_22_30 REAL NOT NULL DEFAULT 0
    )
  ''';

  Future<void> _createSchema(Database db, String airportCode) async {
    await db.execute('''
      CREATE TABLE aircraft(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        registration TEXT NOT NULL UNIQUE,
        model TEXT NOT NULL,
        capacity INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL,
        password_hash TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        airport_code TEXT NOT NULL,
        airport_name TEXT NOT NULL,
        registration TEXT NOT NULL,
        aircraft_model TEXT NOT NULL,
        passengers INTEGER NOT NULL,
        infants INTEGER NOT NULL DEFAULT 0,
        tax_rate REAL NOT NULL,
        tax_subtotal REAL NOT NULL,
        dosa REAL NOT NULL,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_by TEXT NOT NULL,
        valid_until TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute(_createDosaTariffsSql);
    await db.execute(_createPendingPaymentsSql);
    await db.execute('''
      CREATE TABLE audit_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        username TEXT NOT NULL,
        action TEXT NOT NULL,
        details TEXT NOT NULL,
        airport_code TEXT NOT NULL
      )
    ''');

    await _seed(db, airportCode);
  }

  /// Datos iniciales: configuración y usuario administrador.
  /// No se cargan aeronaves: la flota se da de alta desde el panel.
  Future<void> _seed(Database db, String airportCode) async {
    // La DOSA no se siembra: sus importes se cargan desde el panel en la
    // tabla `dosa_tariffs`, por modelo y tramo de permanencia.
    const Map<String, String> defaults = {
      'tax_rate': '15',
      'invoice_seq': '1',
    };
    for (final MapEntry<String, String> entry in defaults.entries) {
      await db.insert('settings', {'key': entry.key, 'value': entry.value});
    }

    await db.insert('users', {
      'username': 'Vincent',
      'full_name': 'Administrador del Sistema',
      'role': 'admin',
      'password_hash': hashPassword('123456789'),
    });

    // La flota no se siembra: cada aeropuerto carga sus propias aeronaves
    // desde el panel de administración. Una base recién creada arranca sin
    // ninguna, de modo que toda matrícula consultada se considera foránea
    // hasta que un administrador la registre.

    await db.insert('audit_log', {
      'created_at': DateTime.now().toIso8601String(),
      'username': 'sistema',
      'action': 'DB_CREATED',
      'details': 'Base de datos creada para el aeropuerto $airportCode',
      'airport_code': airportCode,
    });
  }
}
