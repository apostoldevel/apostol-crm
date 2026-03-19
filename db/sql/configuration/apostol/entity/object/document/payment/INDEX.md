# payment

> Configuration entity -- document | Loaded by `document/create.psql` line 15

Payment processing hub integrating with external payment systems (YooKassa, CloudPayments). Manages the full payment lifecycle: creation, submission, confirmation, cancellation, and refund. Includes reservation management for pre-authorized payments, crediting logic for internal account transfers, and background stale-payment cleanup. Child classes (`yookassa`, `cloudpayments`) implement provider-specific workflows.

## Dependencies

- `client` -- payer with ACL propagation
- `currency` -- payment currency (defaults to `DefaultCurrency()`)
- `card` -- payment card (optional, required for invoice payments)
- `invoice` -- associated invoice (required for `invoice.payment` type)
- `order` -- associated financial order (created during crediting)
- Platform: `document`, `object`, `aou`, `registry`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `payment`, triggers |
| `kernel` | Views `Payment`, `AccessPayment`, `ObjectPayment`; routines |
| `api` | View `api.payment`; CRUD + list/count/check functions |
| `rest` | Dispatcher `rest.payment()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.payment` | id, document, currency, client, card, invoice, order, code, amount, payment_id, metadata | Payment record with external payment system ID and metadata |

**Indexes:** UNIQUE(code), UNIQUE(payment_id), document, currency, client, card, invoice, order

**Triggers (2):**
- `t_payment_before_insert` -- BEFORE INSERT: sets id, generates code (`pay_*`), grants client read ACL
- `t_payment_after_insert` -- AFTER INSERT: grants client read ACL (redundant safety)

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Payment` | kernel | Joins payment with type, state, currency, client, card, invoice, order |
| `AccessPayment` | kernel | ACL-filtered payment access via entity-scoped AOU |
| `ObjectPayment` | kernel | Full object view with invoice/order state, priority, entity, class, owner, area, scope |
| `api.payment` | api | Exposes `ObjectPayment` |

## Functions

**kernel schema (16):**
- `CreatePayment(pParent, pType, pClient, pCurrency, pAmount, pDescription, pCard, pInvoice, pOrder, pCode, pPaymentId, pMetadata)` -- creates payment with validation
- `EditPayment(pId, ...)` -- updates payment fields
- `GetPayment(pCode)` -- lookup by code
- `GetPaymentCode(pId)` -- returns code for given id
- `GetPaymentAmount(pId)` -- returns amount for given id
- `CreateValidationPayment(pCard, pDescription)` -- creates 1-unit validation payment for card binding
- `CreateNoPaymentOrder(pCard, pDescription)` -- creates 0-amount card payment for binding without charge
- `CreatePaymentOrder(pCard, pAmount, pInvoice, pDescription)` -- creates card payment for invoice
- `CreditingPayment(pPayment)` -- transfers funds from company to client account via internal order
- `ZeroPayment(pClient, pCurrency, pLabel, pDescription)` -- zeroes client balance by transferring to company
- `GetPaymentReservationSum(pClient, pCard)` -- sums reserved (waiting_for_capture) payments
- `GetPaymentPaidSum(pInvoice)` -- sums succeeded payments for invoice
- `ConfirmPaymentReservation(pClient, pCard, pInvoice, pAmount, pDescription)` -- confirms reserved payments up to amount
- `CancelPaymentReservation(pClient)` -- cancels all uninvoiced reserved payments
- `UpdatePaymentReservationData(pClient, pCard, pMetaData)` -- updates metadata on reserved payments
- `CheckPaymentReservation(pConnector)` -- cancels stale reservations for disconnected connectors

**api schema (7):**
- `api.add_payment` -- defaults type from registry `PaymentSystem` config
- `api.update_payment` -- lookup by id or code
- `api.set_payment` -- upsert
- `api.get_payment` -- with access check
- `api.count_payment` -- non-admin scoped to current client
- `api.list_payment` -- non-admin scoped to current client
- `api.check_payment(pOffTime)` -- cancels stale waiting_for_capture payments older than offset (default 2 min)

**Event functions (9):**
- `EventPaymentCreate`, `EventPaymentOpen`, `EventPaymentEdit`, `EventPaymentSave`
- `EventPaymentEnable`, `EventPaymentDisable`
- `EventPaymentCancel`, `EventPaymentReturn`
- `EventPaymentDelete`, `EventPaymentRestore`, `EventPaymentDrop`

## REST Routes

Dispatcher: `rest.payment(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/payment/type` | List payment types |
| `/payment/method` | Get available methods for payment instance |
| `/payment/count` | Count with search/filter |
| `/payment/set` | Upsert payment |
| `/payment/get` | Get by id with field selection |
| `/payment/list` | List with search/filter/pagination |

## Workflow States / Methods / Transitions

**Types:** `reserve.payment`, `invoice.payment`, `validation.payment`, `card.payment`

**States (4):**
- `created` (created) -- new payment
- `enabled` (enabled) -- submitted to payment system
- `disabled` (disabled) -- processed/completed
- `deleted` (deleted) -- soft deleted

**Key transitions:**
- created -> enabled (enable), disabled (disable), deleted (delete)
- enabled -> created (cancel), disabled (disable), deleted (delete)
- disabled -> created (cancel), deleted (return/delete)
- deleted -> created (restore)

## Sub-entities

- `cloudpayments/` -- CloudPayments provider integration (loaded at `payment/create.psql` line 22)
- `yookassa/` -- YooKassa provider integration (loaded at `payment/create.psql` line 23)

## Init / Seed Data

- `CreateEntityPayment(pParent)` -- registers entity, class, 4 types, events, methods, transitions; chains to `CreateClassYooKassa` and `CreateClassCloudPayments`
- `AddPaymentMethods(pClass)` -- defines state machine with enable/disable/cancel/return actions
- `AddPaymentEvents(pClass)` -- wires 11 event handlers (including cancel/return with state change)
- Registers REST route: `payment`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, indexes, 2 triggers |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | 2 exception functions |
| `routine.sql` | yes | yes | 16 kernel functions |
| `api.sql` | yes | yes | 1 api view, 7 api functions |
| `rest.sql` | yes | yes | REST dispatcher (6 routes) |
| `event.sql` | yes | yes | 9 event handler functions |
| `cloudpayments/` | yes | yes | CloudPayments sub-entity (see cloudpayments/INDEX.md) |
| `yookassa/` | yes | yes | YooKassa sub-entity (see yookassa/INDEX.md) |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files + sub-entities + init |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
