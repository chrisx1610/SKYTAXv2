/// Modelos de datos de SkyTax.
library;

/// Aeronave registrada en la base de datos del aeropuerto.
class Aircraft {
  const Aircraft({
    this.id,
    required this.registration,
    required this.model,
    this.capacity,
  });

  final int? id;
  final String registration;
  final String model;
  final int? capacity;

  factory Aircraft.fromMap(Map<String, Object?> map) => Aircraft(
        id: map['id'] as int?,
        registration: map['registration'] as String,
        model: map['model'] as String,
        capacity: map['capacity'] as int?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'registration': registration,
        'model': model,
        'capacity': capacity,
      };
}

/// Tarifa DOSA de un modelo de aeronave, escalonada por tiempo de permanencia.
///
/// El administrador define una fila por tipo de aeronave y un importe para
/// cada uno de los seis tramos de estadía contemplados por la norma.
class DosaTariff {
  const DosaTariff({
    this.id,
    required this.model,
    this.upTo2Hours = 0,
    this.oneDay = 0,
    this.days2To7 = 0,
    this.days8To14 = 0,
    this.days15To21 = 0,
    this.days22To30 = 0,
  });

  final int? id;
  final String model;

  /// Tarifa hasta 2 horas de permanencia.
  final double upTo2Hours;

  /// Tarifa de 1 día.
  final double oneDay;

  /// Tarifa del 2.º al 7.º día.
  final double days2To7;

  /// Tarifa del 8.º al 14.º día.
  final double days8To14;

  /// Tarifa del 15.º al 21.º día.
  final double days15To21;

  /// Tarifa del 22.º al 30.º día.
  final double days22To30;

  /// Los seis importes en el orden en que se muestran en la tabla.
  List<double> get brackets => <double>[
        upTo2Hours,
        oneDay,
        days2To7,
        days8To14,
        days15To21,
        days22To30,
      ];

  factory DosaTariff.fromMap(Map<String, Object?> map) => DosaTariff(
        id: map['id'] as int?,
        model: map['model'] as String,
        upTo2Hours: (map['up_to_2h'] as num).toDouble(),
        oneDay: (map['one_day'] as num).toDouble(),
        days2To7: (map['days_2_7'] as num).toDouble(),
        days8To14: (map['days_8_14'] as num).toDouble(),
        days15To21: (map['days_15_21'] as num).toDouble(),
        days22To30: (map['days_22_30'] as num).toDouble(),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'model': model,
        'up_to_2h': upTo2Hours,
        'one_day': oneDay,
        'days_2_7': days2To7,
        'days_8_14': days8To14,
        'days_15_21': days15To21,
        'days_22_30': days22To30,
      };
}

/// Aeronave que cargó sus datos pero decidió pagar más tarde.
///
/// [createdAt] es el instante en que se registraron los datos: de ahí se
/// calcula la permanencia que determina el tramo de la DOSA cuando el usuario
/// regresa a pagar.
class PendingPayment {
  const PendingPayment({
    this.id,
    required this.registration,
    required this.model,
    required this.passengers,
    required this.createdAt,
  });

  final int? id;
  final String registration;
  final String model;
  final int passengers;
  final DateTime createdAt;

  /// Tiempo transcurrido desde que se cargaron los datos.
  Duration elapsedUntil(DateTime now) => now.difference(createdAt);

  factory PendingPayment.fromMap(Map<String, Object?> map) => PendingPayment(
        id: map['id'] as int?,
        registration: map['registration'] as String,
        model: map['model'] as String,
        passengers: map['passengers'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'registration': registration,
        'model': model,
        'passengers': passengers,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Usuario del sistema (administrador u operador de kiosco).
class AppUser {
  const AppUser({
    this.id,
    required this.username,
    required this.fullName,
    required this.role,
  });

  static const String roleAdmin = 'admin';
  static const String roleOperator = 'operator';

  final int? id;
  final String username;
  final String fullName;
  final String role;

  bool get isAdmin => role == roleAdmin;

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
        id: map['id'] as int?,
        username: map['username'] as String,
        fullName: map['full_name'] as String,
        role: map['role'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'role': role,
      };
}

/// Factura emitida por el sistema.
class Invoice {
  const Invoice({
    this.id,
    required this.number,
    required this.createdAt,
    required this.airportCode,
    required this.airportName,
    required this.registration,
    required this.aircraftModel,
    required this.passengers,
    required this.taxRate,
    required this.taxSubtotal,
    required this.dosa,
    required this.total,
    required this.paymentMethod,
    required this.filePath,
    required this.createdBy,
    this.validUntil,
  });

  static const String methodCard = 'card';
  static const String methodMobile = 'mobile';

  final int? id;
  final String number;
  final DateTime createdAt;
  final String airportCode;
  final String airportName;
  final String registration;
  final String aircraftModel;
  final int passengers;
  final double taxRate;
  final double taxSubtotal;
  final double dosa;
  final double total;
  final String paymentMethod;
  final String filePath;
  final String createdBy;

  /// Fecha y hora hasta la que la estadía pagada queda cubierta, según el
  /// tramo DOSA que eligió el usuario. `null` en aeronaves locales, que no
  /// pagan DOSA y por tanto no tienen vigencia asociada.
  final DateTime? validUntil;

  bool get hasDosa => dosa > 0;

  factory Invoice.fromMap(Map<String, Object?> map) => Invoice(
        id: map['id'] as int?,
        number: map['number'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        airportCode: map['airport_code'] as String,
        airportName: map['airport_name'] as String,
        registration: map['registration'] as String,
        aircraftModel: map['aircraft_model'] as String,
        passengers: map['passengers'] as int,
        taxRate: (map['tax_rate'] as num).toDouble(),
        taxSubtotal: (map['tax_subtotal'] as num).toDouble(),
        dosa: (map['dosa'] as num).toDouble(),
        total: (map['total'] as num).toDouble(),
        paymentMethod: map['payment_method'] as String,
        filePath: map['file_path'] as String,
        createdBy: map['created_by'] as String,
        validUntil: map['valid_until'] == null
            ? null
            : DateTime.parse(map['valid_until'] as String),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'number': number,
        'created_at': createdAt.toIso8601String(),
        'airport_code': airportCode,
        'airport_name': airportName,
        'registration': registration,
        'aircraft_model': aircraftModel,
        'passengers': passengers,
        'tax_rate': taxRate,
        'tax_subtotal': taxSubtotal,
        'dosa': dosa,
        'total': total,
        'payment_method': paymentMethod,
        'file_path': filePath,
        'created_by': createdBy,
        'valid_until': validUntil?.toIso8601String(),
      };

  Invoice copyWith({int? id, String? filePath}) => Invoice(
        id: id ?? this.id,
        number: number,
        createdAt: createdAt,
        airportCode: airportCode,
        airportName: airportName,
        registration: registration,
        aircraftModel: aircraftModel,
        passengers: passengers,
        taxRate: taxRate,
        taxSubtotal: taxSubtotal,
        dosa: dosa,
        total: total,
        paymentMethod: paymentMethod,
        filePath: filePath ?? this.filePath,
        createdBy: createdBy,
        validUntil: validUntil,
      );
}

/// Registro de auditoría: quién hizo qué, cuándo y desde qué aeropuerto.
class AuditEntry {
  const AuditEntry({
    this.id,
    required this.createdAt,
    required this.username,
    required this.action,
    required this.details,
    required this.airportCode,
  });

  final int? id;
  final DateTime createdAt;
  final String username;
  final String action;
  final String details;
  final String airportCode;

  factory AuditEntry.fromMap(Map<String, Object?> map) => AuditEntry(
        id: map['id'] as int?,
        createdAt: DateTime.parse(map['created_at'] as String),
        username: map['username'] as String,
        action: map['action'] as String,
        details: map['details'] as String,
        airportCode: map['airport_code'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'username': username,
        'action': action,
        'details': details,
        'airport_code': airportCode,
      };
}
