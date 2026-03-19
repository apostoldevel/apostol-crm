--------------------------------------------------------------------------------
-- ORDER -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.order --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.order (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    currency        uuid NOT NULL REFERENCES db.currency(id),
    debit           uuid NOT NULL REFERENCES db.account(id),
    credit          uuid NOT NULL REFERENCES db.account(id),
    amount          numeric(24,8) NOT NULL,
    code            text NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.order IS 'Financial order that transfers funds between two accounts.';

COMMENT ON COLUMN db.order.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.order.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.order.currency IS 'Currency in which the order is denominated.';
COMMENT ON COLUMN db.order.debit IS 'Account to debit (source of funds).';
COMMENT ON COLUMN db.order.credit IS 'Account to credit (destination of funds).';
COMMENT ON COLUMN db.order.amount IS 'Order amount. Must be positive.';
COMMENT ON COLUMN db.order.code IS 'Unique human-readable order code, auto-generated if not provided.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.order (document);
CREATE INDEX ON db.order (currency);
CREATE INDEX ON db.order (debit);
CREATE INDEX ON db.order (credit);

CREATE UNIQUE INDEX ON db.order (code);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_order_before_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := concat('order_', gen_random_code());
  END IF;

  IF NEW.amount <= 0 THEN
    PERFORM IncorrectOrderAmount(NEW.code, NEW.amount);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_order_before_insert
  BEFORE INSERT ON db.order
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_order_before_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_order_after_insert()
RETURNS trigger AS $$
DECLARE
  uClient   uuid;
  uUserId   uuid;
BEGIN
  SELECT client INTO uClient FROM db.account WHERE id = NEW.debit;

  uUserId := GetClientUserId(uClient);
  IF uUserId IS NOT NULL THEN
	UPDATE db.aou SET allow = allow | B'100' WHERE object = NEW.document AND userid = uUserId;
	IF NOT FOUND THEN
	  INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'100';
	END IF;
  END IF;

  SELECT client INTO uClient FROM db.account WHERE id = NEW.credit;

  uUserId := GetClientUserId(uClient);
  IF uUserId IS NOT NULL THEN
	UPDATE db.aou SET allow = allow | B'100' WHERE object = NEW.document AND userid = uUserId;
	IF NOT FOUND THEN
	  INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'100';
	END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_order_after_insert
  AFTER INSERT ON db.order
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_order_after_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_order_before_update()
RETURNS trigger AS $$
BEGIN
  IF NEW.amount <= 0 THEN
    PERFORM IncorrectOrderAmount(NEW.code, NEW.amount);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_order_before_update
  BEFORE UPDATE ON db.order
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_order_before_update();
