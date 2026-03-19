# entity/object

> Configuration — object layer

The object layer contains shared event/report overrides and two entity hierarchies: references (catalogs) and documents (business objects).

## Loading Order (object/create.psql)

```
object/
  event.sql                ← Shared object-level event overrides (EventObjectCreate, EventObjectEdit)
  report.sql               ← Report helper functions (ReportClient, ReportStation)
  reference/create.psql    ← 12 reference entities
  document/create.psql     ← 18 document entities + 9 sub-entities
```

## Sub-modules

| Sub-module | Entities | Description |
|------------|----------|-------------|
| [reference/](reference/INDEX.md) | 12 | Catalog/lookup data (countries, currencies, regions, GNSS formats, etc.) |
| [document/](document/INDEX.md) | 18 + 9 sub-entities | Business documents (clients, devices, payments, subscriptions, etc.) |

## Shared Files

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `event.sql` | yes | yes | EventObjectCreate, EventObjectEdit overrides |
| `report.sql` | yes | yes | ReportClient, ReportStation helper functions |
