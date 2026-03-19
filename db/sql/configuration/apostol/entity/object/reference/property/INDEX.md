# property

> Configuration entity -- reference | Loaded by `reference/create.psql` line 4

Property reference with types for different value kinds (string, integer, numeric, datetime, boolean).

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: reference, object, type, scope, state, user, aou | model_property (FK property) |

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
| `db.property` | Property reference | `id`, `reference` |

## Triggers -- 1

| Trigger | Table | Event | Purpose |
|---------|-------|-------|---------|
| `t_property_insert` | `db.property` | BEFORE INSERT | Auto-sets `id` from `reference` |

## Views

### kernel schema

| View | Source | Grants |
|------|--------|--------|
| `Property` | `db.property` + reference + type + scope | administrator |
| `AccessProperty` | `db.property` + `db.aou` + member_group | administrator |
| `ObjectProperty` | `db.property` + full object/entity/class/type/state/user joins | administrator |

### api schema

| View | Source | Purpose |
|------|--------|---------|
| `api.property` | `ObjectProperty` | Public API view |

## Functions (kernel schema) -- 3

| Function | Returns | Purpose |
|----------|---------|---------|
| `CreateProperty(pParent, pType, pCode, pName, pDescription)` | `uuid` | Creates a property |
| `EditProperty(pId, pParent, pType, pCode, pName, pDescription)` | `void` | Edits a property |
| `GetProperty(pCode text)` | `uuid` | Finds property by code |

## Functions (api schema) -- 5

| Function | Returns | Purpose |
|----------|---------|---------|
| `api.add_property(pParent, pType, pCode, pName, pDescription)` | `uuid` | Add a property |
| `api.update_property(pId, ...)` | `void` | Update a property |
| `api.set_property(pId, ...)` | `SETOF api.property` | Upsert a property |
| `api.get_property(pId)` | `SETOF api.property` | Get property by ID |
| `api.list_property(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.property` | List properties with filtering |

## REST Routes -- 6

Dispatcher: `rest.property(pPath text, pPayload jsonb)`.

| Path | Purpose |
|------|---------|
| `/property/type` | List entity types |
| `/property/method` | Get available methods for a property |
| `/property/count` | Count properties with optional filtering |
| `/property/set` | Create or update a property |
| `/property/get` | Get a property by ID |
| `/property/list` | List properties with filtering/pagination |

## Workflow States / Methods / Transitions

Defined via `AddDefaultMethods` with labels: Created, Available, Unavailable, Deleted, Open, Close, Delete.

Types registered: `string.property` -- "String", `integer.property` -- "Integer", `numeric.property` -- "Numeric", `datetime.property` -- "Date and time", `boolean.property` -- "Boolean".

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | `db.property` table, index, insert trigger |
| `view.sql` | yes | yes | Property, AccessProperty, ObjectProperty views |
| `routine.sql` | yes | yes | CreateProperty, EditProperty, GetProperty |
| `api.sql` | yes | yes | api.property view + add/update/set/get/list functions |
| `rest.sql` | yes | yes | REST dispatcher with 6 routes |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, AddDefaultMethods |
