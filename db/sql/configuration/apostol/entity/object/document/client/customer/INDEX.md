# customer

> Sub-class of `client` | Loaded by `client/create.psql` line 8

Customer sub-class of the client entity. Represents external paying customers. On creation, automatically creates three financial accounts (technical, main, service) for billing purposes. Shares the same `db.client` table as the parent class.

## Dependencies

- `client` -- parent class; shares `db.client` table and inherits client behavior
- `account` -- auto-creates accounts on customer creation
- `category` -- account categories (tech, main, service)
- `currency` -- accounts denominated in RUB
- Platform: `document`, `object`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `api` | View `api.customer`; CRUD + list/count functions |
| `rest` | Dispatcher `rest.customer()` |

## Views

| View | Schema | Description |
|------|--------|-------------|
| `api.customer` | api | Exposes `ObjectClient` filtered by class `customer` |

## Functions

**api schema (6):**
- `api.add_customer` -- defaults to type `person.customer`
- `api.update_customer` -- update customer
- `api.set_customer` -- upsert
- `api.get_customer` -- with access check
- `api.count_customer` -- non-admin scoped to current client
- `api.list_customer` -- non-admin scoped to current client

**Event functions (9):**
- `EventCustomerCreate` -- auto-creates 3 accounts (tech/main/service in RUB)
- `EventCustomerOpen`, `EventCustomerEdit`, `EventCustomerSave`
- `EventCustomerEnable`, `EventCustomerDisable`
- `EventCustomerDelete`, `EventCustomerRestore`, `EventCustomerDrop`

## REST Routes

Dispatcher: `rest.customer(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/customer/type` | List customer types |
| `/customer/method` | Get available methods for customer instance |
| `/customer/count` | Count with search/filter |
| `/customer/set` | Upsert customer |
| `/customer/get` | Get by id with field selection |
| `/customer/list` | List with search/filter/pagination |

## Workflow States / Methods / Transitions

**Types:** `person.customer`, `individual.customer`, `organization.customer`

**States (4):**
- `created` (created) -- initial state
- `enabled` (enabled) -- active customer
- `disabled` (disabled) -- suspended
- `deleted` (deleted) -- soft-deleted

**Key transitions:**
- created -> enabled (enable), deleted (delete)
- enabled -> disabled (disable)
- disabled -> enabled (enable), deleted (delete)
- deleted -> created (restore)

## Init / Seed Data

- `CreateClassCustomer(pParent, pEntity)` -- creates class with 3 types
- `AddCustomerMethods(pClass)` -- defines standard state machine
- `AddCustomerEvents(pClass)` -- wires 9 event handlers
- Registers REST route: `customer`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `api.sql` | yes | yes | 1 api view, 6 api functions |
| `rest.sql` | yes | yes | REST dispatcher (6 routes) |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except init.sql |
