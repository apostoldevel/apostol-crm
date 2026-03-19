# report

> Configuration module -- reporting | Loaded by `example/create.psql` line 16

Report generation framework extensions. Provides HTML/CSS rendering helpers, three built-in reports (client list, user list, session list), and a file import subsystem with its own REST endpoint. Reports generate locale-aware HTML and CSV output.

## Dependencies

- Platform: `report` module (provides report tree, forms, ready reports, `BuildReport`, `InitReport`)
- `session`, `user` -- data sources for admin reports
- `file` -- import stores files via `SetObjectFile`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `report` | 7 functions (2 top-level + 2 session + 2 user + 1 import) |
| `api` | 1 function (import) |
| `rest` | 1 dispatcher function (import) |

## Functions

**report schema -- top-level (2):**
- `report.get_report_style(orientation)` -- generates CSS `<style>` block with A4 print layout
- `report.get_report_head(title, orientation)` -- generates HTML `<head>` with charset, title, stylesheet link, and print styles

**report schema -- admin/user (2):**
- `report.rfc_user_list(pForm, pParams)` -- form definition: group/user/status selectors (bilingual ru/en)
- `report.rpc_user_list(pReady, pForm)` -- generates user list HTML table + CSV with status, login stats, contact info

**report schema -- admin/session (2):**
- `report.rfc_session_list(pForm, pParams)` -- form definition: group/user/status selectors (bilingual ru/en)
- `report.rpc_session_list(pReady, pForm)` -- generates session list HTML table + CSV with session codes, hosts, timestamps

**report schema -- import (1):**
- `report.rpc_import_files(pReady, pForm)` -- generates file import HTML report, stores uploaded files via `SetObjectFile`

**api schema (1):**
- `api.import(pPayload)` -- builds import report asynchronously via `BuildReport`

**rest schema (1):**
- `rest.import(pPath, pPayload)` -- REST dispatcher for file import; authenticates as apibot

## REST Routes

Dispatcher: `rest.import(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/import/{object}` | Import files for object |
| `/import/{object}/{file}` | Import specific file for object |

## Init / Seed Data

- `InitConfigurationReport()` -- creates report tree (root, general, admin nodes), registers 3 reports: `client_list`, `user_list` (admin-only), `session_list` (admin-only), plus `object_info` with identifier form
- RegisterRoute for `import`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `routine.sql` | yes | yes | 2 HTML/CSS helper functions |
| `init.sql` | yes | no | Report tree and report registration |
| `create.psql` | -- | -- | Loads routine.sql, admin/, import/, init.sql |
| `update.psql` | -- | -- | Loads routine.sql, admin/, import/ |

**Sub-directory: admin/user/**

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `routine.sql` | yes | yes | 2 report functions (form + generator) |

**Sub-directory: admin/session/**

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `routine.sql` | yes | yes | 2 report functions (form + generator) |

**Sub-directory: import/**

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `init.sql` | yes | no | RegisterRoute for `import` |
| `routine.sql` | yes | yes | 1 import report function |
| `api.sql` | yes | yes | 1 api function |
| `rest.sql` | yes | yes | REST import dispatcher |
