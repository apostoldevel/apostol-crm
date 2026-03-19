# observer

> Configuration module -- observer subscriptions | Loaded by `example/create.psql` line 19

Application-specific observer/publisher hook implementations. Handles two publishers: `confirmation` (3-D Secure payment confirmations filtered by agents/clients/cards with ACL checks) and `urgent` (urgent notifications filtered by events/reasons and scoped to the target user).

## Dependencies

- `confirmation` -- publisher source; uses `api.confirmation` view
- `payment` -- filter resolution for confirmation events
- `client` -- ACL check for confirmation events
- Platform: `observer` module (provides `DoCheckListenerFilter`, `DoFilterListener`, etc.)

## Schemas Used

| Schema | Usage |
|--------|-------|
| `kernel` | 4 override functions |

## Functions

**kernel schema (4):**
- `DoCheckListenerFilter(pPublisher, pFilter)` -- validates filter keys: `agents` for confirmation, `events`/`reasons` for urgent
- `DoCheckListenerParams(pPublisher, pParams)` -- validates params: type must be `notify` for both publishers
- `DoFilterListener(pPublisher, pSession, pIdentity, pData)` -- applies publisher-specific filtering with ACL checks; returns boolean
- `DoEventListener(pPublisher, pSession, pIdentity, pData)` -- returns event data: confirmation record from `api.confirmation`, raw JSON for urgent

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `routine.sql` | yes | yes | 4 observer hook functions |
| `create.psql` | -- | -- | Loads routine.sql |
| `update.psql` | -- | -- | Loads routine.sql |
