# report/admin/user

> Configuration sub-module — report | Loaded by `report/create.psql`

User list report — generates HTML and CSV output of users filtered by group, user, and status. Includes login statistics (last login, count, errors). Bilingual (Russian/English).

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: `report` (report framework), `admin` (users, groups, member_group) | Registered as `user_list` report in `InitConfigurationReport()` |

## Schemas Used

| Schema | Usage |
|--------|-------|
| `report` | 2 functions (form + generator) |

## Functions (report schema) — 2

| Function | Returns | Purpose |
|----------|---------|---------|
| `report.rfc_user_list(pForm uuid, pParams json)` | `json` | Report form: group/user/status selectors with bilingual labels |
| `report.rpc_user_list(pReady uuid, pForm jsonb)` | `void` | Report generator: queries `users` view, produces HTML table + CSV with status/username/name/email/phone/created/IP/login stats |

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `routine.sql` | yes | yes | `rfc_user_list` (form) + `rpc_user_list` (generator) |
