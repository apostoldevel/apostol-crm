# name

> Sub-entity of `client` | Loaded by `client/create.psql` line 4

Temporal and locale-aware client name storage. Tracks name changes over time with validity periods, supporting internationalization through locale references. Each name record stores surname, given name, patronymic, and a composed full name.

## Dependencies

- `client` -- parent entity; every name record references a client

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `client_name`, triggers |
| `kernel` | View `ClientName`; routines |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.client_name` | id, client, locale, name, surname, givenname, patronymic, validFromDate, validToDate | Temporal locale-aware client name with individual name components |

**Indexes:** client, locale, UNIQUE(client, locale, validFromDate, validToDate)

**Triggers (1):**
- `t_client_name_insert_update` -- BEFORE INSERT/UPDATE: auto-generates id, composes `name` from surname+givenname+patronymic

## Views

| View | Schema | Description |
|------|--------|-------------|
| `ClientName` | kernel | Simple wrapper over `db.client_name` |

## Functions

**kernel schema (6):**
- `NewClientName(pClient, pName, pSurname, pGivenName, pPatronymic, pLocale, pDate)` -- creates or updates temporal name record
- `EditClientName(pClient, pName, pSurname, pGivenName, pPatronymic, pLocale, pDate)` -- edits name in current validity period
- `GetClientNameRec(pClient, pLocale, pDate)` -- returns full name record
- `GetClientNameJson(pClient, pLocale, pDate)` -- returns name as JSON
- `GetClientName(pClient, pLocale, pDate)` -- returns composed full name
- `GetClientShortName(pClient, pLocale, pDate)` -- returns abbreviated name (surname + initials)

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, indexes, 1 trigger |
| `view.sql` | yes | yes | 1 kernel view |
| `routine.sql` | yes | yes | 6 kernel functions |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads view.sql, routine.sql |
