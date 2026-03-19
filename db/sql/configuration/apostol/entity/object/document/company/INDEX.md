# company

> Configuration entity -- document | Loaded by `document/create.psql` line 4

Hierarchical company management with tree structure (root/node/level). Supports organizational hierarchies with parent-child relationships. On creation, automatically creates a corresponding `company.client` record. Redefines some client exception functions for company context.

## Dependencies

- `client` -- company creation auto-creates a client record
- Platform: `document`, `object`, `aou` (access control)

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `company`, triggers |
| `kernel` | Views `Company`, `AccessCompany`, `ObjectCompany`; routines |
| `api` | View `api.company`; CRUD + list/count functions |
| `rest` | Dispatcher `rest.company()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.company` | id, document, root, node, code, level, sequence | Hierarchical company record with tree structure |

**Indexes:** root, node, code, UNIQUE(code)

**Triggers (1):**
- `t_company_insert` -- BEFORE INSERT: sets id from document, auto-generates code

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Company` | kernel | Joins company with type, state metadata |
| `AccessCompany` | kernel | ACL-filtered company access |
| `ObjectCompany` | kernel | Full object view with entity, class, owner, area, scope metadata |
| `api.company` | api | Exposes `ObjectCompany` |

## Functions

**kernel schema (8):**
- `CreateCompany(pParent, pType, pCode, pName, pDescription)` -- creates company document
- `EditCompany(pId, ...)` -- updates company fields
- `GetCompany(pCode)` -- lookup by code
- `GetCompanyCode(pCompany)` -- returns code
- `GetCompanyName(pCompany)` -- returns company name from object_text
- `SetCompanySequence(pCompany, pSequence, pDate)` -- sets display order
- `SortCompany()` -- reorders all companies
- `current_company()` -- returns company of current client

**api schema (6):**
- `api.add_company` -- defaults to type `main.company`
- `api.update_company` -- update company
- `api.set_company` -- upsert
- `api.get_company` -- with access check
- `api.count_company` -- count with search/filter
- `api.list_company` -- list with search/filter/pagination

**Event functions (9):**
- `EventCompanyCreate` -- auto-creates a `company.client` for the company
- `EventCompanyOpen`, `EventCompanyEdit`, `EventCompanySave`
- `EventCompanyEnable`, `EventCompanyDisable`
- `EventCompanyDelete`, `EventCompanyRestore`, `EventCompanyDrop`

**Exception functions (4):**
- `ClientCodeExists` -- redefines client exception for company context
- `AccountNotClient` -- redefines client exception
- `EmailAddressNotSet` -- redefines client exception
- `EmailAddressNotVerified` -- redefines client exception

## REST Routes

Dispatcher: `rest.company(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/company/type` | List company types |
| `/company/method` | Get available methods for company instance |
| `/company/set` | Upsert company |
| `/company/get` | Get by id with field selection |
| `/company/count` | Count with search/filter |
| `/company/list` | List with search/filter/pagination |

## Workflow States / Methods / Transitions

**Types:** `all.company`, `main.company`, `subsidiary.company`, `mobile.company`

**States (4):**
- `created` (created) -- initial state
- `enabled` (enabled) -- active company
- `disabled` (disabled) -- suspended
- `deleted` (deleted) -- soft-deleted

**Key transitions:**
- created -> enabled (enable), deleted (delete)
- enabled -> disabled (disable)
- disabled -> enabled (enable), deleted (delete)
- deleted -> created (restore)

## Init / Seed Data

- `CreateEntityCompany(pParent)` -- registers entity, class, types, events, methods, transitions
- `CreateClassCompany(pParent, pEntity)` -- creates class with 4 types
- `AddCompanyEvents(pClass)` -- wires 9 event handlers
- Registers REST route: `company`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, indexes, 1 trigger |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | 4 exception functions (redefines client exceptions) |
| `routine.sql` | yes | yes | 8 kernel functions |
| `api.sql` | yes | yes | 1 api view, 6 api functions |
| `rest.sql` | yes | yes | REST dispatcher (6 routes) |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
