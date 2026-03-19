# order

> Configuration entity -- document | Loaded by `document/create.psql` line 14

Financial order (money transfer) management between client accounts. Each order debits one account and credits another, with amount validation enforced by triggers. Provides internal payment, transaction-based payment, and service payment workflows for billing settlement. The event handlers manage balance debit/credit processing on state transitions.

## Dependencies

- `account` -- debit and credit accounts
- `client` -- resolved through accounts, ACL propagation for both debit/credit clients
- `currency` -- order currency (must match both accounts)
- Platform: `document`, `object`, `aou`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `order`, triggers |
| `kernel` | Views `"Order"`, `AccessOrder`, `ObjectOrder`; routines |
| `api` | View `api.order`; CRUD + list/count functions |
| `rest` | Dispatcher `rest.order()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.order` | id, document, currency, debit, credit, amount, code | Financial order with debit/credit account pair |

**Indexes:** UNIQUE(code), document, debit, credit, currency

**Triggers (3):**
- `t_order_before_insert` -- BEFORE INSERT: sets id, generates code (`ord_*`), validates amount > 0, grants ACL to both debit/credit clients
- `t_order_after_insert` -- AFTER INSERT: grants ACL to both debit/credit clients (post-insert)
- `t_order_before_update` -- BEFORE UPDATE: validates amount > 0

## Views

| View | Schema | Description |
|------|--------|-------------|
| `"Order"` | kernel | Joins order with type, state, currency, debit/credit accounts and clients |
| `AccessOrder` | kernel | ACL-filtered order access via entity-scoped AOU |
| `ObjectOrder` | kernel | Full object view with entity, class, priority, owner, area, scope |
| `api.order` | api | Exposes `ObjectOrder` |

## Functions

**kernel schema (8):**
- `CreateOrder(pParent, pType, pCurrency, pDebit, pCredit, pAmount, pCode, pLabel, pDescription)` -- creates order with currency/account validation
- `EditOrder(pId, ...)` -- updates order fields
- `GetOrder(pCode)` -- lookup by code
- `GetOrderCode(pId)` -- returns code for given id
- `GetOrderAmount(pId)` -- returns amount for given id
- `InternalPayment(pParent, pDebit, pCredit, pAmount, pLabel, pDescription)` -- creates memo.order between two accounts
- `TransactionPayment(pParent, pDebit, pCredit, pAmount, pLabel, pDescription)` -- creates memo.order with transaction parent
- `ServicePayment(pParent, pClient, pCurrency, pAmount, pLabel, pDescription)` -- creates order debiting client `000` account to company `000` account

**api schema (6):**
- `api.add_order` -- defaults to type `memo.order`
- `api.update_order` -- validates existence
- `api.set_order` -- upsert
- `api.get_order` -- with access check
- `api.count_order` -- non-admin scoped to current client
- `api.list_order` -- non-admin scoped to current client

**Event functions (9):**
- `EventOrderCreate`, `EventOrderOpen`, `EventOrderEdit`, `EventOrderSave`
- `EventOrderEnable` -- debits source account, credits destination account
- `EventOrderDisable` -- settles: debit balance from source, credit balance to destination
- `EventOrderCancel` -- reverses: credit back to source, debit back from destination
- `EventOrderRefund` -- full reversal of enable+disable operations
- `EventOrderDrop`

## REST Routes

Dispatcher: `rest.order(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/order/type` | List order types |
| `/order/method` | Get available methods for order instance |
| `/order/count` | Count with search/filter |
| `/order/set` | Upsert order |
| `/order/get` | Get by id with field selection |
| `/order/list` | List with search/filter/pagination |

## Workflow States / Methods / Transitions

**Types:** `memo.order`

**States (6):**
- `created` (created) -- new order
- `processing` (enabled) -- funds reserved
- `succeeded` (disabled) -- completed
- `deleted` (deleted) -- soft deleted
- `refunded` (deleted) -- fully reversed
- `canceled` (deleted) -- canceled before completion

**Key transitions:**
- created -> processing (enable), deleted (delete)
- processing -> succeeded (disable), canceled (cancel), deleted (delete)
- succeeded -> refunded (refund), deleted (delete)
- deleted -> created (restore)
- refunded -> created (restore)
- canceled -> created (restore)

## Init / Seed Data

- `CreateEntityOrder(pParent)` -- registers entity, class, type, events, methods, transitions
- `AddOrderMethods(pClass)` -- defines state machine with enable/disable/cancel/refund actions
- `AddOrderEvents(pClass)` -- wires 9 event handlers
- English state labels via `EditStateText`
- Registers REST route: `order`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, indexes, 3 triggers |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | 4 exception functions |
| `routine.sql` | yes | yes | 8 kernel functions |
| `api.sql` | yes | yes | 1 api view, 6 api functions |
| `rest.sql` | yes | yes | REST dispatcher (6 routes) |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
