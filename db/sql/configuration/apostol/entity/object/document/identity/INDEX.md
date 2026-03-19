# identity

> Configuration entity -- document | Loaded by `document/create.psql` line 10

Identity document management for clients (passports, driver licenses, tax IDs, bank details). Each identity has a series/number pair forming a generated `identity` column. Supports validity periods, reminder dates, and photo storage. Identity types cover Russian government and financial identifiers (passport, INN, SNILS, KPP, OGRN, BIC, bank accounts).

## Dependencies

- `client` -- each identity belongs to a client
- `country` -- citizenship/issuing country (defaults to Russia, code 643)
- Platform: `document`, `object`, `type`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `identity`, trigger |
| `kernel` | Views `Identity`, `AccessIdentity`, `ObjectIdentity`; routines |
| `api` | View `api.identity`; CRUD + list/count functions |
| `rest` | Dispatcher `rest.identity()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.identity` | id, document, type, country, client, series, number, identity (generated), code, issued, date, photo, reminderDate, validFromDate, validToDate | Identity document with generated series+number composite |

**Indexes:** UNIQUE(type, identity), UNIQUE(type, client, validFromDate, validToDate), document, type, country, client, identity

**Triggers (1):**
- `t_identity_insert` -- BEFORE INSERT: sets id from document, derives type from object, copies issue date to validFromDate

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Identity` | kernel | Joins identity with type, country, client name |
| `AccessIdentity` | kernel | ACL-filtered identity access via entity-scoped AOU |
| `ObjectIdentity` | kernel | Full object view with entity, class, state, owner, area, scope |
| `api.identity` | api | Exposes `ObjectIdentity` |

## Functions

**kernel schema (5):**
- `CreateIdentity(pParent, pType, pCountry, pClient, pSeries, pNumber, pCode, pIssued, pDate, pPhoto, pReminderDate, pValidFromDate, pValidToDate)` -- creates identity document, auto-computes reminder date 60 days before expiry
- `EditIdentity(pId, ...)` -- updates identity fields with duplicate check
- `SetIdentity(pId, ...)` -- upsert by id or type+series+number
- `GetIdentity(pType, pClient)` -- returns identity string for active identity
- `GetIdentityId(pType, pClient)` -- returns id for active identity

**api schema (6):**
- `api.add_identity` -- creates identity
- `api.update_identity` -- validates existence
- `api.set_identity` -- upsert
- `api.get_identity` -- with access check
- `api.count_identity` -- count with search/filter
- `api.list_identity` -- list with search/filter/pagination

**Event functions (12):**
- `EventIdentityCreate` -- auto-enables after creation
- `EventIdentityOpen`, `EventIdentityEdit`, `EventIdentitySave`
- `EventIdentityEnable`, `EventIdentityDisable`
- `EventIdentityCheck`, `EventIdentityExpire`, `EventIdentityReturn`
- `EventIdentityDelete`, `EventIdentityRestore`, `EventIdentityDrop`

## REST Routes

Dispatcher: `rest.identity(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/identity/type` | List identity types |
| `/identity/method` | Get available methods for identity instance |
| `/identity/count` | Count with search/filter |
| `/identity/set` | Upsert identity |
| `/identity/get` | Get by id with field selection |
| `/identity/list` | List with search/filter/pagination |

## Workflow States / Methods / Transitions

**Types:** `passport.identity`, `driver.identity`, `inn.identity`, `pin.identity`, `kpp.identity`, `ogrn.identity`, `ogrnip.identity`, `account.identity`, `cor-account.identity`, `bic.identity`

**States (5):**
- `created` (created) -- newly added
- `enabled` (enabled) -- currently valid
- `expired` (enabled) -- validity period passed
- `disabled` (disabled) -- archived
- `deleted` (deleted) -- soft deleted

**Key transitions:**
- created -> enabled (enable), disabled (disable), deleted (delete)
- enabled -> expired (expire), disabled (disable), deleted (delete)
- expired -> enabled (enable), disabled (disable), deleted (delete)
- disabled -> created (return), deleted (delete)
- deleted -> created (restore)

## Init / Seed Data

- `CreateEntityIdentity(pParent)` -- registers entity, class, 10 types, events, methods, transitions
- `AddIdentityMethods(pClass)` -- defines state machine with check/expire/return actions
- `AddIdentityEvents(pClass)` -- wires 12 event handlers
- Registers REST route: `identity`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, indexes, 1 trigger |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | 3 exception functions |
| `routine.sql` | yes | yes | 5 kernel functions |
| `api.sql` | yes | yes | 1 api view, 6 api functions |
| `rest.sql` | yes | yes | REST dispatcher (6 routes) |
| `event.sql` | yes | yes | 12 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
