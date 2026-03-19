# admin

> Configuration module -- override | Loaded by `example/create.psql` line 4

Application-specific overrides for platform admin hooks. Customizes login behavior (area assignment, Python agent blocking), area lifecycle (blocks deletion when documents exist), and role lifecycle (syncs client code with username, soft-deletes client on role deletion). Also provides FCM token retrieval from mobile devices.

## Dependencies

- Platform: `admin` module (provides `DoLogin`, `DoLogout`, `DoCreateArea`, etc.)
- `client` -- role sync and FCM token lookup
- `device` -- mobile device token retrieval

## Schemas Used

| Schema | Usage |
|--------|-------|
| `kernel` | 9 override functions |

## Functions

**kernel schema (9):**
- `DoLogin(pUserId)` -- sets user area from profile, blocks Python-agent sessions
- `DoLogout(pUserId)` -- no-op stub
- `DoCreateArea(pArea)` -- no-op stub with diagnostics
- `DoUpdateArea(pArea)` -- no-op stub with diagnostics
- `DoDeleteArea(pArea)` -- blocks deletion if area contains documents
- `DoCreateRole(pRole)` -- no-op stub
- `DoUpdateRole(pRole)` -- syncs client code when username changes
- `DoDeleteRole(pRole)` -- unlinks and soft-deletes associated client
- `DoFCMTokens(pUserId)` -- returns FCM tokens from enabled mobile devices or registry fallback

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `do.sql` | yes | yes | 9 platform override functions |
| `create.psql` | -- | -- | Loads do.sql |
| `update.psql` | -- | -- | Loads do.sql |
