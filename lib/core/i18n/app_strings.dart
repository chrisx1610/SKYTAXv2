/// Textos de la interfaz en español e inglés.
///
/// Se usa una clase inmutable con dos instancias constantes ([es] y [en]);
/// las pantallas obtienen la instancia activa desde el estado global.
class AppStrings {
  const AppStrings({
    required this.localeCode,
    required this.appTagline,
    required this.continueLabel,
    required this.cancel,
    required this.back,
    required this.close,
    required this.save,
    required this.delete,
    required this.edit,
    required this.add,
    required this.confirm,
    required this.finish,
    required this.retry,
    required this.requiredField,
    required this.errorGeneric,
    required this.selectLanguage,
    required this.welcomeTouch,
    required this.consultTitle,
    required this.consultSubtitle,
    required this.registrationLabel,
    required this.aircraftTypeLabel,
    required this.passengersLabel,
    required this.consult,
    required this.history,
    required this.adminPanel,
    required this.enterRegistration,
    required this.enterAircraftType,
    required this.invalidPassengers,
    required this.summaryTitle,
    required this.registrationShort,
    required this.modelLabel,
    required this.passengersShort,
    required this.airportTaxLabel,
    required this.dosaLabel,
    required this.totalToPay,
    required this.localAircraftNote,
    required this.foreignAircraftNote,
    required this.paymentTitle,
    required this.methodCard,
    required this.methodMobile,
    required this.cardProcessingTitle,
    required this.insertCard,
    required this.stepValidating,
    required this.stepAuthorizing,
    required this.stepApproved,
    required this.mobileInstructions,
    required this.bankLabel,
    required this.phoneLabel,
    required this.rifLabel,
    required this.amountLabel,
    required this.referenceLabel,
    required this.referenceHint,
    required this.confirmPayment,
    required this.verifyingPayment,
    required this.invalidReference,
    required this.paymentReceived,
    required this.confirmationTitle,
    required this.invoiceNumberLabel,
    required this.dateLabel,
    required this.timeLabel,
    required this.paymentMethodLabel,
    required this.totalPaidLabel,
    required this.invoiceGenerated,
    required this.viewInvoice,
    required this.newOperation,
    required this.airportLabel,
    required this.subtotalLabel,
    required this.totalPaidUpper,
    required this.invoiceThanks,
    required this.historyTitle,
    required this.searchHint,
    required this.noInvoices,
    required this.openFolder,
    required this.fileMissing,
    required this.adminLoginTitle,
    required this.usernameLabel,
    required this.passwordLabel,
    required this.login,
    required this.logout,
    required this.invalidCredentials,
    required this.adminTitle,
    required this.sectionAircraft,
    required this.sectionUsers,
    required this.sectionSettings,
    required this.sectionHistory,
    required this.sectionReports,
    required this.newAircraft,
    required this.editAircraft,
    required this.modelField,
    required this.capacityField,
    required this.registrationExists,
    required this.newUser,
    required this.editUser,
    required this.singleAdminNote,
    required this.fullNameField,
    required this.roleAdmin,
    required this.passwordKeepHint,
    required this.usernameExists,
    required this.taxRateField,
    required this.validUntilLabel,
    required this.chooseBracketTitle,
    required this.chooseBracketSubtitle,
    required this.coversUntil,
    required this.sectionPending,
    required this.amountDueToday,
    required this.pendingCountTemplate,
    required this.missingTariffWarning,
    required this.payTimingTitle,
    required this.payNow,
    required this.payLater,
    required this.payLaterUnavailable,
    required this.paymentDeferred,
    required this.pendingSince,
    required this.stayLabel,
    required this.bracketLabel,
    required this.dosaTariffsTitle,
    required this.dosaTariffsNote,
    required this.newDosaTariff,
    required this.editDosaTariff,
    required this.addRow,
    required this.modelExists,
    required this.colUpTo2h,
    required this.colOneDay,
    required this.colDays2To7,
    required this.colDays8To14,
    required this.colDays15To21,
    required this.colDays22To30,
    required this.airportCodeField,
    required this.airportNameField,
    required this.settingsSaved,
    required this.invalidNumber,
    required this.airportChangedNote,
    required this.periodToday,
    required this.period7Days,
    required this.periodAll,
    required this.statInvoices,
    required this.statTotal,
    required this.statByMethod,
    required this.generateReport,
    required this.reportGenerated,
    required this.colDate,
    required this.colUser,
    required this.colAction,
    required this.colDetails,
    required this.noRecords,
    required this.deleteConfirmTemplate,
  });

  final String localeCode;

  // Generales
  final String appTagline;
  final String continueLabel;
  final String cancel;
  final String back;
  final String close;
  final String save;
  final String delete;
  final String edit;
  final String add;
  final String confirm;
  final String finish;
  final String retry;
  final String requiredField;
  final String errorGeneric;

  // Idioma
  final String selectLanguage;
  final String welcomeTouch;

  // Menú principal / consulta
  final String consultTitle;
  final String consultSubtitle;
  final String registrationLabel;
  final String aircraftTypeLabel;
  final String passengersLabel;
  final String consult;
  final String history;
  final String adminPanel;
  final String enterRegistration;
  final String enterAircraftType;
  final String invalidPassengers;

  // Resumen
  final String summaryTitle;
  final String registrationShort;
  final String modelLabel;
  final String passengersShort;
  final String airportTaxLabel;
  final String dosaLabel;
  final String totalToPay;
  final String localAircraftNote;
  final String foreignAircraftNote;

  // Pago
  final String paymentTitle;
  final String methodCard;
  final String methodMobile;
  final String cardProcessingTitle;
  final String insertCard;
  final String stepValidating;
  final String stepAuthorizing;
  final String stepApproved;
  final String mobileInstructions;
  final String bankLabel;
  final String phoneLabel;
  final String rifLabel;
  final String amountLabel;
  final String referenceLabel;
  final String referenceHint;
  final String confirmPayment;
  final String verifyingPayment;
  final String invalidReference;
  final String paymentReceived;

  // Confirmación
  final String confirmationTitle;
  final String invoiceNumberLabel;
  final String dateLabel;
  final String timeLabel;
  final String paymentMethodLabel;
  final String totalPaidLabel;
  final String invoiceGenerated;
  final String viewInvoice;
  final String newOperation;

  // Factura TXT
  final String airportLabel;
  final String subtotalLabel;
  final String totalPaidUpper;
  final String invoiceThanks;

  // Historial
  final String historyTitle;
  final String searchHint;
  final String noInvoices;
  final String openFolder;
  final String fileMissing;

  // Administración
  final String adminLoginTitle;
  final String usernameLabel;
  final String passwordLabel;
  final String login;
  final String logout;
  final String invalidCredentials;
  final String adminTitle;
  final String sectionAircraft;
  final String sectionUsers;
  final String sectionSettings;
  final String sectionHistory;
  final String sectionReports;
  final String newAircraft;
  final String editAircraft;
  final String modelField;
  final String capacityField;
  final String registrationExists;
  final String newUser;
  final String editUser;
  final String singleAdminNote;
  final String fullNameField;
  final String roleAdmin;
  final String passwordKeepHint;
  final String usernameExists;
  final String taxRateField;
  final String validUntilLabel;
  final String chooseBracketTitle;
  final String chooseBracketSubtitle;
  final String coversUntil;
  final String sectionPending;
  final String amountDueToday;
  final String pendingCountTemplate;
  final String missingTariffWarning;

  /// Resumen del listado de pendientes: «3 aeronaves pendientes».
  String pendingCount(int n) =>
      pendingCountTemplate.replaceFirst('%d', '$n');
  final String payTimingTitle;
  final String payNow;
  final String payLater;

  /// Motivo por el que no se puede volver a diferir: ya hay un pago pendiente.
  final String payLaterUnavailable;
  final String paymentDeferred;
  final String pendingSince;
  final String stayLabel;
  final String bracketLabel;
  final String dosaTariffsTitle;
  final String dosaTariffsNote;
  final String newDosaTariff;
  final String editDosaTariff;
  final String addRow;
  final String modelExists;
  final String colUpTo2h;
  final String colOneDay;
  final String colDays2To7;
  final String colDays8To14;
  final String colDays15To21;
  final String colDays22To30;
  final String airportCodeField;
  final String airportNameField;
  final String settingsSaved;
  final String invalidNumber;
  final String airportChangedNote;

  // Reportes
  final String periodToday;
  final String period7Days;
  final String periodAll;
  final String statInvoices;
  final String statTotal;
  final String statByMethod;
  final String generateReport;
  final String reportGenerated;

  // Auditoría
  final String colDate;
  final String colUser;
  final String colAction;
  final String colDetails;
  final String noRecords;

  final String deleteConfirmTemplate;

  String confirmDelete(String item) =>
      deleteConfirmTemplate.replaceFirst('%s', item);

  String paymentMethodName(String code) =>
      code == 'mobile' ? methodMobile : methodCard;

  /// Nombre del tramo de permanencia según su posición en la tabla DOSA
  /// (el mismo orden que `DosaTariff.brackets`).
  String bracketName(int index) => <String>[
        colUpTo2h,
        colOneDay,
        colDays2To7,
        colDays8To14,
        colDays15To21,
        colDays22To30,
      ][index];

  static const AppStrings es = AppStrings(
    localeCode: 'es',
    appTagline: 'Sistema de Pago de Impuestos Aeroportuarios',
    continueLabel: 'Continuar',
    cancel: 'Cancelar',
    back: 'Volver',
    close: 'Cerrar',
    save: 'Guardar',
    delete: 'Eliminar',
    edit: 'Editar',
    add: 'Agregar',
    confirm: 'Confirmar',
    finish: 'Finalizar',
    retry: 'Reintentar',
    requiredField: 'Campo obligatorio',
    errorGeneric: 'Ocurrió un error inesperado. Intente nuevamente.',
    selectLanguage: 'Seleccione el idioma',
    welcomeTouch: 'Bienvenido · Welcome',
    consultTitle: 'Datos de la aeronave',
    consultSubtitle:
        'Ingrese los datos del vuelo para calcular los impuestos de forma automática.',
    registrationLabel: 'Matrícula de la aeronave',
    aircraftTypeLabel: 'Tipo de aeronave',
    passengersLabel: 'Cantidad de pasajeros',
    consult: 'Siguiente',
    history: 'Historial',
    adminPanel: 'Panel administrativo',
    enterRegistration: 'Ingrese la matrícula de la aeronave',
    enterAircraftType: 'Ingrese el tipo de aeronave',
    invalidPassengers: 'Ingrese una cantidad de pasajeros válida',
    summaryTitle: 'Resumen',
    registrationShort: 'Matrícula',
    modelLabel: 'Modelo',
    passengersShort: 'Cantidad de pasajeros',
    airportTaxLabel: 'Tasa aeroportuaria',
    dosaLabel: 'DOSA',
    totalToPay: 'Total a pagar',
    localAircraftNote: 'Aeronave con base en este aeropuerto.',
    foreignAircraftNote:
        'Aeronave de otro aeropuerto. Se aplica DOSA automáticamente.',
    paymentTitle: 'Seleccione el método de pago',
    methodCard: 'Tarjeta',
    methodMobile: 'Pago Móvil',
    cardProcessingTitle: 'Pago con Tarjeta',
    insertCard: 'Inserte o acerque la tarjeta al lector',
    stepValidating: 'Validando tarjeta...',
    stepAuthorizing: 'Autorizando pago...',
    stepApproved: 'Pago aprobado',
    mobileInstructions:
        'Realice el pago móvil con los siguientes datos y luego ingrese el número de referencia de la operación.',
    bankLabel: 'Banco',
    phoneLabel: 'Teléfono',
    rifLabel: 'RIF',
    amountLabel: 'Monto',
    referenceLabel: 'Número de referencia',
    referenceHint: 'Ej: 00123456',
    confirmPayment: 'Confirmar pago',
    verifyingPayment: 'Verificando pago...',
    invalidReference:
        'Ingrese un número de referencia válido (mínimo 6 dígitos)',
    paymentReceived: 'Pago recibido correctamente.',
    confirmationTitle: 'Confirmación',
    invoiceNumberLabel: 'Número de factura',
    dateLabel: 'Fecha',
    timeLabel: 'Hora',
    paymentMethodLabel: 'Método de pago',
    totalPaidLabel: 'Total cancelado',
    invoiceGenerated: 'Factura generada correctamente.',
    viewInvoice: 'Ver factura',
    newOperation: 'Finalizar',
    airportLabel: 'Aeropuerto',
    subtotalLabel: 'Subtotal',
    totalPaidUpper: 'TOTAL PAGADO',
    invoiceThanks: 'Gracias por utilizar SkyTax',
    historyTitle: 'Historial de facturas',
    searchHint: 'Buscar por matrícula o número de factura',
    noInvoices: 'No hay facturas registradas.',
    openFolder: 'Abrir carpeta',
    fileMissing: 'El archivo de la factura no se encontró en el disco.',
    adminLoginTitle: 'Acceso administrativo',
    usernameLabel: 'Usuario',
    passwordLabel: 'Contraseña',
    login: 'Ingresar',
    logout: 'Cerrar sesión',
    invalidCredentials: 'Usuario o contraseña incorrectos',
    adminTitle: 'Panel administrativo',
    sectionAircraft: 'Aeronaves',
    sectionUsers: 'Usuarios',
    sectionSettings: 'Configuración',
    sectionHistory: 'Historial',
    sectionReports: 'Reportes',
    newAircraft: 'Nueva aeronave',
    editAircraft: 'Editar aeronave',
    modelField: 'Modelo / Tipo',
    capacityField: 'Capacidad (opcional)',
    registrationExists: 'Ya existe una aeronave con esa matrícula',
    newUser: 'Nuevo usuario',
    editUser: 'Editar usuario',
    singleAdminNote:
        'El sistema utiliza un único usuario administrador. Aquí puede cambiar su nombre y su contraseña.',
    fullNameField: 'Nombre completo',
    roleAdmin: 'Administrador',
    passwordKeepHint: 'Dejar en blanco para mantener la contraseña actual',
    usernameExists: 'Ya existe un usuario con ese nombre',
    taxRateField: 'Tasa aeroportuaria (EUR por pasajero)',
    validUntilLabel: 'Válida hasta',
    chooseBracketTitle: 'Seleccione la tarifa',
    chooseBracketSubtitle:
        'Elija el tiempo que la aeronave permanecerá en el aeropuerto. La factura indicará hasta qué día y hora queda cubierta.',
    coversUntil: 'Cubre hasta',
    sectionPending: 'Pendientes',
    amountDueToday: 'A pagar hoy',
    pendingCountTemplate: '%d aeronave(s) pendiente(s) de pago',
    missingTariffWarning:
        'Este modelo no tiene tarifa DOSA registrada. Cárguela en Configuración para poder cobrarla.',
    payTimingTitle: '¿Desea pagar ahora?',
    payNow: 'Pagar ahora',
    payLater: 'Pagar más tarde',
    payLaterUnavailable: 'Ya tiene un pago pendiente',
    paymentDeferred: 'Aeronave registrada como pendiente de pago',
    pendingSince: 'Pendiente desde',
    stayLabel: 'Permanencia',
    bracketLabel: 'Tramo aplicado',
    dosaTariffsTitle: 'Tarifas DOSA por modelo',
    dosaTariffsNote:
        'Defina una fila por tipo de aeronave y el importe en EUR de cada tramo de permanencia.',
    newDosaTariff: 'Nueva tarifa',
    editDosaTariff: 'Editar tarifa',
    addRow: 'Agregar fila',
    modelExists: 'Ya existe una tarifa para ese modelo',
    colUpTo2h: 'Hasta 2 horas',
    colOneDay: '1 día',
    colDays2To7: 'Del 2.º al 7.º día',
    colDays8To14: 'Del 8.º al 14.º día',
    colDays15To21: 'Del 15.º al 21.º día',
    colDays22To30: 'Del 22.º al 30.º día',
    airportCodeField: 'Código OACI del aeropuerto',
    airportNameField: 'Nombre del aeropuerto',
    settingsSaved: 'Configuración guardada correctamente',
    invalidNumber: 'Ingrese un valor numérico válido',
    airportChangedNote:
        'Cada aeropuerto usa su propia base de datos. Al cambiar el código se abrirá (o creará) la base de datos de ese aeropuerto.',
    periodToday: 'Hoy',
    period7Days: 'Últimos 7 días',
    periodAll: 'Todo',
    statInvoices: 'Facturas emitidas',
    statTotal: 'Total recaudado',
    statByMethod: 'Por método de pago',
    generateReport: 'Generar reporte TXT',
    reportGenerated: 'Reporte generado:',
    colDate: 'Fecha',
    colUser: 'Usuario',
    colAction: 'Acción',
    colDetails: 'Detalle',
    noRecords: 'No hay registros.',
    deleteConfirmTemplate: '¿Desea eliminar "%s"? Esta acción no se puede deshacer.',
  );

  static const AppStrings en = AppStrings(
    localeCode: 'en',
    appTagline: 'Airport Tax Payment System',
    continueLabel: 'Continue',
    cancel: 'Cancel',
    back: 'Back',
    close: 'Close',
    save: 'Save',
    delete: 'Delete',
    edit: 'Edit',
    add: 'Add',
    confirm: 'Confirm',
    finish: 'Finish',
    retry: 'Retry',
    requiredField: 'Required field',
    errorGeneric: 'An unexpected error occurred. Please try again.',
    selectLanguage: 'Select your language',
    welcomeTouch: 'Bienvenido · Welcome',
    consultTitle: 'Aircraft details',
    consultSubtitle:
        'Enter the flight details to calculate the taxes automatically.',
    registrationLabel: 'Aircraft registration',
    aircraftTypeLabel: 'Aircraft type',
    passengersLabel: 'Number of passengers',
    consult: 'Next',
    history: 'History',
    adminPanel: 'Admin panel',
    enterRegistration: 'Enter the aircraft registration',
    enterAircraftType: 'Enter the aircraft type',
    invalidPassengers: 'Enter a valid number of passengers',
    summaryTitle: 'Summary',
    registrationShort: 'Registration',
    modelLabel: 'Model',
    passengersShort: 'Passengers',
    airportTaxLabel: 'Airport tax',
    dosaLabel: 'DOSA',
    totalToPay: 'Total to pay',
    localAircraftNote: 'Aircraft based at this airport.',
    foreignAircraftNote:
        'Aircraft from another airport. DOSA is applied automatically.',
    paymentTitle: 'Select the payment method',
    methodCard: 'Card',
    methodMobile: 'Mobile Payment',
    cardProcessingTitle: 'Card Payment',
    insertCard: 'Insert or tap your card on the reader',
    stepValidating: 'Validating card...',
    stepAuthorizing: 'Authorizing payment...',
    stepApproved: 'Payment approved',
    mobileInstructions:
        'Make the mobile payment using the following details, then enter the transaction reference number.',
    bankLabel: 'Bank',
    phoneLabel: 'Phone',
    rifLabel: 'Tax ID (RIF)',
    amountLabel: 'Amount',
    referenceLabel: 'Reference number',
    referenceHint: 'E.g. 00123456',
    confirmPayment: 'Confirm payment',
    verifyingPayment: 'Verifying payment...',
    invalidReference: 'Enter a valid reference number (at least 6 digits)',
    paymentReceived: 'Payment received successfully.',
    confirmationTitle: 'Confirmation',
    invoiceNumberLabel: 'Invoice number',
    dateLabel: 'Date',
    timeLabel: 'Time',
    paymentMethodLabel: 'Payment method',
    totalPaidLabel: 'Total paid',
    invoiceGenerated: 'Invoice generated successfully.',
    viewInvoice: 'View invoice',
    newOperation: 'Finish',
    airportLabel: 'Airport',
    subtotalLabel: 'Subtotal',
    totalPaidUpper: 'TOTAL PAID',
    invoiceThanks: 'Thank you for using SkyTax',
    historyTitle: 'Invoice history',
    searchHint: 'Search by registration or invoice number',
    noInvoices: 'No invoices recorded.',
    openFolder: 'Open folder',
    fileMissing: 'The invoice file was not found on disk.',
    adminLoginTitle: 'Admin access',
    usernameLabel: 'Username',
    passwordLabel: 'Password',
    login: 'Sign in',
    logout: 'Sign out',
    invalidCredentials: 'Incorrect username or password',
    adminTitle: 'Admin panel',
    sectionAircraft: 'Aircraft',
    sectionUsers: 'Users',
    sectionSettings: 'Settings',
    sectionHistory: 'History',
    sectionReports: 'Reports',
    newAircraft: 'New aircraft',
    editAircraft: 'Edit aircraft',
    modelField: 'Model / Type',
    capacityField: 'Capacity (optional)',
    registrationExists: 'An aircraft with that registration already exists',
    newUser: 'New user',
    editUser: 'Edit user',
    singleAdminNote:
        'The system uses a single administrator account. Here you can change its name and password.',
    fullNameField: 'Full name',
    roleAdmin: 'Administrator',
    passwordKeepHint: 'Leave blank to keep the current password',
    usernameExists: 'A user with that username already exists',
    taxRateField: 'Airport tax (EUR per passenger)',
    validUntilLabel: 'Valid until',
    chooseBracketTitle: 'Select the rate',
    chooseBracketSubtitle:
        'Choose how long the aircraft will stay at the airport. The invoice will state the day and time it is covered until.',
    coversUntil: 'Covers until',
    sectionPending: 'Pending',
    amountDueToday: 'Due today',
    pendingCountTemplate: '%d aircraft pending payment',
    missingTariffWarning:
        'This model has no DOSA tariff on file. Add it under Settings so it can be charged.',
    payTimingTitle: 'Do you want to pay now?',
    payNow: 'Pay now',
    payLater: 'Pay later',
    payLaterUnavailable: 'Payment already pending',
    paymentDeferred: 'Aircraft recorded as pending payment',
    pendingSince: 'Pending since',
    stayLabel: 'Length of stay',
    bracketLabel: 'Applied bracket',
    dosaTariffsTitle: 'DOSA tariffs by model',
    dosaTariffsNote:
        'Define one row per aircraft type and the EUR amount for each length-of-stay bracket.',
    newDosaTariff: 'New tariff',
    editDosaTariff: 'Edit tariff',
    addRow: 'Add row',
    modelExists: 'A tariff for that model already exists',
    colUpTo2h: 'Up to 2 hours',
    colOneDay: '1 day',
    colDays2To7: 'Day 2 to 7',
    colDays8To14: 'Day 8 to 14',
    colDays15To21: 'Day 15 to 21',
    colDays22To30: 'Day 22 to 30',
    airportCodeField: 'Airport ICAO code',
    airportNameField: 'Airport name',
    settingsSaved: 'Settings saved successfully',
    invalidNumber: 'Enter a valid numeric value',
    airportChangedNote:
        'Each airport uses its own database. Changing the code will open (or create) that airport\'s database.',
    periodToday: 'Today',
    period7Days: 'Last 7 days',
    periodAll: 'All time',
    statInvoices: 'Invoices issued',
    statTotal: 'Total collected',
    statByMethod: 'By payment method',
    generateReport: 'Generate TXT report',
    reportGenerated: 'Report generated:',
    colDate: 'Date',
    colUser: 'User',
    colAction: 'Action',
    colDetails: 'Details',
    noRecords: 'No records.',
    deleteConfirmTemplate: 'Delete "%s"? This action cannot be undone.',
  );
}
