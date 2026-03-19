# transaction

> Configuration entity -- document | Loaded by `document/create.psql` line 21

Service usage transaction records for billing. Each transaction links a client to a service with computed pricing from tariffs, tracking volume consumed, amounts due, commission, and tax. Transactions are created automatically from NTRIP station connection sessions (via `CreateTransactions`) and flow through processing to settlement or cancellation/refund.

## Dependencies

- `client` -- transaction owner with read ACL
- `service` -- service being billed (time.service, volume.service)
- `currency` -- billing currency
- `order` -- optional associated order
- `device` -- optional device that generated the usage
- `tariff` -- pricing tariff applied
- `subscription` -- optional active subscription
- `invoice` -- optional invoice for settlement
- `station_transaction` -- NTRIP session transaction reference
- Platform: `document`, `object`, `aou`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `transaction`; trigger |
| `kernel` | Views `Transaction`, `AccessTransaction`, `ObjectTransaction`; routines |
| `api` | View `api.transaction`; CRUD + list/count functions |
| `rest` | Dispatcher `rest.transaction()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.transaction` | id, document, client, service, currency, "order", device, tariff, subscription, invoice, transactionId, code, price, volume, amount, commission, tax | Billing transaction with 16 columns |

**Indexes (10):** document, client, service, currency, "order", device, tariff, subscription, invoice, transactionId

**Triggers (1):**
- `t_transaction_insert` -- BEFORE INSERT: sets id, generates code (`tx_*`), grants client read ACL

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Transaction` | kernel | Joins with client, service, currency, order, device, tariff, subscription, invoice |
| `AccessTransaction` | kernel | ACL-filtered transaction access |
| `ObjectTransaction` | kernel | Full object view including subscription/invoice state codes |
| `api.transaction` | api | Exposes `ObjectTransaction` |

## Functions

**kernel schema (10):**
- `CreateTransaction(pParent, pType, pClient, pService, pCurrency, pOrder, pDevice, pTariff, pSubscription, pInvoice, pTransactionId, pPrice, pVolume, pAmount, pCommission, pTax, pCode, pLabel, pDescription)` -- creates transaction with extensive FK validation
- `EditTransaction(pId, ...)` -- updates with code uniqueness check
- `GetTransaction(pCode)` -- lookup by code
- `GetTransaction(pTransactionId, pService, pStateType)` -- lookup by station transaction + service + state (overloaded)
- `GetTransactionSum(pTransactionId, pService, pStateType)` -- sum amounts for station transaction
- `GetTransactionVolume(pTransactionId, pService, pStateType)` -- sum volumes for station transaction
- `CreateServiceTransaction(pTransactionId, pService, pDevice, pClient, pCurrency, pVolume, pTag)` -- high-level: resolves tariff from subscription/product, calculates amount with commission/tax, creates or updates transaction
- `CreateTransactions(pTransactionId)` -- creates time + volume service transactions from a station_transaction session
- `CloseTransactions(pDevice)` -- disables all enabled transactions for a device
- `CancelTransactions(pDevice)` -- cancels all enabled transactions for a device
- `GetTransactionsAmount(pOrder, pService)` -- sum amounts for an order+service (disabled state)

**api schema (6):**
- `api.add_transaction` -- defaults to type `service.transaction`
- `api.update_transaction` -- validates existence
- `api.set_transaction` -- upsert
- `api.get_transaction` -- single record
- `api.count_transaction` -- non-admin scoped to current client
- `api.list_transaction` -- non-admin scoped to current client, supports groupby

**Event functions (10):**
- `EventTransactionCreate` -- auto-enables transaction
- `EventTransactionOpen`, `EventTransactionEdit`, `EventTransactionSave`, `EventTransactionEnable`
- `EventTransactionDisable` -- triggers `TransactionPayment()` to process settlement
- `EventTransactionCancel` -- cascades cancel to child orders
- `EventTransactionRefund` -- cascades refund to child orders (disabled state)
- `EventTransactionDelete` -- cascades delete to child orders
- `EventTransactionRestore`, `EventTransactionDrop`

## REST Routes

Dispatcher: `rest.transaction(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/transaction/type` | List transaction types |
| `/transaction/method` | Get available methods |
| `/transaction/set` | Upsert transaction |
| `/transaction/get` | Get by id with field selection |
| `/transaction/count` | Count with search/filter |
| `/transaction/list` | List with search/filter/pagination/groupby |

## Workflow States / Methods / Transitions

**Types:** `service.transaction`

**States (5):**
- `created` -- newly created
- `processing` (enabled) -- being processed
- `succeeded` (disabled) -- completed and settled
- `refunded` (deleted) -- refunded
- `canceled` (deleted) -- canceled
- `deleted` -- soft deleted

**Key transitions:**
- created -> processing (enable), deleted (delete)
- processing -> succeeded (disable), canceled (cancel), deleted (delete)
- succeeded -> refunded (refund), deleted (delete)
- deleted/refunded/canceled -> created (restore)

## Exceptions

| Function | Description |
|----------|-------------|
| `TransactionCodeExists(pCode)` | Raised when duplicate transaction code |
| `TariffNotFound(pService, pCurrency, pTag)` | Raised when no tariff matches service+currency+tag |

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, 10 indexes, 1 trigger |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | 2 exception functions |
| `routine.sql` | yes | yes | 11 kernel functions |
| `api.sql` | yes | yes | 1 api view, 6 api functions |
| `rest.sql` | yes | yes | REST dispatcher (6 routes) |
| `event.sql` | yes | yes | 10 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
