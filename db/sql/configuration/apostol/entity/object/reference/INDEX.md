# entity/object/reference

> Configuration — reference entity hierarchy

Twelve reference (catalog) entities providing lookup data for the Project Example system: countries, currencies, regions, data formats, measurement units, and more.

## Loading Order (reference/create.psql)

```
reference/
  event.sql                ← Shared EventReferenceCreate override
  country/create.psql      ← ISO 3166-1 countries (~240 seeded)
  property/create.psql     ← Typed properties (string/int/numeric/datetime/bool)
  address/create.psql      ← Addresses with KLADR integration
  calendar/create.psql     ← Work calendars with date generation
  category/create.psql     ← Flexible categorization (service/account)
  currency/create.psql     ← ISO 4217 currencies (RUB/USD/EUR seeded)
  format/create.psql       ← GNSS data formats (RTCM, NMEA, etc.)
  measure/create.psql      ← Units of measurement (~50 seeded)
  model/create.psql        ← Device models with typed properties
  region/create.psql       ← Russian Federation regions (~70 seeded)
  service/create.psql      ← Billable services (time/volume)
```

## Entity Index

| Entity | Tables | Functions | REST Routes | Seed Data |
|--------|--------|-----------|-------------|-----------|
| [address](address/INDEX.md) | 1 (14 cols) | 25 | 12 | — |
| [calendar](calendar/INDEX.md) | 2 | 22 | 13 | 1 default calendar |
| [category](category/INDEX.md) | 1 | 12 | 6 | — |
| [country](country/INDEX.md) | 1 | 10 | 6 | ~240 countries |
| [currency](currency/INDEX.md) | 1 | 13 | 6 | RUB, USD, EUR |
| [format](format/INDEX.md) | 1 | 9 | 6 | 12 formats |
| [measure](measure/INDEX.md) | 1 | 8 | 6 | ~50 units |
| [model](model/INDEX.md) | 2 | 23 | 12 | 3 default models |
| [property](property/INDEX.md) | 1 | 8 | 6 | — |
| [region](region/INDEX.md) | 1 | 9 | 6 | ~70 RF regions |
| [service](service/INDEX.md) | 1 | 11 | 6 | 2 services |

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `event.sql` | yes | yes | Shared EventReferenceCreate override |
| `*/create.psql` | yes | — | 12 entity sub-modules |
| `create.psql` | — | — | Loads event.sql + 12 entities |
| `update.psql` | — | — | Loads event.sql + 12 entity updates |
