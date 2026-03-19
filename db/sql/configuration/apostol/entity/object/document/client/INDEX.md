# client

> Configuration entity -- document | Loaded by `document/create.psql` line 5

Core client entity representing customers and employees. Stores personal/business data (phone, email, passport, INN, OGRN, BIC, bank account), photo, and metadata. Features email confirmation workflow, user account management with group/area/interface provisioning, and locale-aware temporal client names. Parent class for `employee/` and `customer/` sub-classes.

## Dependencies

- `company` -- each client references a company
- `identity` -- client creation may auto-create identity documents
- `address` -- client creation may auto-create address records
- Platform: `document`, `object`, `aou` (access control), `user`, `session`, `oauth2`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Tables `client`, `client_name`, triggers |
| `kernel` | Views `Client`, `AccessClient`, `ObjectClient`; routines |
| `api` | View `api.client`; CRUD + list/count/close/balance functions |
| `rest` | Dispatcher `rest.client()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.client` | id, document, company, userid, code, phone, email, info, birthday, passportser, passportnum, passportdate, passportcode, passportissuer, inn, pin, kpp, ogrn, bic, account, address, photo, metadata | Client record with personal/business data |

**Indexes:** company, userid, code, UNIQUE(code)

**Triggers (2):**
- `t_client_insert` -- BEFORE INSERT: sets id, auto-generates code, grants client read/write ACL
- `t_client_update` -- BEFORE UPDATE: validates write access

## Sub-entities

| Directory | Description |
|-----------|-------------|
| `name/` | Temporal locale-aware client name records |
| `employee/` | Employee sub-class of client |
| `customer/` | Customer sub-class of client |

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Client` | kernel | Joins client with type, state, company, user profile |
| `AccessClient` | kernel | ACL-filtered client access |
| `ObjectClient` | kernel | Full object view with entity, class, owner, area, scope metadata |
| `api.client` | api | Exposes `ObjectClient` filtered by class `client` |

## Functions

**kernel schema (10):**
- `CreateClient(pParent, pType, pCompany, pUserId, pCode, pName, pPhone, pEmail, ...)` -- creates client with optional address/identity
- `EditClient(pId, ...)` -- updates client fields and name
- `GetClient(pCode)` -- lookup by code
- `GetClientCode(pClient)` -- returns code
- `GetClientCompany(pClient)` -- returns company uuid
- `GetClientUserId(pClient)` -- returns userId
- `GetClientByUserId(pUserId)` -- reverse lookup
- `BuildClientName(pSurname, pGivenName, pPatronymic)` -- constructs full name from parts
- `current_client()` -- returns client for current user session
- `SendPushAll(pMessage)` -- sends push notifications to all active clients

**api schema (8):**
- `api.add_client` -- defaults to type `company.client`
- `api.update_client` -- update client
- `api.set_client` -- upsert
- `api.get_client` -- with access check
- `api.count_client` -- non-admin scoped to current client
- `api.list_client` -- non-admin scoped to current client
- `api.close_client(pId)` -- session logout + disable + delete + drop cascade
- `api.get_client_balance(pId)` -- returns all account balances as JSON

**Event functions (11):**
- `EventClientCreate`, `EventClientOpen`
- `EventClientEdit` -- triggers email reconfirmation on email change
- `EventClientSave`
- `EventClientEnable` -- unlocks user, assigns groups/areas/interfaces, enables accounts
- `EventClientDisable` -- locks user, revokes permissions, disables accounts
- `EventClientDelete` -- deletes user account, randomizes code
- `EventClientRestore`, `EventClientDrop`
- `EventClientConfirm` -- verifies email is set and confirmed
- `EventClientReconfirm` -- resets email verification, sends confirmation

**Exception functions (8):**
- `ClientCodeExists`, `AccountNotClient`, `EmailAddressNotSet`, `EmailAddressNotVerified`
- `PhoneNumberNotSet`, `PhoneNumberNotVerified`, `InvalidClientId`, `IncorrectDateValue`

**Report functions (2):**
- `report.rfc_client_list` -- report form definition
- `report.rpc_client_list` -- HTML report generation

## REST Routes

Dispatcher: `rest.client(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/client/type` | List client types |
| `/client/method` | Get available methods for client instance |
| `/client/set` | Upsert client |
| `/client/get` | Get by id with field selection |
| `/client/count` | Count with search/filter |
| `/client/list` | List with search/filter/pagination |
| `/client/close` | Close client (cascade disable/delete/drop) |
| `/client/balance` | Get client account balances |

## Workflow States / Methods / Transitions

**Types:** `company.client`

**States (4 + custom):**
- `created` (created) -- initial state; has submit, delete methods
- `confirmed` (enabled) -- email confirmed; has reconfirm, disable methods
- `disabled` (disabled) -- suspended
- `deleted` (deleted) -- soft-deleted

**Custom methods:**
- `submit` -- submits for confirmation
- `confirm` -- confirms client (created -> confirmed)
- `reconfirm` -- re-initiates email confirmation

**Key transitions:**
- created -> confirmed (confirm), enabled (enable), deleted (delete)
- enabled/confirmed -> disabled (disable)
- disabled -> enabled (enable), deleted (delete)
- deleted -> created (restore)

## Init / Seed Data

- `CreateEntityClient(pParent)` -- registers entity, class, types, events, methods, transitions; also creates employee/customer sub-classes
- `CreateClassClient(pParent, pEntity)` -- creates class with 1 type
- `AddClientMethods(pClass)` -- defines custom workflow with submit/confirm/reconfirm
- `AddClientEvents(pClass)` -- wires 11+ event handlers
- Registers REST route: `client`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, indexes, 2 triggers |
| `name/` | yes | yes | Sub-entity: temporal client names |
| `employee/` | yes | yes | Sub-entity: employee sub-class |
| `customer/` | yes | yes | Sub-entity: customer sub-class |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | 8 exception functions |
| `routine.sql` | yes | yes | 10 kernel functions |
| `api.sql` | yes | yes | 1 api view, 8 api functions |
| `rest.sql` | yes | yes | REST dispatcher (8 routes) |
| `event.sql` | yes | yes | 11 event handler functions |
| `report.sql` | yes | yes | 2 report functions |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
