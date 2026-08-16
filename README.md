# SkyTax

Sistema digital para el cálculo y pago de impuestos aeroportuarios en Venezuela.
Aplicación de kiosco táctil multiplataforma (tablet Android / escritorio Windows)
desarrollada en Flutter con una única base de código.

El sistema funciona **completamente sin conexión**: toda la información vive en
una base de datos SQLite local en el propio terminal, sin servidor ni API.

---

## Funcionalidades

### Flujo del pasajero

1. **Selección de idioma** — Español / English, al estilo de un kiosco de autoservicio.
2. **Datos del vuelo** — matrícula, tipo de aeronave, cantidad de pasajeros y,
   opcionalmente, cuántos infantes viajan.
3. **Momento del pago** — pagar ahora o diferir el pago.
4. **Tramo de permanencia** — solo para quien paga en el momento (ver DOSA).
5. **Resumen** con el desglose completo antes de cobrar.
6. **Método de pago** — tarjeta o pago móvil.
7. **Confirmación** y emisión de la factura.

### Cálculo de impuestos

El operador nunca selecciona impuestos: el sistema los determina solo.

| Situación | Tasa aeroportuaria | DOSA |
|---|---|---|
| Matrícula registrada en el aeropuerto (**local**) | Sí | No |
| Matrícula no registrada (**foránea**) | Sí | Sí |

- **Tasa aeroportuaria** = `tasa × pasajeros que tributan`, configurable desde el panel.
- **DOSA** — se cobra por aeronave, no por pasajero. El importe sale de la tabla
  de tarifas del modelo, escalonada en seis tramos de permanencia:
  hasta 2 horas · 1 día · 2.º al 7.º · 8.º al 14.º · 15.º al 21.º · 22.º al 30.º día.
- **Exención de infantes** — los pasajeros de 0 a 3 años no pagan la tasa
  aeroportuaria. Se declaran aparte y se restan del cálculo; la DOSA no se altera,
  porque no depende de la cantidad de pasajeros.
- Si el modelo de una aeronave foránea no tiene tarifa cargada, el importe queda
  en cero y la interfaz **lo advierte** en lugar de cobrar de menos en silencio.

### Pago diferido

Una aeronave puede cargar sus datos y postergar el pago. Desde ese momento
empieza a correr su permanencia, y el tramo DOSA que se le cobrará al regresar lo
determina el tiempo transcurrido, no una elección del usuario.

Tres reglas protegen el cobro:

- Al volver, el tramo **ya está determinado** por la permanencia: se va directo al
  resumen, sin pantalla de selección de tarifa.
- El **tipo de aeronave queda bloqueado** con el valor registrado, para que no se
  pueda declarar un modelo de tarifa más barata al momento de pagar.
- **«Pagar más tarde» se deshabilita**: la deuda solo se cierra pagando, y diferir
  otra vez no reinicia el reloj.

### Facturación y reportes

- **Factura `.txt`** en `Documentos/SkyTax/Facturas/`, con numeración correlativa
  `FACT-000001`, `FACT-000002`… Incluye el desglose, los infantes exentos, el
  tramo aplicado y hasta cuándo queda cubierta la estadía.
- **Historial** de facturas con búsqueda y visor del archivo.
- **Reportes** por período —hoy, últimos 7 días o histórico completo— en
  `Documentos/SkyTax/Reportes/REPORTE-<fecha>.txt`, con la cantidad de facturas,
  el total recaudado y el desglose por método de pago.

### Panel administrativo

Usuario inicial **`Vincent`** / **`123456789`**.

| Sección | Contenido |
|---|---|
| Aeronaves | Flota del aeropuerto (matrícula, modelo, capacidad) |
| Usuarios | Altas y credenciales del personal |
| Pendientes | Aeronaves con pago diferido, su permanencia y lo que adeudan |
| Configuración | Tasa por pasajero, tabla de tarifas DOSA y aeropuerto del terminal |
| Historial | Facturas emitidas |
| Reportes | Generación de reportes por período |

### Trazabilidad

- **Auditoría** de cada operación: usuario, acción, fecha/hora y aeropuerto.
- **Logging** a `skytax.log` en el directorio de datos de la aplicación.

---

## Arquitectura

Cuatro capas, con la lógica de negocio aislada de Flutter y de la base de datos.

```
lib/
├── core/                       # Infraestructura transversal
│   ├── theme/                  #   Material 3, azul #1E40AF, IBM Plex Sans
│   ├── i18n/                   #   Textos ES/EN en una sola clase tipada
│   ├── utils/                  #   Formateadores y filtros de entrada
│   ├── app_paths.dart          #   Rutas por plataforma
│   └── logging/                #   Registro a archivo
│
├── domain/                     # Reglas de negocio puras, sin dependencias de UI
│   ├── tax_calculator.dart     #   Cálculo de impuestos y exenciones
│   ├── dosa_schedule.dart      #   Tramos de permanencia y vigencias
│   ├── invoicing.dart          #   Puerto InvoiceOutput + implementación TXT
│   └── payment_simulator.dart  #   Pasarela de pago simulada
│
├── data/                       # Persistencia
│   ├── models/                 #   Entidades y mapeo a/desde SQLite
│   ├── database/               #   Esquema, migraciones y apertura
│   └── repositories/           #   Un repositorio por entidad
│
└── presentation/               # Interfaz
    ├── state/                  #   AppController (Provider)
    ├── screens/                #   Pantallas del kiosco y del panel admin
    └── widgets/                #   Componentes táctiles reutilizables
```

### Decisiones de diseño

**Una base de datos por aeropuerto.** Cada terminal abre `skytax_<código>.db` y
solo contiene las aeronaves con base operacional en ese aeropuerto, junto con su
configuración, usuarios, facturas y auditoría. El aeropuerto del terminal se
guarda en `config.json`; cambiarlo desde el panel abre otra base distinta.

**El dominio no conoce Flutter.** `TaxCalculator` y `dosa_schedule` son funciones
puras sobre modelos simples, lo que permite probar las reglas fiscales sin
levantar ninguna interfaz.

**Facturación desacoplada por puerto.** El sistema depende de la interfaz
`InvoiceOutput`, no del archivo TXT. Para pasar a una impresora fiscal o a
facturación electrónica basta con registrar otra implementación, sin tocar el
resto del código.

**Pasarela de pago simulada.** `PaymentSimulator` reproduce los estados y tiempos
de una transacción real (validación → autorización → aprobación) sin conectarse a
ningún banco. Sustituir esa clase es todo lo que hace falta para integrar una
pasarela verdadera.

**SQLite según plataforma.** `sqflite` usa el plugin nativo en Android;
`sqflite_common_ffi` toma su lugar en Windows y Linux. La selección ocurre en
`main.dart` y es transparente para los repositorios.

### Migraciones

El esquema va por la **versión 8**. Cada cambio se aplica de forma incremental y
conservadora: nunca se descartan datos que el usuario haya podido modificar.

| Versión | Cambio |
|---|---|
| 2 | Credenciales del administrador inicial |
| 3 | Se elimina el concepto de operador aéreo |
| 4 | La DOSA pasa a ser una tabla de tarifas por modelo |
| 5 | Tabla de pagos pendientes |
| 6 | La factura guarda la vigencia de la estadía |
| 7 | Deja de sembrarse la flota de ejemplo |
| 8 | La factura guarda los infantes exentos |

---

## Ejecución

Requiere Flutter con Dart SDK **3.11.4** o superior.

```bash
flutter pub get
flutter run                 # Android (dispositivo o emulador)
flutter run -d windows      # Windows
```

### Compilar para Android

```bash
flutter build apk --release
```

El paquete queda en `build/app/outputs/flutter-apk/app-release.apk` e incluye las
arquitecturas `arm64-v8a`, `armeabi-v7a` y `x86_64`. Para reducir su tamaño,
`--split-per-abi` genera un archivo por arquitectura.

> El `release` se firma con la clave de depuración. Antes de publicar hay que
> configurar una clave propia en `android/app/build.gradle.kts` y cambiar el
> `applicationId`, que hoy es `com.example.tesis`.

### Pruebas y análisis

```bash
flutter analyze
flutter test
```

La suite cubre las reglas fiscales, los tramos de permanencia, la exención de
infantes, el mapeo de modelos a la base de datos y el comportamiento responsivo
de los componentes del panel.

> **Nota (Windows):** la compilación con plugins requiere el *Modo de
> Desarrollador* activo (`start ms-settings:developers`), por el soporte de
> enlaces simbólicos que usa Flutter.

---

## Primer arranque

La base de datos se crea vacía: **sin aeronaves y sin tarifas DOSA**. Antes de
operar hay que cargar desde el panel administrativo la flota del aeropuerto y la
tabla de tarifas por modelo.

Mientras la flota esté vacía, toda matrícula consultada se considera foránea y
se le aplica DOSA, que es el comportamiento correcto según la Regla 2.
