# country

> Configuration entity -- reference | Loaded by `reference/create.psql` line 3

ISO 3166 country reference with alpha-2, alpha-3 codes and numeric identifiers, pre-seeded with 240 countries.

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: reference, object, type, scope, state, user, aou | address (FK country), region (conceptual) |

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
| `db.country` | Country reference | `id`, `reference`, `alpha2` char(2), `alpha3` char(3), `digital` integer, `flag` text |

## Triggers -- 1

| Trigger | Table | Event | Purpose |
|---------|-------|-------|---------|
| `t_country_insert` | `db.country` | BEFORE INSERT | Auto-sets `id` from `reference` |

## Views

### kernel schema

| View | Source | Grants |
|------|--------|--------|
| `Country` | `db.country` + reference + type + scope | administrator |
| `AccessCountry` | `db.country` + `db.aou` + member_group | administrator |
| `ObjectCountry` | `db.country` + full object/entity/class/type/state/user joins | administrator |

### api schema

| View | Source | Purpose |
|------|--------|---------|
| `api.country` | `ObjectCountry` | Public API view |

## Functions (kernel schema) -- 14

| Function | Returns | Purpose |
|----------|---------|---------|
| `CreateCountry(pParent, pType, pCode, pName, pDescription, pAlpha2, pAlpha3, pDigital, pFlag)` | `uuid` | Creates a country |
| `EditCountry(pId, pParent, pType, pCode, pName, pDescription, pAlpha2, pAlpha3, pDigital, pFlag)` | `void` | Edits a country |
| `GetCountry(pDigital integer)` | `uuid` | Finds country by numeric code |
| `GetCountry(pCode text)` | `uuid` | Finds country by alpha2/alpha3 code |
| `GetCountryName(pId)` | `text` | Returns country name |
| `GetCountryByISO(pISO)` | `uuid` | Returns country by ISO code |
| `EventCountryCreate(pObject)` | `void` | Event: country created (auto-enables) |
| `EventCountryOpen(pObject)` | `void` | Event: country opened |
| `EventCountryEdit(pObject)` | `void` | Event: country edited |
| `EventCountrySave(pObject)` | `void` | Event: country saved |
| `EventCountryEnable(pObject)` | `void` | Event: country enabled |
| `EventCountryDisable(pObject)` | `void` | Event: country disabled |
| `EventCountryDelete(pObject)` | `void` | Event: country deleted |
| `EventCountryRestore(pObject)` | `void` | Event: country restored |
| `EventCountryDrop(pObject)` | `void` | Event: country dropped (destroys record) |

## Functions (api schema) -- 6

| Function | Returns | Purpose |
|----------|---------|---------|
| `api.add_country(pParent, pType, pCode, pName, pDescription, pAlpha2, pAlpha3, pDigital, pFlag)` | `uuid` | Add a country |
| `api.update_country(pId, ...)` | `void` | Update a country |
| `api.set_country(pId, ...)` | `SETOF api.country` | Upsert a country |
| `api.get_country(pId)` | `SETOF api.country` | Get country by ID |
| `api.list_country(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.country` | List countries with filtering |
| `api.get_country_id(pCode)` | `uuid` | Get country UUID by code |

## REST Routes -- 6

Dispatcher: `rest.country(pPath text, pPayload jsonb)`.

| Path | Purpose |
|------|---------|
| `/country/type` | List entity types |
| `/country/method` | Get available methods for a country |
| `/country/count` | Count countries with optional filtering |
| `/country/set` | Create or update a country |
| `/country/get` | Get a country by ID |
| `/country/list` | List countries with filtering/pagination |

## Workflow States / Methods / Transitions

Defined via `AddDefaultMethods` with labels: Created, Opened, Closed, Deleted, Open, Close, Delete.

Type registered: `iso.country` -- "ISO 3166" (list of ISO 3166 codes).

## Init / Seed Data

`InitCountry()` inserts 240 countries with alpha-2, alpha-3 codes and numeric ISO codes. Examples: Russia (RU/RUS/643), USA (US/USA/840), Germany (DE/DEU/276).

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | `db.country` table, indexes, insert trigger |
| `view.sql` | yes | yes | Country, AccessCountry, ObjectCountry views |
| `routine.sql` | yes | yes | CreateCountry, EditCountry, GetCountry*, GetCountryName, GetCountryByISO |
| `api.sql` | yes | yes | api.country view + add/update/set/get/list/get_id functions |
| `rest.sql` | yes | yes | REST dispatcher with 6 routes |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, InitCountry seed data |
