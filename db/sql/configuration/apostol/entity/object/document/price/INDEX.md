# price

> Configuration entity -- document | Loaded by `document/create.psql` line 17

Price management with Stripe-like semantics. Each price links a product to a specific amount in a given currency. Supports one-off and recurring pricing models, payment links, and metadata storage. Prices are automatically enabled/disabled alongside their parent product.

## Dependencies

- `product` -- each price belongs to a product
- `currency` -- pricing currency
- Platform: `document`, `object`, `aou`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `price`, trigger |
| `kernel` | Views `Price`, `AccessPrice`, `ObjectPrice`; routines |
| `api` | View `api.price`; CRUD + list/count functions |
| `rest` | Dispatcher `rest.price()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.price` | id, document, currency, product, code, amount, payment_link, metadata | Price record with Stripe-style fields |

**Indexes:** UNIQUE(code), document, currency, product

**Triggers (1):**
- `t_price_insert` -- BEFORE INSERT: sets id from document, generates code (`price_*`)

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Price` | kernel | Joins price with type, currency (with decimal/digital), product name |
| `AccessPrice` | kernel | ACL-filtered price access |
| `ObjectPrice` | kernel | Full object view with entity, class, currency, product, owner, area, scope |
| `api.price` | api | Exposes `ObjectPrice` |

## Functions

**kernel schema (3):**
- `CreatePrice(pParent, pType, pCurrency, pProduct, pCode, pAmount, pPaymentLink, pMetaData, pLabel, pDescription)` -- creates price document with currency/product validation
- `EditPrice(pId, ...)` -- updates price fields
- `GetPrice(pCode)` -- lookup by code

**api schema (6):**
- `api.add_price` -- defaults to type `one_time.price`
- `api.update_price` -- lookup by id or code
- `api.set_price` -- upsert by id or code
- `api.get_price` -- with access check
- `api.count_price` -- count with search/filter
- `api.list_price` -- list with search/filter/pagination

**Event functions (9):**
- `EventPriceCreate`, `EventPriceOpen`, `EventPriceEdit`, `EventPriceSave`
- `EventPriceEnable`, `EventPriceDisable`
- `EventPriceDelete`, `EventPriceRestore`, `EventPriceDrop`

## REST Routes

Dispatcher: `rest.price(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/price/type` | List price types |
| `/price/method` | Get available methods |
| `/price/count` | Count with search/filter |
| `/price/set` | Upsert price |
| `/price/get` | Get by id with field selection |
| `/price/list` | List with search/filter/pagination |

## Workflow States / Methods / Transitions

**Types:** `one_off.price`, `recurring.price`

**States:** Uses `AddDefaultMethods` -- standard created/enabled/disabled/deleted lifecycle.

## Init / Seed Data

- `CreateEntityPrice(pParent)` -- registers entity, class, 2 types, events, methods
- `AddPriceEvents(pClass)` -- wires 9 event handlers
- Registers REST route: `price`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, indexes, 1 trigger |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | (empty) |
| `routine.sql` | yes | yes | 3 kernel functions |
| `api.sql` | yes | yes | 1 api view, 6 api functions |
| `rest.sql` | yes | yes | REST dispatcher (6 routes) |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
