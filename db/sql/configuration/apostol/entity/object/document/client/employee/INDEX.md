# employee

> Sub-class of `client` | Loaded by `client/create.psql` line 7

Employee sub-class of the client entity. Represents internal staff members. All event handlers require administrator role. Shares the same `db.client` table as the parent class but uses the `employee` class code for workflow differentiation.

## Dependencies

- `client` -- parent class; shares `db.client` table and inherits client behavior
- Platform: `document`, `object`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `api` | View `api.employee`; CRUD + list/count functions |
| `rest` | Dispatcher `rest.employee()` |

## Views

| View | Schema | Description |
|------|--------|-------------|
| `api.employee` | api | Exposes `ObjectClient` filtered by class `employee` |

## Functions

**api schema (6):**
- `api.add_employee` -- defaults to type `employee.employee`
- `api.update_employee` -- update employee
- `api.set_employee` -- upsert
- `api.get_employee` -- with access check
- `api.count_employee` -- count with search/filter
- `api.list_employee` -- list with search/filter/pagination

**Event functions (9):**
- `EventEmployeeCreate` -- requires administrator role
- `EventEmployeeOpen`, `EventEmployeeEdit`, `EventEmployeeSave`
- `EventEmployeeEnable`, `EventEmployeeDisable`
- `EventEmployeeDelete`, `EventEmployeeRestore`, `EventEmployeeDrop`

## REST Routes

Dispatcher: `rest.employee(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/employee/type` | List employee types |
| `/employee/method` | Get available methods for employee instance |
| `/employee/count` | Count with search/filter |
| `/employee/set` | Upsert employee |
| `/employee/get` | Get by id with field selection |
| `/employee/list` | List with search/filter/pagination |

## Workflow States / Methods / Transitions

**Types:** `employee.employee`, `accountant.employee`, `admin.employee`

**States (4):**
- `created` (created) -- initial state
- `enabled` (enabled) -- active employee
- `disabled` (disabled) -- suspended
- `deleted` (deleted) -- soft-deleted

**Key transitions:**
- created -> enabled (enable), deleted (delete)
- enabled -> disabled (disable)
- disabled -> enabled (enable), deleted (delete)
- deleted -> created (restore)

## Init / Seed Data

- `CreateClassEmployee(pParent, pEntity)` -- creates class with 3 types
- `AddEmployeeMethods(pClass)` -- defines standard state machine
- `AddEmployeeEvents(pClass)` -- wires 9 event handlers
- Registers REST route: `employee`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `api.sql` | yes | yes | 1 api view, 6 api functions |
| `rest.sql` | yes | yes | REST dispatcher (6 routes) |
| `event.sql` | yes | yes | 9 event handler functions (all require admin) |
| `init.sql` | yes | no | Class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except init.sql |
