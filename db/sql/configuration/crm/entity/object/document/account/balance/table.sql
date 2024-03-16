--------------------------------------------------------------------------------
-- BALANCE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.balance (
    id                uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    type              integer NOT NULL CHECK (type BETWEEN 0 AND 3) DEFAULT 0,
    account           uuid NOT NULL REFERENCES db.account(id) ON DELETE RESTRICT,
    amount            numeric NOT NULL,
    validFromDate     timestamptz DEFAULT Now() NOT NULL,
    validToDate       timestamptz DEFAULT MAXDATE() NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.balance IS 'Баланс.';

COMMENT ON COLUMN db.balance.id IS 'Идентификатор';
COMMENT ON COLUMN db.balance.type IS 'Тип: 0 - на момент открытия; 1 - реальный; 2 - плановый; 3 - эквивалент';
COMMENT ON COLUMN db.balance.account IS 'Счёт';
COMMENT ON COLUMN db.balance.amount IS 'Сумма';
COMMENT ON COLUMN db.balance.validFromDate IS 'Дата начала периода действия';
COMMENT ON COLUMN db.balance.validToDate IS 'Дата окончания периода действия';

--------------------------------------------------------------------------------

CREATE INDEX ON db.balance (type);
CREATE INDEX ON db.balance (account);

CREATE UNIQUE INDEX ON db.balance (type, account, validFromDate, validToDate);

--------------------------------------------------------------------------------
-- TURNOVER --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.turnover (
    id                uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    type            integer NOT NULL DEFAULT 0,
    account            uuid NOT NULL REFERENCES db.account(id) ON DELETE RESTRICT,
    debit            numeric NOT NULL,
    credit          numeric NOT NULL,
    timestamp        timestamptz NOT NULL,
    datetime        timestamptz NOT NULL DEFAULT Now(),
    CHECK (type BETWEEN 0 AND 3)
);

COMMENT ON TABLE db.turnover IS 'Оборот.';

COMMENT ON COLUMN db.turnover.id IS 'Идентификатор';
COMMENT ON COLUMN db.turnover.type IS 'Тип: 0 - на момент открытия; 1 - реальный; 2 - плановый; 3 - эквивалент';
COMMENT ON COLUMN db.turnover.account IS 'Счёт';
COMMENT ON COLUMN db.turnover.debit IS 'Сумма обота по дебету';
COMMENT ON COLUMN db.turnover.credit IS 'Сумма обота по кредиту';
COMMENT ON COLUMN db.turnover.timestamp IS 'Логическое время оборота';
COMMENT ON COLUMN db.turnover.datetime IS 'Физическое время оборота';

CREATE INDEX ON db.turnover (type);
CREATE INDEX ON db.turnover (account);

CREATE INDEX ON db.turnover (type, account, timestamp);
