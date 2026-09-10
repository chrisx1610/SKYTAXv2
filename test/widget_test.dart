import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tesis/core/i18n/app_strings.dart';
import 'package:tesis/core/theme/app_theme.dart';
import 'package:tesis/core/utils/formatters.dart';
import 'package:tesis/core/utils/input_formatters.dart';
import 'package:tesis/data/models/models.dart';
import 'package:tesis/domain/dosa_schedule.dart';
import 'package:tesis/domain/invoicing.dart';
import 'package:tesis/domain/tax_calculator.dart';
import 'package:tesis/presentation/widgets/bar_chart_card.dart';
import 'package:tesis/presentation/widgets/kiosk_widgets.dart';

void main() {
  const TaxCalculator calculator = TaxCalculator();
  const Aircraft localAircraft = Aircraft(
    id: 1,
    registration: 'YV1234',
    model: 'AC90',
  );

  group('TaxCalculator', () {
    test('Regla 1: aeronave local paga solo tasa × pasajeros', () {
      final TaxQuote quote = calculator.quote(
        registration: 'yv1234',
        typedModel: 'OTRO',
        passengers: 95,
        aircraft: localAircraft,
        taxRate: 15,
      );
      expect(quote.isLocal, isTrue);
      expect(quote.registration, 'YV1234');
      expect(quote.aircraftModel, 'AC90');
      expect(quote.taxSubtotal, 1425);
      expect(quote.dosa, 0);
      expect(quote.total, 1425);
    });

    test('Regla 2: aeronave foránea paga DOSA + tasa × pasajeros', () {
      final TaxQuote quote = calculator.quote(
        registration: 'YV9999',
        typedModel: 'B737',
        passengers: 95,
        aircraft: null,
        taxRate: 15,
        dosaTariff: const DosaTariff(model: 'B737', upTo2Hours: 120),
      );
      expect(quote.isLocal, isFalse);
      expect(quote.aircraftModel, 'B737');
      expect(quote.taxSubtotal, 1425);
      expect(quote.dosa, 120);
      expect(quote.total, 1545);
      expect(quote.missingTariff, isFalse);
    });

    test('aeronave foránea sin tarifa tabulada queda en cero y se advierte',
        () {
      final TaxQuote quote = calculator.quote(
        registration: 'YV9999',
        typedModel: 'MODELO-DESCONOCIDO',
        passengers: 95,
        aircraft: null,
        taxRate: 15,
      );
      expect(quote.dosa, 0);
      expect(quote.total, 1425);
      // La bandera permite avisar en pantalla en lugar de cobrar de menos
      // sin que nadie se entere.
      expect(quote.missingTariff, isTrue);
    });

    test('rechaza cantidades de pasajeros inválidas', () {
      expect(
        () => calculator.quote(
          registration: 'YV1',
          typedModel: 'X',
          passengers: 0,
          aircraft: null,
          taxRate: 15,
        ),
        throwsArgumentError,
      );
    });
  });

  group('exención de infantes', () {
    test('los infantes de 0 a 3 años no pagan la tasa aeroportuaria', () {
      final TaxQuote quote = calculator.quote(
        registration: 'YV1234',
        typedModel: 'OTRO',
        passengers: 95,
        infants: 5,
        aircraft: localAircraft,
        taxRate: 15,
      );
      expect(quote.passengers, 95);
      expect(quote.infants, 5);
      expect(quote.payingPassengers, 90);
      expect(quote.taxSubtotal, 1350);
      expect(quote.total, 1350);
    });

    test('la DOSA no depende de los infantes: se cobra por aeronave', () {
      final TaxQuote quote = calculator.quote(
        registration: 'YV9999',
        typedModel: 'B737',
        passengers: 100,
        infants: 10,
        aircraft: null,
        taxRate: 15,
        dosaTariff: const DosaTariff(model: 'B737', upTo2Hours: 120),
      );
      expect(quote.taxSubtotal, 1350);
      expect(quote.dosa, 120);
      expect(quote.total, 1470);
    });

    test('sin infantes declarados tributan todos los pasajeros', () {
      final TaxQuote quote = calculator.quote(
        registration: 'YV1234',
        typedModel: 'OTRO',
        passengers: 95,
        aircraft: localAircraft,
        taxRate: 15,
      );
      expect(quote.infants, 0);
      expect(quote.payingPassengers, 95);
      expect(quote.taxSubtotal, 1425);
    });

    test('rechaza más infantes que pasajeros a bordo', () {
      expect(
        () => calculator.quote(
          registration: 'YV1',
          typedModel: 'X',
          passengers: 3,
          infants: 4,
          aircraft: null,
          taxRate: 15,
        ),
        throwsArgumentError,
      );
    });

    test('el tramo elegido conserva la exención', () {
      final TaxQuote base = calculator.quote(
        registration: 'YV9999',
        typedModel: 'B737',
        passengers: 100,
        infants: 10,
        aircraft: null,
        taxRate: 15,
        dosaTariff: const DosaTariff(model: 'B737', upTo2Hours: 120),
      );
      final TaxQuote priced = calculator.withBracket(
        base,
        tariff: const DosaTariff(model: 'B737', oneDay: 200),
        bracket: DosaBracket.oneDay,
        paidAt: DateTime(2026, 1, 1, 10),
      );
      expect(priced.infants, 10);
      expect(priced.payingPassengers, 90);
      expect(priced.taxSubtotal, 1350);
      expect(priced.total, 1550);
    });
  });

  group('Formatters', () {
    test('número de factura con relleno de ceros', () {
      expect(Formatters.invoiceNumber(1), 'FACT-000001');
      expect(Formatters.invoiceNumber(123456), 'FACT-123456');
    });

    test('montos con separador de miles', () {
      expect(Formatters.money(1425), '€1,425');
      expect(Formatters.money(1545.5), '€1,545.5');
    });
  });

  group('buildInvoiceText', () {
    final Invoice invoice = Invoice(
      number: 'FACT-000001',
      createdAt: DateTime(2026, 7, 18, 14, 35),
      airportCode: 'SVMI',
      airportName: 'Maiquetía',
      registration: 'YV1234',
      aircraftModel: 'AC90',
      passengers: 95,
      taxRate: 15,
      taxSubtotal: 1425,
      dosa: 120,
      total: 1545,
      paymentMethod: Invoice.methodCard,
      filePath: '',
      createdBy: 'kiosco',
    );

    test('contiene todos los datos de la factura', () {
      final String text = buildInvoiceText(invoice, AppStrings.es);
      expect(text, contains('SKYTAX'));
      expect(text, contains('FACT-000001'));
      expect(text, contains('18/07/2026'));
      expect(text, contains('14:35'));
      expect(text, contains('SVMI - Maiquetía'));
      expect(text, contains('YV1234'));
      expect(text, contains('95 x €15'));
      expect(text, contains('€1,425'));
      expect(text, contains('€120'));
      expect(text, contains('€1,545'));
      expect(text, contains('TOTAL PAGADO'));
      expect(text, contains('Tarjeta'));
      expect(text, contains('Gracias por utilizar SkyTax'));
    });

    test('imprime hasta qué día y hora es válida la estadía', () {
      final Invoice conVigencia = Invoice(
        number: 'FACT-000003',
        createdAt: DateTime(2026, 8, 2, 14, 30),
        airportCode: 'SVMI',
        airportName: 'Maiquetía',
        registration: 'YV8888',
        aircraftModel: 'C172',
        passengers: 30,
        taxRate: 15,
        taxSubtotal: 450,
        dosa: 362.1,
        total: 812.1,
        paymentMethod: Invoice.methodCard,
        filePath: '',
        createdBy: 'kiosco',
        validUntil: DateTime(2026, 8, 16, 14, 30),
      );
      final String text = buildInvoiceText(conVigencia, AppStrings.es);
      expect(text, contains('Válida hasta'));
      expect(text, contains('16/08/2026 14:30'));
    });

    test('sin tramo elegido no imprime vigencia', () {
      final String text = buildInvoiceText(invoice, AppStrings.es);
      expect(text, isNot(contains('Válida hasta')));
    });

    test('omite la DOSA para aeronaves locales', () {
      final Invoice local = Invoice(
        number: 'FACT-000002',
        createdAt: DateTime(2026, 7, 18, 15, 0),
        airportCode: 'SVMI',
        airportName: 'Maiquetía',
        registration: 'YV1234',
        aircraftModel: 'AC90',
        passengers: 10,
        taxRate: 15,
        taxSubtotal: 150,
        dosa: 0,
        total: 150,
        paymentMethod: Invoice.methodMobile,
        filePath: '',
        createdBy: 'kiosco',
      );
      final String text = buildInvoiceText(local, AppStrings.es);
      expect(text, isNot(contains('DOSA')));
      expect(text, contains('Pago Móvil'));
    });
  });

  group('KioskActionBar', () {
    Widget harness(double width) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: KioskActionBar(
                  secondaryLabel: 'Ver factura',
                  secondaryIcon: Icons.receipt_long_rounded,
                  onSecondary: () {},
                  primaryLabel: 'Verificando pago...',
                  primaryIcon: Icons.check_rounded,
                  onPrimary: () {},
                ),
              ),
            ),
          ),
        );

    for (final double width in [320.0, 480.0, 800.0, 1280.0]) {
      testWidgets('sin desbordes ni texto partido a $width px', (tester) async {
        await tester.pumpWidget(harness(width));
        expect(tester.takeException(), isNull);

        // Ambas etiquetas presentes y limitadas a una sola línea.
        for (final String label in ['Ver factura', 'Verificando pago...']) {
          expect(find.text(label), findsOneWidget);
          final Text widget = tester.widget<Text>(find.text(label));
          expect(widget.maxLines, 1);
          expect(widget.softWrap, isFalse);
        }
      });
    }
  });

  group('dosaBracketFor', () {
    // Los límites son inclusivos por arriba: el instante exacto todavía
    // pertenece al tramo que termina.
    const List<(Duration, DosaBracket, String)> cases = [
      (Duration(minutes: 1), DosaBracket.upTo2Hours, 'recién llegada'),
      (Duration(hours: 2), DosaBracket.upTo2Hours, 'exactamente 2 horas'),
      (Duration(hours: 2, minutes: 1), DosaBracket.oneDay, 'pasadas 2 horas'),
      (Duration(days: 1), DosaBracket.oneDay, 'exactamente 1 día'),
      (Duration(days: 2), DosaBracket.days2To7, 'segundo día'),
      (Duration(days: 7), DosaBracket.days2To7, 'séptimo día'),
      (Duration(days: 8), DosaBracket.days8To14, 'octavo día'),
      (Duration(days: 14), DosaBracket.days8To14, 'día 14'),
      (Duration(days: 15), DosaBracket.days15To21, 'día 15'),
      (Duration(days: 21), DosaBracket.days15To21, 'día 21'),
      (Duration(days: 22), DosaBracket.days22To30, 'día 22'),
      (Duration(days: 30), DosaBracket.days22To30, 'día 30'),
      (Duration(days: 400), DosaBracket.days22To30, 'más de 30 días: tope'),
    ];

    for (final (Duration elapsed, DosaBracket expected, String label)
        in cases) {
      test('$label -> ${expected.name}', () {
        expect(dosaBracketFor(elapsed), expected);
      });
    }
  });

  group('dosaAmount', () {
    const DosaTariff tariff = DosaTariff(
      model: 'AC90',
      upTo2Hours: 15,
      oneDay: 45,
      days2To7: 200,
      days8To14: 350,
      days15To21: 500,
      days22To30: 650,
    );

    test('pagar en el momento cobra el tramo de hasta 2 horas', () {
      expect(dosaAmount(tariff: tariff, elapsed: Duration.zero), 15);
    });

    test('diez días acumulados cobran el tramo del 8.º al 14.º', () {
      expect(
        dosaAmount(tariff: tariff, elapsed: const Duration(days: 10)),
        350,
      );
    });

    test('modelo sin tarifa tabulada no genera importe', () {
      expect(
        dosaAmount(tariff: null, elapsed: const Duration(days: 10)),
        0,
      );
    });
  });

  group('TaxCalculator con tabla DOSA', () {
    const DosaTariff tariff = DosaTariff(
      model: 'B737',
      upTo2Hours: 15,
      oneDay: 45,
      days2To7: 200,
      days8To14: 350,
      days15To21: 500,
      days22To30: 650,
    );

    test('aeronave foránea que paga ahora usa el tramo de 2 horas', () {
      final TaxQuote quote = calculator.quote(
        registration: 'YV9999',
        typedModel: 'B737',
        passengers: 10,
        aircraft: null,
        taxRate: 15,
        dosaTariff: tariff,
      );
      expect(quote.dosa, 15);
      expect(quote.total, 165);
      expect(quote.dosaBracket, DosaBracket.upTo2Hours);
    });

    test('aeronave foránea con 9 días acumulados sube de tramo', () {
      final TaxQuote quote = calculator.quote(
        registration: 'YV9999',
        typedModel: 'B737',
        passengers: 10,
        aircraft: null,
        taxRate: 15,
        dosaTariff: tariff,
        elapsed: const Duration(days: 9),
      );
      expect(quote.dosa, 350);
      expect(quote.total, 500);
      expect(quote.dosaBracket, DosaBracket.days8To14);
    });

    test('aeronave local no paga DOSA aunque acumule días', () {
      final TaxQuote quote = calculator.quote(
        registration: 'YV1234',
        typedModel: 'AC90',
        passengers: 10,
        aircraft: localAircraft,
        taxRate: 15,
        dosaTariff: tariff,
        elapsed: const Duration(days: 20),
      );
      expect(quote.dosa, 0);
      expect(quote.total, 150);
      expect(quote.dosaBracket, isNull);
    });
  });

  group('vigencia del tramo elegido', () {
    final DateTime paidAt = DateTime(2026, 8, 2, 14, 30);

    test('cada tramo cubre hasta su tope, contado desde el pago', () {
      expect(dosaValidUntil(paidAt, DosaBracket.upTo2Hours),
          DateTime(2026, 8, 2, 16, 30));
      expect(dosaValidUntil(paidAt, DosaBracket.oneDay),
          DateTime(2026, 8, 3, 14, 30));
      expect(dosaValidUntil(paidAt, DosaBracket.days2To7),
          DateTime(2026, 8, 9, 14, 30));
      expect(dosaValidUntil(paidAt, DosaBracket.days8To14),
          DateTime(2026, 8, 16, 14, 30));
      expect(dosaValidUntil(paidAt, DosaBracket.days15To21),
          DateTime(2026, 8, 23, 14, 30));
      expect(dosaValidUntil(paidAt, DosaBracket.days22To30),
          DateTime(2026, 9, 1, 14, 30));
    });
  });

  group('TaxCalculator.withBracket', () {
    const DosaTariff tariff = DosaTariff(
      model: 'C172',
      upTo2Hours: 43.1,
      oneDay: 86.2,
      days2To7: 172.45,
      days8To14: 362.1,
      days15To21: 543.1,
      days22To30: 612.1,
    );
    final DateTime paidAt = DateTime(2026, 8, 2, 14, 30);

    TaxQuote base({bool local = false}) => calculator.quote(
          registration: 'YV8888',
          typedModel: 'C172',
          passengers: 30,
          aircraft: local ? localAircraft : null,
          taxRate: 15,
          dosaTariff: tariff,
        );

    test('el tramo elegido fija importe, total y vigencia', () {
      final TaxQuote q = calculator.withBracket(
        base(),
        tariff: tariff,
        bracket: DosaBracket.days8To14,
        paidAt: paidAt,
      );
      expect(q.dosa, 362.1);
      expect(q.taxSubtotal, 450);
      expect(q.total, 812.1);
      expect(q.dosaBracket, DosaBracket.days8To14);
      expect(q.validUntil, DateTime(2026, 8, 16, 14, 30));
    });

    test('elegir un tramo mayor cuesta más y cubre más tiempo', () {
      final TaxQuote corto = calculator.withBracket(base(),
          tariff: tariff, bracket: DosaBracket.upTo2Hours, paidAt: paidAt);
      final TaxQuote largo = calculator.withBracket(base(),
          tariff: tariff, bracket: DosaBracket.days22To30, paidAt: paidAt);
      expect(corto.dosa, lessThan(largo.dosa));
      expect(corto.validUntil!.isBefore(largo.validUntil!), isTrue);
    });

    test('la aeronave local no paga DOSA ni tiene vigencia', () {
      final TaxQuote q = calculator.withBracket(
        base(local: true),
        tariff: tariff,
        bracket: DosaBracket.days22To30,
        paidAt: paidAt,
      );
      expect(q.dosa, 0);
      expect(q.validUntil, isNull);
      expect(q.dosaBracket, isNull);
    });
  });

  group('PendingPayment', () {
    test('la permanencia se mide desde que se cargaron los datos', () {
      final PendingPayment pending = PendingPayment(
        registration: 'YV9999',
        model: 'B737',
        passengers: 10,
        createdAt: DateTime(2026, 7, 1, 10, 0),
      );
      expect(
        pending.elapsedUntil(DateTime(2026, 7, 9, 10, 0)),
        const Duration(days: 8),
      );
    });

    test('ida y vuelta a través del mapa de la base de datos', () {
      final PendingPayment original = PendingPayment(
        id: 3,
        registration: 'YV9999',
        model: 'Boeing 737-300',
        passengers: 140,
        createdAt: DateTime(2026, 7, 1, 10, 30),
      );
      final PendingPayment copy = PendingPayment.fromMap(original.toMap());
      expect(copy.registration, original.registration);
      expect(copy.passengers, original.passengers);
      expect(copy.createdAt, original.createdAt);
    });
  });

  group('Formatters.stay', () {
    test('minutos, horas y días', () {
      expect(Formatters.stay(const Duration(minutes: 45)), '45 min');
      expect(Formatters.stay(const Duration(hours: 2)), '2 h');
      expect(Formatters.stay(const Duration(hours: 2, minutes: 15)),
          '2 h 15 min');
      expect(Formatters.stay(const Duration(days: 3)), '3 d');
      expect(Formatters.stay(const Duration(days: 3, hours: 4)), '3 d 4 h');
    });
  });

  group('UpperCaseTextFormatter', () {
    // El modelo de aeronave se captura en tres sitios (kiosco, alta de
    // aeronave y tarifa DOSA); todos deben guardar en mayúsculas.
    final UpperCaseTextFormatter formatter = UpperCaseTextFormatter();

    TextEditingValue apply(String text) => formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );

    test('convierte el modelo a mayúsculas', () {
      expect(apply('ac90').text, 'AC90');
      expect(apply('Boeing 737-300').text, 'BOEING 737-300');
      expect(apply('embraer e190').text, 'EMBRAER E190');
    });

    test('conserva la posición del cursor', () {
      final TextEditingValue v = apply('ac90');
      expect(v.selection.baseOffset, 4);
    });
  });

  group('DosaTariff', () {
    test('los seis tramos se exponen en orden', () {
      const DosaTariff t = DosaTariff(
        model: 'AC90',
        upTo2Hours: 10,
        oneDay: 20,
        days2To7: 30,
        days8To14: 40,
        days15To21: 50,
        days22To30: 60,
      );
      expect(t.brackets, [10, 20, 30, 40, 50, 60]);
    });

    test('los tramos son cero por omisión', () {
      const DosaTariff t = DosaTariff(model: 'B737');
      expect(t.brackets, everyElement(0));
    });

    test('ida y vuelta a través del mapa de la base de datos', () {
      const DosaTariff original = DosaTariff(
        id: 7,
        model: 'Boeing 737-300',
        upTo2Hours: 12.5,
        oneDay: 40,
        days2To7: 180,
        days8To14: 320,
        days15To21: 460,
        days22To30: 600,
      );
      final DosaTariff copy = DosaTariff.fromMap(original.toMap());
      expect(copy.id, original.id);
      expect(copy.model, original.model);
      expect(copy.brackets, original.brackets);
    });
  });

  group('DosaTariffTable', () {
    const List<String> labels = [
      'Hasta 2 horas',
      '1 día',
      'Del 2.º al 7.º día',
      'Del 8.º al 14.º día',
      'Del 15.º al 21.º día',
      'Del 22.º al 30.º día',
    ];
    const List<DosaTariff> tariffs = [
      DosaTariff(
        id: 1,
        model: 'McDonnell Douglas MD-82',
        upTo2Hours: 15,
        oneDay: 45,
        days2To7: 200,
        days8To14: 350,
        days15To21: 500,
        days22To30: 650,
      ),
    ];

    Widget harness(double width) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: width,
                child: const DosaTariffTable(
                  tariffs: tariffs,
                  modelLabel: 'Modelo',
                  bracketLabels: labels,
                  editTooltip: 'Editar',
                  deleteTooltip: 'Eliminar',
                ),
              ),
            ),
          ),
        );

    for (final double width in [320.0, 480.0, 800.0, 1280.0]) {
      testWidgets('sin desbordes a $width px', (tester) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(harness(width));
        expect(tester.takeException(), isNull);

        // El modelo se muestra en ambas disposiciones (tabla y tarjetas).
        expect(find.text('McDonnell Douglas MD-82'), findsOneWidget);
      });
    }

    testWidgets('en pantalla ancha usa tabla; en angosta, tarjetas',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(1280));
      expect(find.byType(DataTable), findsOneWidget);

      await tester.pumpWidget(harness(480));
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsNothing);
      // Las seis etiquetas de tramo acompañan a cada importe.
      for (final String label in labels) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('AdminListCard', () {
    const String title = 'Vincent · Administrador del Sistema';
    const TextStyle titleStyle =
        TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

    Widget harness(double width) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: AdminListCard(
                  icon: Icons.shield_rounded,
                  title: title,
                  subtitle: 'Administrador',
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    /// Ancho de la palabra más larga del título con su mismo estilo.
    double longestWordWidth() {
      double widest = 0;
      for (final String word in title.split(' ')) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: word, style: titleStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        if (painter.width > widest) widest = painter.width;
      }
      return widest;
    }

    for (final double width in [320.0, 480.0, 800.0, 1280.0]) {
      testWidgets('sin palabras partidas a $width px', (tester) async {
        await tester.pumpWidget(harness(width));
        expect(tester.takeException(), isNull);

        expect(find.text(title), findsOneWidget);
        // Si la caja del título fuese más angosta que su palabra más larga,
        // el texto se rompería a mitad de palabra ("Administr / ador").
        expect(
          tester.getSize(find.text(title)).width,
          greaterThanOrEqualTo(longestWordWidth()),
        );
      });
    }
  });

  group('BigChoiceCard', () {
    // Los dos subtitulos reales de la pantalla de metodos de pago: uno ocupa
    // dos lineas y el otro una sola.
    const String longSublabel = 'Inserte o acerque la tarjeta al lector';
    const String shortSublabel = 'Numero de referencia';

    Widget harness(double width, {required bool row}) {
      final List<Widget> cards = [
        BigChoiceCard(
          icon: Icons.credit_card_rounded,
          label: 'Tarjeta',
          sublabel: longSublabel,
          onTap: () {},
        ),
        BigChoiceCard(
          icon: Icons.phone_android_rounded,
          label: 'Pago Movil',
          sublabel: shortSublabel,
          onTap: () {},
        ),
      ];
      return MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: row
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 24),
                          Expanded(child: cards[1]),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [cards[0], const SizedBox(height: 20), cards[1]],
                    ),
            ),
          ),
        ),
      );
    }

    for (final double width in [360.0, 480.0]) {
      testWidgets('apiladas miden igual a $width px', (tester) async {
        await tester.pumpWidget(harness(width, row: false));
        expect(tester.takeException(), isNull);

        // Un subtitulo mas largo no debe agrandar su tarjeta: el usuario ve
        // dos opciones equivalentes y deben verse equivalentes.
        final Size card = tester.getSize(find.text('Tarjeta'));
        final Size mobile = tester.getSize(find.text('Pago Movil'));
        expect(card.height, mobile.height);

        final Size boxA = tester.getSize(find.byType(BigChoiceCard).first);
        final Size boxB = tester.getSize(find.byType(BigChoiceCard).last);
        expect(boxA.width, boxB.width);
        expect(boxA.height, boxB.height);
      });
    }

    testWidgets('lado a lado miden igual a 800 px', (tester) async {
      await tester.pumpWidget(harness(800, row: true));
      expect(tester.takeException(), isNull);

      final Size boxA = tester.getSize(find.byType(BigChoiceCard).first);
      final Size boxB = tester.getSize(find.byType(BigChoiceCard).last);
      expect(boxA.width, boxB.width);
      expect(boxA.height, boxB.height);
    });
  });

  group('BarChartCard', () {
    List<BarDatum> series(int n) => [
          for (int i = 0; i < n; i++)
            BarDatum(
              axisLabel: '${i.toString().padLeft(2, '0')}h',
              // Un tramo de cada cinco sin actividad, para cubrir el hueco.
              value: i % 5 == 0 ? 0 : (i * 7 % 13).toDouble(),
              tooltip: '${i * 7 % 13}',
            ),
        ];

    Widget harness(double width, List<BarDatum> bars) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: BarChartCard(
                  title: 'Facturas emitidas',
                  bars: bars,
                  color: AppTheme.brandBright,
                  emptyLabel: 'No hay registros.',
                ),
              ),
            ),
          ),
        );

    for (final double width in [320.0, 480.0, 800.0, 1280.0]) {
      testWidgets('sin desbordes con 24 tramos a $width px', (tester) async {
        await tester.pumpWidget(harness(width, series(24)));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sin datos muestra el aviso en lugar de un eje vacío',
        (tester) async {
      final List<BarDatum> vacios = [
        for (int i = 0; i < 7; i++)
          BarDatum(axisLabel: 'd$i', value: 0, tooltip: '0'),
      ];
      await tester.pumpWidget(harness(600, vacios));
      expect(tester.takeException(), isNull);
      // Con todo en cero no hay escala posible: dibujar barras planas daría a
      // entender que hubo actividad mínima en vez de ninguna.
      expect(find.text('No hay registros.'), findsOneWidget);
    });

    testWidgets('la barra mayor lleva su valor escrito', (tester) async {
      await tester.pumpWidget(harness(800, series(24)));
      expect(tester.takeException(), isNull);
      final double maxValue =
          series(24).fold<double>(0, (a, b) => b.value > a ? b.value : a);
      // Solo una etiqueta de valor: la del máximo, que fija la escala.
      expect(find.text('${maxValue.toInt()}'), findsOneWidget);
    });
  });
}
