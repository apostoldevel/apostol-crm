# tariff

> Configuration entity -- document | Loaded by `document/create.psql` line 19

Pricing tariff management linking products to services with per-unit pricing, commission rates, and tax percentages. Supports a secondary `tariff_scheme` table for default service pricing independent of specific products. Used by the transaction system to calculate billing amounts.

## Dependencies

- `product` -- each tariff belongs to a product
- `service` -- each tariff prices a specific service
- `currency` -- pricing currency
- Platform: `document`, `object`, `reference`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Tables `tariff`, `tariff_scheme`; triggers |
| `kernel` | Views `Tariff`, `AccessTariff`, `ObjectTariff`, `TariffScheme`; routines |
| `api` | Views `api.tariff`, `api.tariff_scheme`; CRUD + list functions |
| `rest` | Dispatcher `rest.tariff()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.tariff` | id, document, product, service, currency, tag, code, price, commission, tax | Per-product service tariff |
| `db.tariff_scheme` | service, currency, tag, price, commission, tax | Default service pricing (PK: service+currency+tag) |

**Indexes (tariff):** UNIQUE(code), UNIQUE(product, service, currency, tag), document, product, service, currency

**Indexes (tariff_scheme):** service, currency

**Triggers (1):**
- `t_tariff_before_insert` -- sets id from document, generates code (`tariff_*`)

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Tariff` | kernel | Joins tariff with type, product, service, measure, currency |
| `AccessTariff` | kernel | ACL-filtered tariff access |
| `ObjectTariff` | kernel | Full object view with entity, class, owner, area, scope |
| `TariffScheme` | kernel | Formatted tariff scheme with human-readable description |
| `api.tariff` | api | Exposes `ObjectTariff` |
| `api.tariff_scheme` | api | Exposes `TariffScheme` |

## Functions

**kernel schema (7):**
- `CreateTariff(pParent, pType, pProduct, pService, pCurrency, pCode, pTag, pPrice, pCommission, pTax, pLabel, pDescription)` -- creates tariff document
- `EditTariff(pId, ...)` -- updates tariff
- `GetTariff(pCode)` -- lookup by code
- `SetTariffScheme(pService, pCurrency, pTag, pPrice, pCommission, pTax)` -- upsert into tariff_scheme
- `GetTariffScheme(pId)` -- returns price for tariff id
- `GetServiceTariffId(pProduct, pService, pCurrency, pTag)` -- finds enabled tariff by product+service+currency+tag
- `GetServicePrice(pProduct, pService, pCurrency, pTag)` -- calculates per-unit price (price / service.value)

**api schema (7):**
- `api.add_tariff` -- defaults to type `custom.tariff`
- `api.update_tariff` -- lookup by id or code
- `api.set_tariff` -- upsert
- `api.get_tariff` -- single record
- `api.list_tariff` -- list with search/filter/pagination
- `api.get_tariff_scheme` -- by service+currency+tag
- `api.list_tariff_scheme` -- list with search/filter/pagination

**Event functions (9):**
- `EventTariffCreate` -- auto-enables after creation
- `EventTariffOpen`, `EventTariffEdit`, `EventTariffSave`, `EventTariffEnable`, `EventTariffDisable`
- `EventTariffDelete` -- blocks deletion of system tariffs for non-admins
- `EventTariffRestore`, `EventTariffDrop`

## REST Routes

Dispatcher: `rest.tariff(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/tariff/type` | List tariff types |
| `/tariff/method` | Get available methods |
| `/tariff/count` | Count tariffs |
| `/tariff/set` | Upsert tariff |
| `/tariff/get` | Get by id |
| `/tariff/list` | List tariffs |
| `/tariff/scheme/get` | Get tariff scheme by service+currency+tag |
| `/tariff/scheme/count` | Count tariff schemes |
| `/tariff/scheme/list` | List tariff schemes |

## Workflow States / Methods / Transitions

**Types:** `system.tariff`, `custom.tariff`

**States:** Uses `DefaultMethods` -- standard created/enabled/disabled/deleted lifecycle.

## Init / Seed Data

- `CreateEntityTariff(pParent)` -- registers entity, class, types, events, methods
- `AddTariffEvents(pClass)` -- wires 9 event handlers
- `InitTariffScheme()` -- seeds default tariff scheme: time.service = 0.1 RUB, volume.service = 0.01 RUB
- Registers REST route: `tariff`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | 2 tables, indexes, 1 trigger |
| `view.sql` | yes | yes | 4 kernel views |
| `routine.sql` | yes | yes | 7 kernel functions |
| `api.sql` | yes | yes | 2 api views, 7 api functions |
| `rest.sql` | yes | yes | REST dispatcher (9 routes) |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class registration, tariff scheme seeding |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
