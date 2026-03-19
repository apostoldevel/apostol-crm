--------------------------------------------------------------------------------
-- CURRENCY --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.currency -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.currency (
    id              uuid PRIMARY KEY,
    reference       uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE,
    digital         integer,
    decimal         integer DEFAULT 2
);

COMMENT ON TABLE db.currency IS 'Currency reference based on ISO 4217 standard.';

COMMENT ON COLUMN db.currency.id IS 'Primary key, matches the parent reference UUID.';
COMMENT ON COLUMN db.currency.reference IS 'Link to the parent reference entry.';
COMMENT ON COLUMN db.currency.digital IS 'ISO 4217 numeric currency code.';
COMMENT ON COLUMN db.currency.decimal IS 'Number of decimal places for monetary amounts (default 2).';

CREATE INDEX ON db.currency (reference);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_currency_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.reference INTO NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_currency_insert
  BEFORE INSERT ON db.currency
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_currency_insert();
