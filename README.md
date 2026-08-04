# SkyTax

Sistema digital para el cálculo y pago de impuestos aeroportuarios en Venezuela.
Aplicación de kiosco táctil multiplataforma (Android tablet / Windows desktop)
desarrollada en Flutter con una única base de código.

## Funcionalidades

- **Selección de idioma** (Español / English) al estilo de un kiosco de autoservicio.
- **Consulta de aeronave**: matrícula, tipo y cantidad de pasajeros.
- **Cálculo automático de impuestos** (el operador nunca selecciona impuestos):
  - *Regla 1*: si la matrícula existe en la base de datos local del aeropuerto,
    la aeronave es local → paga `tasa aeroportuaria × pasajeros`.
  - *Regla 2*: si no existe, pertenece a otro aeropuerto → paga además la **DOSA**.
- **Pago simulado** con Tarjeta (validación → autorización → aprobación) o
  Pago Móvil (datos del beneficiario + número de referencia).
- **Factura digital `.txt`** generada automáticamente en `Documentos/SkyTax/Facturas/`
  con numeración `FACT-000001`, `FACT-000002`, …
- **Historial** de facturas con búsqueda y visor del archivo TXT.
- **Panel administrativo** (usuario inicial `admin` / `admin123`):
  aeronaves, operadores, usuarios, configuración de tasas (tasa aeroportuaria y DOSA),
  aeropuerto del terminal, historial, reportes TXT y auditoría.
- **Logging** a archivo (`skytax.log`) y **auditoría** de cada operación
  (usuario, acción, fecha/hora y aeropuerto).

## Arquitectura

```
lib/
├── core/            # Tema (Material 3, #546E7A), i18n ES/EN, formateadores,
│                    # rutas de la app y logging
├── data/            # Modelos, base de datos SQLite y repositorios
│   └── database/    # Una base de datos independiente por aeropuerto:
│                    #   skytax_<codigo>.db (solo aeronaves con base en él)
├── domain/          # Lógica de negocio pura:
│   ├── tax_calculator.dart    # Reglas 1 y 2 del cálculo
│   ├── invoicing.dart         # Puerto InvoiceOutput + implementación TXT
│   └── payment_simulator.dart # Pasarela de pago simulada
└── presentation/    # Estado (Provider) + pantallas del kiosco y del admin
```

El módulo de facturación está desacoplado mediante el puerto `InvoiceOutput`:
para sustituir el archivo TXT por una impresora fiscal o facturación electrónica
solo se registra otra implementación, sin modificar el resto del sistema.
La base de datos usa `sqflite` en Android y `sqflite_common_ffi` en Windows.

## Ejecución

```bash
flutter pub get
flutter run -d windows    # Windows (requiere Modo de Desarrollador activo)
flutter run               # Android
```

Pruebas y análisis:

```bash
flutter analyze
flutter test
```

> **Nota (Windows):** la compilación con plugins requiere habilitar el
> *Modo de Desarrollador* (`start ms-settings:developers`) por el soporte de
> enlaces simbólicos de Flutter.

## Datos de demostración

La base de datos de SVMI (Maiquetía) se crea automáticamente con operadores
(Conviasa, Avior, Laser, Estelar) y una flota de ejemplo (`YV1234`, `YV2850`,
`YV3016`, `YV3224`, `YV1004`, `YV3389`). Cualquier matrícula no registrada se
considera de otro aeropuerto y paga DOSA automáticamente.
