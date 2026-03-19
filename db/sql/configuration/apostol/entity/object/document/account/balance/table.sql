--------------------------------------------------------------------------------
-- BALANCE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.balance (
    id              uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    type            integer NOT NULL CHECK (type BETWEEN 0 AND 3) DEFAULT 0,
    account         uuid NOT NULL REFERENCES db.account(id) ON DELETE RESTRICT,
    amount          numeric NOT NULL,
    validFromDate   timestamptz DEFAULT MINDATE() NOT NULL,
    validToDate     timestamptz DEFAULT MAXDATE() NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.balance IS 'Account balance snapshot with temporal validity. Tracks opening, actual, planned, and equivalent balances.';

COMMENT ON COLUMN db.balance.id IS 'Primary key, auto-generated UUID.';
COMMENT ON COLUMN db.balance.type IS 'Balance type: 0 = opening, 1 = actual, 2 = planned, 3 = equivalent.';
COMMENT ON COLUMN db.balance.account IS 'Reference to the account this balance belongs to.';
COMMENT ON COLUMN db.balance.amount IS 'Balance amount in the account currency.';
COMMENT ON COLUMN db.balance.validFromDate IS 'Start of the validity period for this balance record.';
COMMENT ON COLUMN db.balance.validToDate IS 'End of the validity period for this balance record.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.balance (type);
CREATE INDEX ON db.balance (account);

CREATE UNIQUE INDEX ON db.balance (type, account, validFromDate, validToDate);

--------------------------------------------------------------------------------
-- TURNOVER --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.turnover (
    id              uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    type            integer NOT NULL DEFAULT 0,
    account         uuid NOT NULL REFERENCES db.account(id) ON DELETE RESTRICT,
    debit           numeric NOT NULL,
    credit          numeric NOT NULL,
    timestamp       timestamptz NOT NULL,
    datetime        timestamptz NOT NULL DEFAULT Now(),
    CHECK (type BETWEEN 0 AND 3)
);

COMMENT ON TABLE db.turnover IS 'Account turnover record tracking debit and credit totals over time.';

COMMENT ON COLUMN db.turnover.id IS 'Primary key, auto-generated UUID.';
COMMENT ON COLUMN db.turnover.type IS 'Turnover type: 0 = opening, 1 = actual, 2 = planned, 3 = equivalent.';
COMMENT ON COLUMN db.turnover.account IS 'Reference to the account this turnover belongs to.';
COMMENT ON COLUMN db.turnover.debit IS 'Total debit turnover amount.';
COMMENT ON COLUMN db.turnover.credit IS 'Total credit turnover amount.';
COMMENT ON COLUMN db.turnover.timestamp IS 'Logical timestamp of the turnover (business time).';
COMMENT ON COLUMN db.turnover.datetime IS 'Physical timestamp when the turnover was recorded (wall-clock time).';

CREATE INDEX ON db.turnover (type);
CREATE INDEX ON db.turnover (account);

CREATE INDEX ON db.turnover (type, account, timestamp);
