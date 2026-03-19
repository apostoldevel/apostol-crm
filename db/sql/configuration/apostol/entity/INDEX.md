# entity

> Configuration module | Loaded by `example/create.psql` line 7

The entity module registers the complete Project Example class tree and contains all 30 business entities (12 references + 18 documents + 9 sub-entities).

## Class Tree (registered by `InitConfigurationEntity()`)

```
object (platform)
├── reference (platform)
│     ├── address          — Physical addresses with KLADR
│     ├── calendar         — Work calendars with date generation
│     ├── category         — Flexible categorization
│     ├── country          — ISO 3166-1 countries
│     ├── currency         — ISO 4217 currencies
│     ├── format           — GNSS data formats
│     ├── measure          — Units of measurement
│     ├── model            — Device models with properties
│     ├── property         — Typed key-value properties
│     ├── region           — RF region codes
│     └── service          — Billable services
└── document (platform)
      ├── account          — Financial accounts
      │     └── balance    — (helper tables, not a class)
      ├── card             — Payment/ID cards
      ├── client           — Core client entity
      │     ├── customer   — Customer sub-class
      │     └── employee   — Employee sub-class
      ├── company          — Companies (extends client)
      ├── device           — IoT/GNSS devices
      │     ├── caster     — NTRIP casters
      │     └── station    — GNSS base stations
      ├── identity         — Identity documents
      ├── invoice          — Invoices with auto-payment
      ├── order            — Financial orders
      ├── payment          — Payment processing
      │     ├── cloudpayments — CloudPayments gateway
      │     └── yookassa     — YooKassa gateway
      ├── price            — Price definitions
      ├── product          — Product catalog
      ├── subscription     — Time/volume subscriptions
      ├── tariff           — Tariff plans
      ├── task             — Background tasks
      └── transaction      — Financial transactions
```

## Loading Order (entity/create.psql)

```
entity/
  object/create.psql       ← event.sql, report.sql, reference/, document/
  init.sql                 ← InitConfigurationEntity() — registers full class tree
```

## Sub-modules

| Sub-module | Description |
|------------|-------------|
| [object/](object/INDEX.md) | Object layer (references + documents) |
| [object/reference/](object/reference/INDEX.md) | 12 reference entities |
| [object/document/](object/document/INDEX.md) | 18 document entities + 9 sub-entities |

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `object/create.psql` | yes | — | All object entities |
| `init.sql` | yes | no | `InitConfigurationEntity()` — class tree registration |
| `create.psql` | — | — | Includes object/create.psql + init.sql |
| `update.psql` | — | — | Includes object/update.psql |
