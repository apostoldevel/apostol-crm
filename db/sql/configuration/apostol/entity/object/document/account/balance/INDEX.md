# balance

> Sub-entity of `account` | Loaded by `account/create.psql` line 4

Temporal balance and turnover tracking for financial accounts. Maintains point-in-time balance snapshots with validity periods and records individual debit/credit turnover entries. Balance types: 0 = opening, 1 = closing (current), 2 = debit turnover, 3 = credit turnover.

## Dependencies

- `account` -- parent entity; every balance/turnover record references an account

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Tables `balance`, `turnover` |
| `kernel` | Views `Balance`, `Turnover`; routines |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.balance` | id, type, account, amount, validFromDate, validToDate | Temporal balance snapshots (type 0-3) with validity period |
| `db.turnover` | id, type, account, debit, credit, timestamp, datetime | Individual debit/credit turnover entries |

**Indexes (balance):** account, type, UNIQUE(type, account, validFromDate, validToDate)
**Indexes (turnover):** account, type, UNIQUE(type, account, datetime)

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Balance` | kernel | Simple wrapper over `db.balance` |
| `Turnover` | kernel | Simple wrapper over `db.turnover` |

## Functions

**kernel schema (6):**
- `CheckBalance(pAccount, pAmount)` -- validates sufficient funds, raises `InsufficientFunds` on failure
- `NewBalance(pType, pAccount, pAmount, pTimeStamp)` -- creates or updates temporal balance record
- `ChangeBalance(pAccount, pAmount, pTimeStamp)` -- atomic debit: checks balance, creates turnover, adjusts closing balance
- `NewTurnOver(pType, pAccount, pDebit, pCredit, pTimeStamp)` -- creates or updates temporal turnover record
- `UpdateBalance(pAccount, pAmount, pTimeStamp)` -- replenish: creates credit turnover, increases closing balance
- `GetBalance(pAccount, pTimeStamp)` -- returns current balance amount

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | 2 tables DDL, indexes |
| `view.sql` | yes | yes | 2 kernel views |
| `routine.sql` | yes | yes | 6 kernel functions |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads view.sql, routine.sql |
