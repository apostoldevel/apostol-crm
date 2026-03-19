# currency

> Configuration entity -- reference | Loaded by `reference/create.psql` line 8

Currency reference with ISO 4217 digital codes and decimal precision, pre-seeded with 3 currencies (RUB, USD, EUR).

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: reference, object, type, scope, state, user, aou | payment, invoice, transaction (conceptual) |

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
| `db.currency` | Currency reference | `id`, `reference`, `digital` integer, `decimal` integer (default 2) |

## Triggers -- 1

| Trigger | Table | Event | Purpose |
|---------|-------|-------|---------|
| `t_currency_insert` | `db.currency` | BEFORE INSERT | Auto-sets `id` from `reference` |

## Views

### kernel schema

| View | Source | Grants |
|------|--------|--------|
| `Currency` | `db.currency` + reference + type + scope | administrator |
| `AccessCurrency` | `db.currency` + `db.aou` + member_group | administrator |
| `ObjectCurrency` | `db.currency` + full object/entity/class/type/state/user joins | administrator |

### api schema

| View | Source | Purpose |
|------|--------|---------|
| `api.currency` | `ObjectCurrency` | Public API view |

## Functions (kernel schema) -- 7

| Function | Returns | Purpose |
|----------|---------|---------|
| `CreateCurrency(pParent, pType, pCode, pName, pDescription, pDigital, pDecimal)` | `uuid` | Creates a currency |
| `EditCurrency(pId, pParent, pType, pCode, pName, pDescription, pDigital, pDecimal)` | `void` | Edits a currency |
| `GetCurrency(pCode text)` | `uuid` | Finds currency by code |
| `GetCurrencyCode(pId)` | `text` | Returns currency code by ID |
| `GetCurrencyDigital(pId)` | `integer` | Returns digital code by ID |
| `DefaultCurrencyCode(pDefault)` | `text` | Returns default currency code from registry (fallback: RUB) |
| `DefaultCurrency()` | `uuid` | Returns default currency UUID |

## Functions (api schema) -- 6

| Function | Returns | Purpose |
|----------|---------|---------|
| `api.add_currency(pParent, pType, pCode, pName, pDescription, pDigital, pDecimal)` | `uuid` | Add a currency |
| `api.update_currency(pId, ...)` | `void` | Update a currency |
| `api.set_currency(pId, ...)` | `SETOF api.currency` | Upsert a currency |
| `api.get_currency(pId)` | `SETOF api.currency` | Get currency by ID |
| `api.list_currency(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.currency` | List currencies with filtering |
| `api.get_currency_id(pCode)` | `uuid` | Get currency UUID by code |

## REST Routes -- 6

Dispatcher: `rest.currency(pPath text, pPayload jsonb)`.

| Path | Purpose |
|------|---------|
| `/currency/type` | List entity types |
| `/currency/method` | Get available methods for a currency |
| `/currency/count` | Count currencies with optional filtering |
| `/currency/set` | Create or update a currency |
| `/currency/get` | Get a currency by ID |
| `/currency/list` | List currencies with filtering/pagination |

## Workflow States / Methods / Transitions

Defined via `AddDefaultMethods` with labels: Created, Opened, Closed, Deleted, Open, Close, Delete.

Types registered: `iso.currency` -- "ISO" (ISO 4217), `crypto.currency` -- "Cryptocurrency", `unit.currency` -- "Conditional unit".

## Init / Seed Data

`InitCurrency()` inserts 3 currencies: RUB (643), USD (840), EUR (978).

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | `db.currency` table, index, insert trigger |
| `view.sql` | yes | yes | Currency, AccessCurrency, ObjectCurrency views |
| `routine.sql` | yes | yes | CreateCurrency, EditCurrency, GetCurrency, GetCurrencyCode, GetCurrencyDigital, DefaultCurrencyCode, DefaultCurrency |
| `api.sql` | yes | yes | api.currency view + add/update/set/get/list/get_id functions |
| `rest.sql` | yes | yes | REST dispatcher with 6 routes |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, InitCurrency seed data |
