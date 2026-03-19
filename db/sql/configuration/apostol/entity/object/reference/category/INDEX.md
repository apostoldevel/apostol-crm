# category

> Configuration entity -- reference | Loaded by `reference/create.psql` line 7

Category reference for classifying services and accounts.

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: reference, object, type, scope, state, user, aou | model (FK category), service (FK category) |

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
| `db.category` | Category reference | `id`, `reference` |

## Triggers -- 1

| Trigger | Table | Event | Purpose |
|---------|-------|-------|---------|
| `t_category_insert` | `db.category` | BEFORE INSERT | Auto-sets `id` from `reference` |

## Views

### kernel schema

| View | Source | Grants |
|------|--------|--------|
| `Category` | `db.category` + reference + type + scope | administrator |
| `AccessCategory` | `db.category` + `db.aou` + member_group | administrator |
| `ObjectCategory` | `db.category` + full object/entity/class/type/state/user joins | administrator |

### api schema

| View | Source | Purpose |
|------|--------|---------|
| `api.category` | `ObjectCategory` | Public API view |

## Functions (kernel schema) -- 5

| Function | Returns | Purpose |
|----------|---------|---------|
| `CreateCategory(pParent, pType, pCode, pName, pDescription)` | `uuid` | Creates a category |
| `EditCategory(pId, pParent, pType, pCode, pName, pDescription)` | `void` | Edits a category |
| `SetCategory(pId, pParent, pType, pCode, pName, pDescription)` | `uuid` | Upsert: finds by code or creates/edits |
| `GetCategory(pCode)` | `uuid` | Finds category by code |
| `GetCategoryCode(pId)` | `text` | Returns category code by ID |

## Functions (api schema) -- 7

| Function | Returns | Purpose |
|----------|---------|---------|
| `api.add_category(pParent, pType, pCode, pName, pDescription)` | `uuid` | Add a category |
| `api.update_category(pId, ...)` | `void` | Update a category |
| `api.set_category(pId, ...)` | `SETOF api.category` | Upsert a category |
| `api.get_category(pId)` | `SETOF api.category` | Get category by ID |
| `api.list_category(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.category` | List categories with filtering |
| `api.get_category_id(pCode)` | `uuid` | Get category UUID by code |

## REST Routes -- 6

Dispatcher: `rest.category(pPath text, pPayload jsonb)`.

| Path | Purpose |
|------|---------|
| `/category/type` | List entity types |
| `/category/method` | Get available methods for a category |
| `/category/count` | Count categories with optional filtering |
| `/category/set` | Create or update a category |
| `/category/get` | Get a category by ID |
| `/category/list` | List categories with filtering/pagination |

## Workflow States / Methods / Transitions

Defined via `AddDefaultMethods` with labels: Created, Opened, Closed, Deleted, Open, Close, Delete.

Types registered: `service.category` -- "Service" (Service provision category), `account.category` -- "Account" (Personal account category).

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | `db.category` table, index, insert trigger |
| `view.sql` | yes | yes | Category, AccessCategory, ObjectCategory views |
| `routine.sql` | yes | yes | CreateCategory, EditCategory, SetCategory, GetCategory, GetCategoryCode |
| `api.sql` | yes | yes | api.category view + add/update/set/get/list/get_category_id functions |
| `rest.sql` | yes | yes | REST dispatcher with 6 routes |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration with bilingual methods |
