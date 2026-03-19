# product

> Configuration entity -- document | Loaded by `document/create.psql` line 16

Product catalog management with Stripe-like semantics. Products serve as containers for prices and tariffs. When enabled, products auto-create/update tariffs from the tariff scheme. When disabled or dropped, associated tariffs and prices are cascaded through their own lifecycle states. Supports default price references, tax codes, and URL metadata.

## Dependencies

- `price` -- child prices belong to product
- `tariff` -- child tariffs created from tariff scheme on enable
- `service` -- tariff scheme references services
- `currency` -- tariff scheme references currencies
- Platform: `document`, `object`, `aou`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `product`, trigger |
| `kernel` | Views `Product`, `AccessProduct`, `ObjectProduct`; routines |
| `api` | View `api.product`; CRUD + list/count functions |
| `rest` | Dispatcher `rest.product()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.product` | id, document, code, name, default_price, tax_code, url, metadata | Product record with Stripe-style fields |

**Indexes:** UNIQUE(code), document

**Triggers (1):**
- `t_product_before_insert` -- BEFORE INSERT: sets id from document, generates code (`prod_*`)

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Product` | kernel | Joins product with type, state, timestamps |
| `AccessProduct` | kernel | ACL-filtered product access |
| `ObjectProduct` | kernel | Full object view with entity, class, owner, area, scope |
| `api.product` | api | Exposes `ObjectProduct` |

## Functions

**kernel schema (5):**
- `CreateProduct(pParent, pType, pCode, pName, pDefaultPrice, pTaxCode, pURL, pMetaData, pLabel, pDescription)` -- creates product document
- `EditProduct(pId, ...)` -- updates product fields
- `GetProduct(pCode)` -- lookup by code
- `GetProductCode(pId)` -- returns code for given id
- `GetProductPrice(pId)` -- returns default_price for given id

**api schema (6):**
- `api.add_product` -- defaults to type `service.product`
- `api.update_product` -- lookup by id or code
- `api.set_product` -- upsert by id or code
- `api.get_product` -- with access check
- `api.count_product` -- count with search/filter
- `api.list_product` -- list with search/filter/pagination (supports groupby)

**Event functions (9):**
- `EventProductCreate`, `EventProductOpen`, `EventProductEdit`, `EventProductSave`
- `EventProductEnable` -- enables child prices, creates/updates tariffs from tariff scheme
- `EventProductDisable` -- disables all associated tariffs
- `EventProductDelete`, `EventProductRestore`
- `EventProductDrop` -- cascades drop to all tariffs and prices

## REST Routes

Dispatcher: `rest.product(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/product/type` | List product types |
| `/product/method` | Get available methods |
| `/product/count` | Count with search/filter |
| `/product/set` | Upsert product |
| `/product/get` | Get by id with field selection |
| `/product/list` | List with search/filter/pagination (supports groupby) |

## Workflow States / Methods / Transitions

**Types:** `unknown.product`, `service.product`

**States:** Uses `AddDefaultMethods` -- standard created/enabled/disabled/deleted lifecycle.

## Init / Seed Data

- `CreateEntityProduct(pParent)` -- registers entity, class, 2 types, events, methods
- `AddProductEvents(pClass)` -- wires 9 event handlers
- Registers REST route: `product`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, indexes, 1 trigger |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | (empty) |
| `routine.sql` | yes | yes | 5 kernel functions |
| `api.sql` | yes | yes | 1 api view, 6 api functions |
| `rest.sql` | yes | yes | REST dispatcher (6 routes) |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
