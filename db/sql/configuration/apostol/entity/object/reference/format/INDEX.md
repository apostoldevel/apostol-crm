# format

> Configuration entity -- reference | Loaded by `reference/create.psql` line 9

Data format reference for classifying data representations.

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: reference, object, type, scope, state, user, aou | model_property (format field) |

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
| `db.format` | Format reference | `id`, `reference` |

## Triggers -- 1

| Trigger | Table | Event | Purpose |
|---------|-------|-------|---------|
| `t_format_insert` | `db.format` | BEFORE INSERT | Auto-sets `id` from `reference` |

## Views

### kernel schema

| View | Source | Grants |
|------|--------|--------|
| `Format` | `db.format` + reference + type + scope | administrator |
| `AccessFormat` | `db.format` + `db.aou` + member_group | administrator |
| `ObjectFormat` | `db.format` + full object/entity/class/type/state/user joins | administrator |

### api schema

| View | Source | Purpose |
|------|--------|---------|
| `api.format` | `ObjectFormat` | Public API view |

## Functions (kernel schema) -- 3

| Function | Returns | Purpose |
|----------|---------|---------|
| `CreateFormat(pParent, pType, pCode, pName, pDescription)` | `uuid` | Creates a format |
| `EditFormat(pId, pParent, pType, pCode, pName, pDescription)` | `void` | Edits a format |
| `GetFormat(pCode text)` | `uuid` | Finds format by code |

## Functions (api schema) -- 6

| Function | Returns | Purpose |
|----------|---------|---------|
| `api.add_format(pParent, pType, pCode, pName, pDescription)` | `uuid` | Add a format |
| `api.update_format(pId, ...)` | `void` | Update a format |
| `api.set_format(pId, ...)` | `SETOF api.format` | Upsert a format |
| `api.get_format(pId)` | `SETOF api.format` | Get format by ID |
| `api.count_format(pSearch, pFilter)` | `SETOF bigint` | Count formats with filtering |
| `api.list_format(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.format` | List formats with filtering |

## REST Routes -- 6

Dispatcher: `rest.format(pPath text, pPayload jsonb)`.

| Path | Purpose |
|------|---------|
| `/format/type` | List entity types |
| `/format/method` | Get available methods for a format |
| `/format/count` | Count formats with optional filtering |
| `/format/set` | Create or update a format |
| `/format/get` | Get a format by ID |
| `/format/list` | List formats with filtering/pagination |

## Workflow States / Methods / Transitions

Defined via `AddDefaultMethods` (default labels).

Type registered: `data.format` -- "Data" (Data format), with English translation.

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | `db.format` table, index, insert trigger |
| `view.sql` | yes | yes | Format, AccessFormat, ObjectFormat views |
| `routine.sql` | yes | yes | CreateFormat, EditFormat, GetFormat |
| `api.sql` | yes | yes | api.format view + add/update/set/get/count/list functions |
| `rest.sql` | yes | yes | REST dispatcher with 6 routes |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration |
