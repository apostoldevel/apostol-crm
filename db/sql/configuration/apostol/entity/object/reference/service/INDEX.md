# service

> Configuration entity -- reference | Loaded by `reference/create.psql` line 13

Service reference with category, measure, and numeric value fields for defining billable services.

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: reference, object, type, scope, state, user, aou; category (FK), measure (FK) | subscription, invoice, order (conceptual) |

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
| `db.service` | Service reference | `id`, `reference`, `category` uuid FK, `measure` uuid FK, `value` numeric |

## Triggers -- 1

| Trigger | Table | Event | Purpose |
|---------|-------|-------|---------|
| `t_service_insert` | `db.service` | BEFORE INSERT | Auto-sets `id` from `reference` |

## Views

### kernel schema

| View | Source | Grants |
|------|--------|--------|
| `Service` | `db.service` + reference + object + class + type + state + category/measure refs + scope | administrator |
| `AccessService` | `db.service` + `db.aou` + member_group | administrator |
| `ObjectService` | `db.service` + full object/entity/class/type/state/user + category/measure joins | administrator |

### api schema

| View | Source | Purpose |
|------|--------|---------|
| `api.service` | `ObjectService` | Public API view |

## Functions (kernel schema) -- 6

| Function | Returns | Purpose |
|----------|---------|---------|
| `CreateService(pParent, pType, pCategory, pMeasure, pCode, pName, pValue, pDescription)` | `uuid` | Creates a service |
| `EditService(pId, pParent, pType, pCategory, pMeasure, pCode, pName, pValue, pDescription)` | `void` | Edits a service |
| `GetService(pCode text)` | `uuid` | Finds service by code |
| `GetServiceCode(pId)` | `text` | Returns service code by ID |
| `GetServiceValue(pId)` | `numeric` | Returns service value by ID |
| `GetServiceCategory(pId)` | `uuid` | Returns service category UUID |

## Functions (api schema) -- 5

| Function | Returns | Purpose |
|----------|---------|---------|
| `api.add_service(pParent, pType, pCategory, pMeasure, pCode, pName, pValue, pDescription)` | `uuid` | Add a service |
| `api.update_service(pId, ...)` | `void` | Update a service |
| `api.set_service(pId, ...)` | `SETOF api.service` | Upsert a service |
| `api.get_service(pId)` | `SETOF api.service` | Get service by ID |
| `api.list_service(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.service` | List services with filtering |

## REST Routes -- 6

Dispatcher: `rest.service(pPath text, pPayload jsonb)`.

| Path | Purpose |
|------|---------|
| `/service/type` | List entity types |
| `/service/method` | Get available methods for a service |
| `/service/count` | Count services with optional filtering |
| `/service/set` | Create or update a service |
| `/service/get` | Get a service by ID |
| `/service/list` | List services with filtering/pagination |

## Workflow States / Methods / Transitions

Defined via `AddDefaultMethods` with labels: Created, Active, Closed, Deleted, Activate, Close, Delete (bilingual with English translations).

Type registered: `rent.service` -- "Rent" (Equipment rental), with English translation.

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | `db.service` table, indexes, insert trigger |
| `view.sql` | yes | yes | Service, AccessService, ObjectService views |
| `routine.sql` | yes | yes | CreateService, EditService, GetService, GetServiceCode, GetServiceValue, GetServiceCategory |
| `api.sql` | yes | yes | api.service view + add/update/set/get/list functions |
| `rest.sql` | yes | yes | REST dispatcher with 6 routes |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration with bilingual methods |
