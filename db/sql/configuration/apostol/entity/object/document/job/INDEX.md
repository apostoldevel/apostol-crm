# job

> Configuration entity -- document (thin override) | Loaded by `document/create.psql` line 12

Overrides platform job event handlers. `EventJobDone` reschedules completed jobs by looking up the scheduler period from the registry and re-enabling the job after the configured interval. `EventJobComplete` is a no-op override.

## Overridden Event Functions (3)

- `EventJobExecute` -- no-op (commented out)
- `EventJobComplete` -- no-op override
- `EventJobDone` -- reschedules job: reads `CONFIG\CurrentProject\Scheduler` period from registry, re-enables after interval

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `event.sql` | yes | yes | 3 event handler overrides |
| `create.psql` | -- | -- | Loads event.sql |
| `update.psql` | -- | -- | Loads event.sql |
