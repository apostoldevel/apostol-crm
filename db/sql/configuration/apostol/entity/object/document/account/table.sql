--------------------------------------------------------------------------------
-- db.account ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.account (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    currency        uuid NOT NULL REFERENCES db.currency(id),
    client          uuid NOT NULL REFERENCES db.client(id),
    category        uuid REFERENCES db.category(id),
    code            text NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.account IS 'Client financial account in a specific currency. Holds balances and participates in orders and transactions.';

COMMENT ON COLUMN db.account.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.account.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.account.currency IS 'Currency of this account.';
COMMENT ON COLUMN db.account.client IS 'Client who owns this account.';
COMMENT ON COLUMN db.account.category IS 'Optional category for account classification.';
COMMENT ON COLUMN db.account.code IS 'Unique account code, auto-generated if not provided.';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.account (currency, code);

CREATE INDEX ON db.account (document);
CREATE INDEX ON db.account (currency);
CREATE INDEX ON db.account (client);
CREATE INDEX ON db.account (category);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_account_before_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := concat('acc_', gen_random_code());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_account_before_insert
  BEFORE INSERT ON db.account
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_account_before_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_account_after_insert()
RETURNS trigger AS $$
DECLARE
  uUserId    uuid;
BEGIN
  uUserId := GetClientUserId(NEW.client);
  IF uUserId IS NOT NULL THEN
    UPDATE db.object SET owner = uUserId WHERE id = NEW.document;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_account_after_insert
  AFTER INSERT ON db.account
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_account_after_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_account_after_update_client()
RETURNS trigger AS $$
DECLARE
  uUserId   uuid;
  uOwner    uuid;
BEGIN
  SELECT owner INTO uOwner FROM db.object WHERE id = NEW.document;

  uUserId := GetClientUserId(NEW.client);
  IF uOwner <> uUserId THEN
    UPDATE db.aou SET allow = allow | B'100' WHERE object = NEW.document AND userid = uUserId;
    IF NOT found THEN
      INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'100';
    END IF;
  END IF;

  uUserId := GetClientUserId(OLD.client);
  IF uOwner <> uUserId THEN
    DELETE FROM db.aou WHERE object = OLD.document AND userid = uUserId;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_account_after_update_client
  AFTER UPDATE ON db.account
  FOR EACH ROW
  WHEN (OLD.client IS DISTINCT FROM NEW.client)
  EXECUTE PROCEDURE db.ft_account_after_update_client();
