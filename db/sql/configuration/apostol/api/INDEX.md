# api

> Configuration module -- API extensions | Loaded by `example/create.psql` line 13

Application-specific API functions: user registration (signup), current user info (whoami view and function), garbage collection for stale data, REST callback dispatcher for service webhooks, and email confirmation event handler.

## Dependencies

- `client` -- signup creates a client record
- `payment` -- callback routes service payment webhooks
- `confirmation` -- callback references confirmation flow
- Platform: `oauth2`, `session`, `user`, `profile`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `api` | 1 view, 3 functions |
| `rest` | 1 dispatcher function |

## Views

| View | Schema | Description |
|------|--------|-------------|
| `api.whoami` | api | Current session info: client, company, roles, account balance, session, locale, scope, area, interface |

## Functions

**api schema (3):**
- `api.signup(pType, pUserName, pPassword, pName, pPhone, pEmail, pDescription, pProfile)` -- full client registration with user creation, group/area membership, profile setup
- `api.whoami()` -- returns current session info from the whoami view
- `api.garbage_collector(pOffTime, pLimit)` -- purges old job states, notifications, API logs, heartbeat logs, NTRIP logs, meter values, data transfers

**rest schema (1):**
- `rest.callback(pPath, pPayload)` -- REST callback dispatcher; routes `/callback/service/*` to `api.service_callback`

**Event functions (1):**
- `api.on_confirm_email(pId)` -- triggers client `confirm` action after email verification

## REST Routes

Dispatcher: `rest.callback(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/callback/service` | Service payment callback |
| `/callback/service/{report}` | Service callback with report parameter |

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `api.sql` | yes | yes | 1 view, 3 api functions |
| `event.sql` | yes | yes | 1 email confirmation event handler |
| `callback.sql` | yes | yes | REST callback dispatcher |
| `init.sql` | yes | no | RegisterRoute for `callback` |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads api.sql, event.sql, callback.sql |
