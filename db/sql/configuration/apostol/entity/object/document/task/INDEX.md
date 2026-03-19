# task

> Configuration entity -- document | Loaded by `document/create.psql` line 20

Task management with calendar-aware deadline calculation. Tasks are assigned to an executor (client), have priority levels, and automatically compute due dates based on working hours from a calendar reference. Background `CheckTask` function transitions tasks between planned/enabled/expired states.

## Dependencies

- `calendar` -- working hours schedule for deadline computation
- `client` -- task executor with ACL propagation
- `priority` -- document priority level
- Platform: `document`, `object`, `aou`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `task`; triggers |
| `kernel` | Views `Task`, `AccessTask`, `ObjectTask`; routines |
| `api` | View `api.task`; CRUD + list/count/check functions |
| `rest` | Dispatcher `rest.task()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.task` | id, document, calendar, executor, read, period, validFromDate, validToDate | Task with calendar-based scheduling |

**Indexes:** document, calendar, executor

**Triggers (3):**
- `t_task_insert` -- BEFORE INSERT: sets id, grants executor ACL, computes validToDate from calendar
- `t_task_before_update` -- BEFORE UPDATE: recalculates dates when period/fromDate/calendar change
- `t_task_after_update` -- AFTER UPDATE: migrates ACL when executor changes

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Task` | kernel | Basic task view with calendar and executor names |
| `AccessTask` | kernel | ACL-filtered task access |
| `ObjectTask` | kernel | Full object view with priority, entity, class, owner, area, scope |
| `api.task` | api | Extends ObjectTask with parent binding JSON data |

## Functions

**kernel schema (5):**
- `CreateTask(pParent, pType, pCalendar, pExecutor, pLabel, pRead, pPeriod, pDateFrom, pDateTo, pDescription, pPriority, pData)` -- creates task document
- `EditTask(pId, ...)` -- updates task, passes old/new record to method for change tracking
- `GetTaskValidToDate(pCalendar, pDateFrom, pPeriod, pUserId)` -- calculates due date by iterating working days
- `GetTaskPeriod(pCalendar, pDateFrom, pDateTo, pUserId)` -- reverse-calculates working period from date range
- `CheckTask()` -- background job: expires overdue enabled tasks, enables planned/postponed tasks whose start date has arrived

**api schema (8):**
- `api.task(pState, pDateFrom)` -- filter tasks by state and date
- `api.add_task` -- defaults calendar to `default.calendar`, period to 8 hours, type to `user.task`
- `api.update_task` -- validates task exists
- `api.set_task` -- upsert
- `api.get_task` -- with access check
- `api.count_task` -- non-admin scoped to current executor
- `api.list_task` -- non-admin scoped to current executor
- `api.check_task` -- safe wrapper for `CheckTask()` with error handling

**Event functions (12):**
- `EventTaskCreate` -- auto-routes to enable/postpone/plan based on date range
- `EventTaskEdit` -- stores parent object data as JSON binding
- `EventTaskSave`
- `EventTaskEnable` -- accepts period/date params, updates task dates
- `EventTaskDisable`, `EventTaskDelete`, `EventTaskRestore`
- `EventTaskComplete`, `EventTaskReturn`, `EventTaskExpire`
- `EventTaskPlan`, `EventTaskPostpone` -- accepts period/date params

## REST Routes

Dispatcher: `rest.task(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/task/type` | List task types |
| `/task/method` | Get available methods (array returns grouped by id) |
| `/task/count` | Count with search/filter |
| `/task/set` | Upsert task |
| `/task/get` | Get by id with field selection |
| `/task/list` | List with search/filter/pagination |

## Workflow States / Methods / Transitions

**Types:** `system.task`, `user.task`

**States (7):**
- `created` -- new task
- `enabled` -- currently active/in progress
- `expired` -- overdue (auto-transitioned by CheckTask)
- `planned` -- scheduled for future start
- `postponed` -- deferred
- `completed` (disabled) -- finished
- `deleted` -- soft deleted

**Key transitions:**
- created -> enabled (enable), completed (complete), planned (plan), postponed (postpone), deleted (delete)
- enabled -> completed (complete), expired (expire), planned (plan), postponed (postpone), deleted (delete)
- expired -> enabled (enable), postponed (postpone), deleted (delete)
- planned -> enabled (enable), postponed (postpone), deleted (delete)
- postponed -> enabled (enable), completed (complete), deleted (delete)
- completed -> enabled (return), deleted (delete)
- deleted -> created (restore)

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, indexes, 3 triggers |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | (empty) |
| `routine.sql` | yes | yes | 5 kernel functions |
| `api.sql` | yes | yes | 1 api view, 8 api functions |
| `rest.sql` | yes | yes | REST dispatcher (6 routes) |
| `event.sql` | yes | yes | 12 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
