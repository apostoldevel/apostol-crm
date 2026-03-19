# confirmation

> Configuration module -- payment confirmation | Loaded by `example/create.psql` line 25

Payment confirmation flow for 3-D Secure processing. Stores confirmation data (linked to agent and payment), fires PostgreSQL NOTIFY on insert/update to alert the observer system, and exposes a view for the observer to deliver confirmation data to subscribed WebSocket clients.

## Dependencies

- `agent` -- payment agent reference
- `payment` -- payment being confirmed
- `client` -- resolved through payment for view joins
- `card` -- optional card from payment
- `invoice` -- optional invoice from payment
- Platform: `observer` (publisher/subscriber)

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `confirmation`; 2 triggers |
| `kernel` | View `Confirmation`; 1 routine |
| `api` | View `api.confirmation` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.confirmation` | id, agent, payment, data, validFromDate, validToDate | Payment confirmation record |

**Indexes (4):** agent, payment, (validFromDate, validToDate), UNIQUE(payment, validFromDate, validToDate)

**Triggers (2):**
- `t_confirmation_after_insert` -- AFTER INSERT: pg_notify('confirmation') with id, agent, payment
- `t_confirmation_after_update` -- AFTER UPDATE (data changed): pg_notify('confirmation') with id, agent, payment

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Confirmation` | kernel | Joins confirmation with agent, payment, client, card, invoice |
| `api.confirmation` | api | Exposes `Confirmation` view |

## Functions

**kernel schema (1):**
- `CreateConfirmation(pAgent, pPayment, pData)` -- upserts confirmation record (ON CONFLICT updates data)

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, 4 indexes, 2 triggers |
| `view.sql` | yes | yes | 1 kernel view |
| `routine.sql` | yes | yes | 1 kernel function |
| `api.sql` | yes | yes | 1 api view |
| `rest.sql` | yes | yes | Empty |
| `init.sql` | yes | no | CreatePublisher for 'confirmation' |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads view.sql, routine.sql, api.sql, rest.sql |
