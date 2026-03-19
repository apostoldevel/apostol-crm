# region

> Configuration entity -- reference | Loaded by `reference/create.psql` line 12

Russian Federation region codes reference, pre-seeded with ~70 regions. On enable, copies KLADR address data for the region.

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: reference, object, type, scope, state, user, aou, kladr (address_tree, CopyFromKladr) | station (conceptual region assignment) |

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
| `db.region` | Region reference | `id`, `reference` |

## Triggers -- 1

| Trigger | Table | Event | Purpose |
|---------|-------|-------|---------|
| `t_region_insert` | `db.region` | BEFORE INSERT | Auto-sets `id` from `reference` |

## Views

### kernel schema

| View | Source | Grants |
|------|--------|--------|
| `Region` | `db.region` + reference + type + scope | administrator |
| `AccessRegion` | `db.region` + `db.aou` + member_group | administrator |
| `ObjectRegion` | `db.region` + full object/entity/class/type/state/user joins | administrator |

### api schema

| View | Source | Purpose |
|------|--------|---------|
| `api.region` | `ObjectRegion` | Public API view |

## Functions (kernel schema) -- 3

| Function | Returns | Purpose |
|----------|---------|---------|
| `CreateRegion(pParent, pType, pCode, pName, pDescription)` | `uuid` | Creates a region |
| `EditRegion(pId, pParent, pType, pCode, pName, pDescription)` | `void` | Edits a region |
| `GetRegion(pCode text)` | `uuid` | Finds region by code |

## Functions (api schema) -- 6

| Function | Returns | Purpose |
|----------|---------|---------|
| `api.add_region(pParent, pType, pCode, pName, pDescription)` | `uuid` | Add a region |
| `api.update_region(pId, ...)` | `void` | Update a region |
| `api.set_region(pId, ...)` | `SETOF api.region` | Upsert a region |
| `api.get_region(pId)` | `SETOF api.region` | Get region by ID |
| `api.count_region(pSearch, pFilter)` | `SETOF bigint` | Count regions with filtering |
| `api.list_region(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.region` | List regions with filtering |

## REST Routes -- 6

Dispatcher: `rest.region(pPath text, pPayload jsonb)`.

| Path | Purpose |
|------|---------|
| `/region/type` | List entity types |
| `/region/method` | Get available methods for a region |
| `/region/count` | Count regions with optional filtering |
| `/region/set` | Create or update a region |
| `/region/get` | Get a region by ID |
| `/region/list` | List regions with filtering/pagination |

## Workflow States / Methods / Transitions

Defined via `AddDefaultMethods` (default labels).

Type registered: `code.region` -- "Region codes" (RF region codes), with English translation.

## Init / Seed Data

`InitRegion()` inserts ~70 Russian Federation regions with two-digit codes: republics (01-21), krais (22-27), oblasts (28-76), federal cities Moscow (77) and Saint Petersburg (78), autonomous oblast (79), autonomous okrugs (83, 86, 87, 89), and "other territories" (99).

## Event: EventRegionEnable

Notable: `EventRegionEnable` copies KLADR address data for the region via `CopyFromKladr()`, initializing the address_tree for that region.

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | `db.region` table, index, insert trigger |
| `view.sql` | yes | yes | Region, AccessRegion, ObjectRegion views |
| `routine.sql` | yes | yes | CreateRegion, EditRegion, GetRegion |
| `api.sql` | yes | yes | api.region view + add/update/set/get/count/list functions |
| `rest.sql` | yes | yes | REST dispatcher with 6 routes |
| `event.sql` | yes | yes | 9 event handlers (EventRegionEnable copies KLADR data) |
| `init.sql` | yes | no | Entity/class/type registration, InitRegion seed data |
