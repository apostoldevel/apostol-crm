# invoice

> Configuration entity -- document | Loaded by `document/create.psql` line 11

Invoice management for payment collection. Invoices are generated per device from accumulated transactions (`BuildInvoice`). Supports automatic payment processing with card cycling, retry logic, and configurable auto-payment behavior. Two invoice types: direct payment invoices and top-up invoices with distinct payment flows.

## Dependencies

- `client` -- invoiced client with ACL propagation
- `device` -- device generating billable transactions
- `currency` -- invoice currency
- `card` -- payment card for auto-payment
- `payment` -- created during invoice processing
- `order` -- created for service payment settlement
- Platform: `document`, `object`, `aou`, `transaction`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `invoice`, triggers |
| `kernel` | Views `Invoice`, `AccessInvoice`, `ObjectInvoice`; routines |
| `api` | View `api.invoice`; CRUD + list/count/check functions |
| `rest` | Dispatcher `rest.invoice()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.invoice` | id, document, currency, client, device, code, amount, pdf | Invoice with auto-generated code and PDF link |

**Indexes:** UNIQUE(code), document, currency, client, device

**Triggers (2):**
- `t_invoice_insert` -- BEFORE INSERT: sets id, generates code (`inv_*`), grants client ACL
- `t_invoice_update` -- AFTER UPDATE (client change): migrates ACL from old to new client

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Invoice` | kernel | Joins invoice with type, state, currency, client, device |
| `AccessInvoice` | kernel | ACL-filtered invoice access via entity-scoped AOU |
| `ObjectInvoice` | kernel | Full object view with priority, entity, class, owner, area, scope |
| `api.invoice` | api | Exposes `ObjectInvoice` |

## Functions

**kernel schema (6):**
- `CreateInvoice(pParent, pType, pCurrency, pClient, pDevice, pCode, pAmount, pPDF, pLabel, pDescription)` -- creates invoice document
- `EditInvoice(pId, ...)` -- updates invoice fields
- `GetInvoice(pCode)` -- lookup by code
- `GetInvoiceCode(pId)` -- returns code for given id
- `GetInvoiceAmount(pId)` -- returns amount for given id
- `BuildInvoice(pDevice)` -- aggregates active transactions per device into invoice, triggers payment

**api schema (7):**
- `api.add_invoice` -- defaults to type `top-up.invoice`
- `api.update_invoice` -- validates existence
- `api.set_invoice` -- upsert
- `api.get_invoice` -- with access check
- `api.count_invoice` -- non-admin scoped to current client
- `api.list_invoice` -- non-admin scoped to current client
- `api.check_invoice` -- background job: retries failed invoices, builds new invoices from unbilled transactions

**Event functions (10):**
- `EventInvoiceCreate`, `EventInvoiceOpen`, `EventInvoiceEdit`, `EventInvoiceSave`
- `EventInvoiceEnable` -- processes payment: tries cards in round-robin, creates payment order via payment system
- `EventInvoiceDisable` -- creates service payment order to settle balances
- `EventInvoiceCancel`, `EventInvoiceFail`
- `EventInvoiceDelete`, `EventInvoiceDrop`

## REST Routes

Dispatcher: `rest.invoice(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/invoice/type` | List invoice types |
| `/invoice/method` | Get available methods for invoice instance |
| `/invoice/count` | Count with search/filter |
| `/invoice/set` | Upsert invoice |
| `/invoice/get` | Get by id with field selection |
| `/invoice/list` | List with search/filter/pagination |

## Workflow States / Methods / Transitions

**Types:** `payment.invoice`, `top-up.invoice`

**States (6):**
- `created` (created) -- unpaid
- `in_progress` (enabled) -- payment in progress
- `failed` (enabled) -- payment failed
- `disabled` (disabled) -- paid
- `closed` (disabled) -- closed/settled
- `deleted` (deleted) -- soft deleted

**Key transitions:**
- created -> in_progress (enable), deleted (delete)
- in_progress -> disabled (disable), failed (fail), deleted (delete)
- failed -> in_progress (enable), created (cancel), deleted (delete)
- disabled -> closed (close), deleted (delete)
- closed -> deleted (delete)
- deleted -> created (restore)

## Init / Seed Data

- `CreateEntityInvoice(pParent)` -- registers entity, class, 2 types, events, methods, transitions
- `AddInvoiceMethods(pClass)` -- defines state machine with enable/disable/fail/close actions
- `AddInvoiceEvents(pClass)` -- wires 10 event handlers
- Registers REST route: `invoice`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, indexes, 2 triggers |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | 4 exception functions |
| `routine.sql` | yes | yes | 6 kernel functions |
| `api.sql` | yes | yes | 1 api view, 7 api functions |
| `rest.sql` | yes | yes | REST dispatcher (6 routes) |
| `event.sql` | yes | yes | 10 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
