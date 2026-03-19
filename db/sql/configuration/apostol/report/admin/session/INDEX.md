# report/admin/session

> Configuration sub-module — report | Loaded by `report/create.psql`

Session list report — generates HTML and CSV output of user sessions filtered by group, user, and status. Bilingual (Russian/English).

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: `report` (report framework), `admin` (sessions, users, groups) | Registered as `session_list` report in `InitConfigurationReport()` |

## Schemas Used

| Schema | Usage |
|--------|-------|
| `report` | 2 functions (form + generator) |

## Functions (report schema) — 2

| Function | Returns | Purpose |
|----------|---------|---------|
| `report.rfc_session_list(pForm uuid, pParams json)` | `json` | Report form: group/user/status selectors with bilingual labels |
| `report.rpc_session_list(pReady uuid, pForm jsonb)` | `void` | Report generator: queries `db.session` + `users`, produces HTML table + CSV, saves as `index.html` via `SetObjectFile` |

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `routine.sql` | yes | yes | `rfc_session_list` (form) + `rpc_session_list` (generator) |
