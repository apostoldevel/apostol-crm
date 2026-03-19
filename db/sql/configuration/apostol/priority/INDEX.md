# priority

> Configuration module -- REST endpoint | Loaded by `example/create.psql` line 10

REST endpoint for the platform `priority` reference entity. Exposes count, get, and list operations for document priority levels. The priority entity itself (table, views, API functions) is defined in the platform; this module only adds the REST dispatcher and route registration.

## Dependencies

- Platform: `priority` entity (provides `api.get_priority`, `api.list_priority`, `api.priority` view)

## Schemas Used

| Schema | Usage |
|--------|-------|
| `rest` | 1 dispatcher function |

## REST Routes

Dispatcher: `rest.priority(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/priority/count` | Count priorities with search/filter |
| `/priority/get` | Get priority by id with field selection |
| `/priority/list` | List priorities with search/filter/pagination |

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `rest.sql` | yes | yes | REST dispatcher (3 routes) |
| `init.sql` | yes | no | RegisterRoute for `priority` |
| `create.psql` | -- | -- | Loads rest.sql, init.sql |
| `update.psql` | -- | -- | Loads rest.sql |
