# account

> Configuration entity -- document | Loaded by `document/create.psql` line 7

Financial account management for clients. Each account tracks a balance in a specific currency, with support for multiple account categories (active, passive, active-passive). Includes temporal balance tracking and turnover recording via the `balance/` sub-entity.

## Dependencies

- `client` -- each account is linked to a client
- `currency` -- each account has a denomination currency
- `category` -- optional reference-based categorization
- Platform: `document`, `object`, `aou` (access control), `reference`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `account`, triggers |
| `kernel` | Views `Account`, `AccessAccount`, `ObjectAccount`; routines |
| `api` | View `api.account`; CRUD + list/count/balance functions |
| `rest` | Dispatcher `rest.account()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.account` | id, document, currency, client, category, code | Client financial account with currency and optional category |

**Indexes:** document, currency, client, category, UNIQUE(currency, code)

**Triggers (3):**
- `t_account_before_insert` -- BEFORE INSERT: sets id from document, auto-generates code via `GenAccountCode()`
- `t_account_after_insert` -- AFTER INSERT: sets object owner to client's userId
- `t_account_after_update_client` -- AFTER UPDATE (client change): migrates AOUs from old to new client

## Sub-entities

| Directory | Description |
|-----------|-------------|
| `balance/` | Temporal balance tracking and turnover recording |

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Account` | kernel | Joins account with type, currency, category, client, balance |
| `AccessAccount` | kernel | ACL-filtered account access |
| `ObjectAccount` | kernel | Full object view with entity, class, owner, area, scope metadata |
| `api.account` | api | Exposes `ObjectAccount` |

## Functions

**kernel schema (9):**
- `CreateAccount(pParent, pType, pCurrency, pClient, pCategory, pCode, pLabel, pDescription)` -- creates account document
- `EditAccount(pId, ...)` -- updates account fields
- `GetAccount(pCurrency, pClient, pCategory)` -- lookup by currency+client+category
- `GetAccountCode(pAccount)` -- returns code
- `GenAccountCode(pAccount)` -- generates code as `acc_<next_sequence>`
- `GetClientAccount(pClient, pCurrency, pType, pCategory)` -- resolves account for client
- `GetAccountClient(pAccount)` -- returns client uuid
- `GetAccountJson(pClient)` -- returns accounts as JSON array
- `GetBalanceJsonb(pAccount)` -- returns balance as JSONB

**api schema (8):**
- `api.add_account` -- defaults to type `active.account`
- `api.update_account` -- lookup by id
- `api.set_account` -- upsert
- `api.get_account` -- with access check
- `api.count_account` -- non-admin scoped to current client
- `api.list_account` -- non-admin scoped to current client
- `api.get_account_id(pCurrency, pClient, pCategory)` -- resolves account id
- `api.get_account_balance(pAccount)` -- returns balance JSON

**Event functions (9):**
- `EventAccountCreate` -- auto-enables account
- `EventAccountOpen`, `EventAccountEdit`, `EventAccountSave`
- `EventAccountEnable`, `EventAccountDisable`
- `EventAccountDelete`, `EventAccountRestore`, `EventAccountDrop`

## REST Routes

Dispatcher: `rest.account(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/account/type` | List account types |
| `/account/method` | Get available methods for account instance |
| `/account/count` | Count with search/filter |
| `/account/set` | Upsert account |
| `/account/get` | Get by id with field selection |
| `/account/list` | List with search/filter/pagination |
| `/account/balance` | Get account balance |

## Workflow States / Methods / Transitions

**Types:** `active.account`, `passive.account`, `active-passive.account`

**States (4):**
- `created` (created) -- initial state
- `enabled` (enabled) -- active account
- `disabled` (disabled) -- suspended account
- `deleted` (deleted) -- soft-deleted

**Key transitions:**
- created -> enabled (enable), deleted (delete)
- enabled -> disabled (disable)
- disabled -> enabled (enable), deleted (delete)
- deleted -> created (restore)

## Init / Seed Data

- `CreateEntityAccount(pParent)` -- registers entity, class, types, events, methods, transitions
- `CreateClassAccount(pParent, pEntity)` -- creates class with 3 types
- `AddAccountEvents(pClass)` -- wires 9 event handlers
- Registers REST route: `account`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, indexes, 3 triggers |
| `balance/` | yes | yes | Sub-entity: balance and turnover tables |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | 5 exception functions |
| `routine.sql` | yes | yes | 9 kernel functions |
| `api.sql` | yes | yes | 1 api view, 8 api functions |
| `rest.sql` | yes | yes | REST dispatcher (7 routes) |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
