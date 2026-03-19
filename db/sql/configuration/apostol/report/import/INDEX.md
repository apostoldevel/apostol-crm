# report/import

> Configuration sub-module — report | Loaded by `report/create.psql`

File import report — accepts files via REST/API, stores them as report attachments using `SetObjectFile`, and generates an HTML summary table. Authenticates as `apibot` via OAuth2 for system-level access.

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: `report` (BuildReport, report_ready), `oauth2` (audience), `admin` (SignIn, SubstituteUser) | Registered as `import_data` report in `InitConfigurationReport()` |

## Schemas Used

| Schema | Usage |
|--------|-------|
| `report` | 1 function (generator) |
| `api` | 1 function (import wrapper) |
| `rest` | 1 function (REST dispatcher) |

## Functions (report schema) — 1

| Function | Returns | Purpose |
|----------|---------|---------|
| `report.rpc_import_files(pReady uuid, pForm jsonb)` | `void` | Processes `files` array from form: stores each file via `SetObjectFile`, generates HTML summary table |

## Functions (api schema) — 1

| Function | Returns | Purpose |
|----------|---------|---------|
| `api.import(pPayload jsonb)` | `jsonb` | Wraps payload into a file record, calls `BuildReport` for async processing, returns `{ok, report_id, status}` |

## REST Routes — 1

Dispatcher: `rest.import(pPath text, pPayload jsonb)`.

| Path | Purpose |
|------|---------|
| `/import[/object[/file]]` | Accepts import payload, authenticates as apibot via OAuth2, calls `api.import` |

## Init / Seed Data

Registered by `InitConfigurationReport()` as report `import_data` with routine `rpc_import_files`.

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `routine.sql` | yes | yes | `report.rpc_import_files` generator |
| `api.sql` | yes | yes | `api.import` wrapper |
| `rest.sql` | yes | yes | `rest.import` dispatcher |
| `init.sql` | yes | no | Route registration for `/import` |
