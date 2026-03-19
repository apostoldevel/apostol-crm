# measure

> Configuration entity -- reference | Loaded by `reference/create.psql` line 10

Units of measurement reference with 7 categories, pre-seeded with ~50 units covering time, length, weight, volume, area, technical, and economic measures.

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: reference, object, type, scope, state, user, aou | model_property (FK measure), service (FK measure) |

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Tables, trigger function |
| `kernel` | Views, functions |
| `api` | API views, functions |
| `rest` | REST dispatcher |

## Tables -- 1

| Table | Description | Key Columns |
|-------|-------------|-------------|
| `db.measure` | Measure reference | `id`, `reference` |

## Triggers -- 1

| Trigger | Table | Event | Purpose |
|---------|-------|-------|---------|
| `t_measure_insert` | `db.measure` | BEFORE INSERT | Auto-sets `id` from `reference` |

## Views

### kernel schema

| View | Source | Grants |
|------|--------|--------|
| `Measure` | `db.measure` + reference + type + scope | administrator |
| `AccessMeasure` | `db.measure` + `db.aou` + member_group | administrator |
| `ObjectMeasure` | `db.measure` + full object/entity/class/type/state/user joins | administrator |

### api schema

| View | Source | Purpose |
|------|--------|---------|
| `api.measure` | `ObjectMeasure` | Public API view |

## Functions (kernel schema) -- 3

| Function | Returns | Purpose |
|----------|---------|---------|
| `CreateMeasure(pParent, pType, pCode, pName, pDescription)` | `uuid` | Creates a measure |
| `EditMeasure(pId, pParent, pType, pCode, pName, pDescription)` | `void` | Edits a measure |
| `GetMeasure(pCode text)` | `uuid` | Finds measure by code |

## Functions (api schema) -- 5

| Function | Returns | Purpose |
|----------|---------|---------|
| `api.add_measure(pParent, pType, pCode, pName, pDescription)` | `uuid` | Add a measure |
| `api.update_measure(pId, ...)` | `void` | Update a measure |
| `api.set_measure(pId, ...)` | `SETOF api.measure` | Upsert a measure |
| `api.get_measure(pId)` | `SETOF api.measure` | Get measure by ID |
| `api.list_measure(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.measure` | List measures with filtering |

## REST Routes -- 6

Dispatcher: `rest.measure(pPath text, pPayload jsonb)`.

| Path | Purpose |
|------|---------|
| `/measure/type` | List entity types |
| `/measure/method` | Get available methods for a measure |
| `/measure/count` | Count measures with optional filtering |
| `/measure/set` | Create or update a measure |
| `/measure/get` | Get a measure by ID |
| `/measure/list` | List measures with filtering/pagination |

## Workflow States / Methods / Transitions

Defined via `AddDefaultMethods` with labels: Created, Opened, Closed, Deleted, Open, Close, Delete.

Types registered: `time.measure` -- "Time", `length.measure` -- "Length", `weight.measure` -- "Weight", `volume.measure` -- "Volume", `area.measure` -- "Area", `technical.measure` -- "Technical", `economic.measure` -- "Economic".

## Init / Seed Data

`InitMeasure()` inserts ~50 units of measurement: mm/cm/m/km (length), sq.m/sq.km (area), cm3/l/m3 (volume), mg/g/kg/t (weight), W/kW/MW/V/kV/A (technical), s/min/h/day (time), pcs/% (economic), and more.

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | `db.measure` table, index, insert trigger |
| `view.sql` | yes | yes | Measure, AccessMeasure, ObjectMeasure views |
| `routine.sql` | yes | yes | CreateMeasure, EditMeasure, GetMeasure |
| `api.sql` | yes | yes | api.measure view + add/update/set/get/list functions |
| `rest.sql` | yes | yes | REST dispatcher with 6 routes |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, InitMeasure seed data |
