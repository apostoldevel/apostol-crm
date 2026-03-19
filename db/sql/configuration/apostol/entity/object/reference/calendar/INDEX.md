# calendar

> Configuration entity -- reference | Loaded by `reference/create.psql` line 6

Work calendar reference with configurable work week, holidays, work/rest hours, and weekly schedule. Includes a `cdate` child table for per-day overrides with per-user support.

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: reference, object, type, scope, state, user, aou | subscription, job (conceptual scheduling) |

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Tables, trigger function |
| `kernel` | Views, functions |
| `api` | API views, functions |
| `rest` | REST dispatcher |

## Tables -- 2

| Table | Description | Key Columns |
|-------|-------------|-------------|
| `db.calendar` | Calendar reference | `id`, `reference`, `week` integer (workdays/week), `dayoff` integer[], `holiday` integer[][], `work_start` interval, `work_count` interval, `rest_start` interval, `rest_count` interval, `schedule` text[][] |
| `db.cdate` | Calendar date entries | `id` uuid (auto-generated), `calendar` uuid FK, `date` date, `flag` bit(4), `work_start` interval, `work_count` interval, `rest_start` interval, `rest_count` interval, `schedule` interval[][], `userid` uuid FK; unique (calendar, date, userid) |

## Triggers -- 1

| Trigger | Table | Event | Purpose |
|---------|-------|-------|---------|
| `t_calendar_insert` | `db.calendar` | BEFORE INSERT | Auto-sets `id` from `reference` |

## Views

### kernel schema

| View | Source | Grants |
|------|--------|--------|
| `Calendar` | `db.calendar` + reference + type + scope | administrator |
| `AccessCalendar` | `db.calendar` + `db.aou` + member_group | administrator |
| `ObjectCalendar` | `db.calendar` + full object/entity/class/type/state/user joins | administrator |
| `calendar_date` | `db.cdate` with computed label/work times based on flag bits | (no explicit grant) |
| `CalendarDate` | `calendar_date` + Calendar + user | administrator |

### api schema

| View | Source | Purpose |
|------|--------|---------|
| `api.calendar` | `ObjectCalendar` | Public API view for calendars |
| `api.calendar_date` | `calendar_date` | Public API view for calendar dates |
| `api.calendardate` | `CalendarDate` | Public API view for calendar dates with calendar/user info |

## Functions (kernel schema) -- 10

| Function | Returns | Purpose |
|----------|---------|---------|
| `CreateCalendar(pParent, pType, pCode, pName, pWeek, pDayOff, pHoliday, pWorkStart, pWorkCount, pRestStart, pRestCount, pSchedule, pDescription)` | `uuid` | Creates a calendar |
| `EditCalendar(pId, ...)` | `void` | Edits a calendar |
| `GetCalendar(pCode)` | `uuid` | Finds calendar by code |
| `AddCalendarDate(pCalendar, pDate, pFlag, pWorkStart, pWorkCount, pRestStart, pRestCount, pSchedule, pUserId)` | `uuid` | Adds a single calendar date entry |
| `EditCalendarDate(pId, ...)` | `void` | Edits a calendar date entry |
| `DeleteCalendarDate(pId)` | `void` | Deletes a calendar date entry |
| `GetCalendarDate(pCalendar, pDate, pUserId)` | `uuid` | Finds calendar date by calendar+date+user |
| `calendar_date(pCalendar, pDateFrom, pDateTo, pUserId)` | `SETOF calendar_date` | Returns calendar dates for a period (user dates override common dates) |
| `FillCalendar(pCalendar, pDateFrom, pDateTo, pUserId)` | `void` | Fills calendar with computed dates for a period (handles holidays, pre-holiday shortened days, weekends) |
| `GetCalendarPeriod(pCalendar, pDateFrom, pDateTo, pUserId)` | `interval` | Calculates working time in a date range |

## Functions (api schema) -- 12

| Function | Returns | Purpose |
|----------|---------|---------|
| `api.add_calendar(pParent, pType, pCode, pName, pWeek, pDayOff, pHoliday, pWorkStart, pWorkCount, pRestStart, pRestCount, pSchedule, pDescription)` | `uuid` | Add a calendar |
| `api.update_calendar(pId, ...)` | `void` | Update a calendar |
| `api.set_calendar(pId, ...)` | `SETOF api.calendar` | Upsert a calendar |
| `api.get_calendar(pId)` | `SETOF api.calendar` | Get calendar by ID |
| `api.list_calendar(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.calendar` | List calendars with filtering |
| `api.fill_calendar(pCalendar, pDateFrom, pDateTo, pUserId)` | `void` | Fill calendar dates for a period |
| `api.list_calendar_date(pCalendar, pDateFrom, pDateTo, pUserId)` | `SETOF api.calendar_date` | List calendar dates for a period (user overrides common) |
| `api.list_calendar_user(pCalendar, pDateFrom, pDateTo, pUserId)` | `SETOF api.calendar_date` | List only user-specific calendar dates |
| `api.get_calendar_date(pCalendar, pDate, pUserId)` | `SETOF api.calendar_date` | Get a specific calendar date |
| `api.set_calendar_date(pCalendar, pDate, pFlag, pWorkStart, pWorkCount, pRestStart, pRestCount, pSchedule, pUserId)` | `SETOF api.calendar_date` | Upsert a calendar date entry |
| `api.delete_calendar_date(pCalendar, pDate, pUserId)` | `void` | Delete a calendar date entry |

## REST Routes -- 13

Dispatcher: `rest.calendar(pPath text, pPayload jsonb)`.

| Path | Purpose |
|------|---------|
| `/calendar/type` | List entity types |
| `/calendar/method` | Get available methods for a calendar |
| `/calendar/count` | Count calendars with optional filtering |
| `/calendar/set` | Create or update a calendar |
| `/calendar/get` | Get a calendar by ID |
| `/calendar/list` | List calendars with filtering/pagination |
| `/calendar/fill` | Fill calendar with dates for a period |
| `/calendar/date/list` | List calendar dates for a period |
| `/calendar/user/list` | List user-specific calendar dates |
| `/calendar/date/get` | Get a specific calendar date |
| `/calendar/date/set` | Set (upsert) a calendar date entry |
| `/calendar/date/delete` | Delete a calendar date entry |

## Workflow States / Methods / Transitions

Defined via `AddDefaultMethods` (default labels).

Type registered: `workday.calendar` -- "Workday" (Calendar of workdays).

## Calendar Date Flags

The `flag` column in `db.cdate` is a 4-bit field: `1000` = pre-holiday (shortened), `0100` = holiday, `0010` = weekend, `0001` = non-working, `0000` = working day.

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | `db.calendar` + `db.cdate` tables, indexes, insert trigger |
| `view.sql` | yes | yes | Calendar, AccessCalendar, ObjectCalendar, calendar_date, CalendarDate views |
| `routine.sql` | yes | yes | CreateCalendar, EditCalendar, GetCalendar, Add/Edit/Delete/GetCalendarDate, calendar_date, FillCalendar, GetCalendarPeriod |
| `api.sql` | yes | yes | api.calendar + api.calendar_date + api.calendardate views + 12 functions |
| `rest.sql` | yes | yes | REST dispatcher with 13 routes (calendar/* + calendar/date/* + calendar/user/*) |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration |
