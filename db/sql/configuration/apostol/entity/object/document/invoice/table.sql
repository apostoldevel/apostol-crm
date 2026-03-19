--------------------------------------------------------------------------------
-- INVOICE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.invoice ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.invoice (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    currency        uuid NOT NULL REFERENCES db.currency(id) ON DELETE RESTRICT,
    client          uuid NOT NULL REFERENCES db.client(id),
    device          uuid REFERENCES db.device(id),
    code            text NOT NULL,
    amount          numeric(12,4) NOT NULL,
    pdf             text
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.invoice IS 'Invoice issued to a client for services or device usage. Can be linked to payments.';

COMMENT ON COLUMN db.invoice.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.invoice.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.invoice.currency IS 'Currency of the invoice.';
COMMENT ON COLUMN db.invoice.client IS 'Client to whom the invoice is issued.';
COMMENT ON COLUMN db.invoice.device IS 'Device associated with this invoice, if applicable.';
COMMENT ON COLUMN db.invoice.code IS 'Unique invoice code, auto-generated if not provided.';
COMMENT ON COLUMN db.invoice.amount IS 'Total invoice amount in the specified currency.';
COMMENT ON COLUMN db.invoice.pdf IS 'URL for downloading the invoice PDF.';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.invoice (code);

CREATE INDEX ON db.invoice (document);
CREATE INDEX ON db.invoice (currency);
CREATE INDEX ON db.invoice (client);
CREATE INDEX ON db.invoice (device);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_invoice_insert()
RETURNS trigger AS $$
DECLARE
  uUserId    uuid;
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := concat('inv_', gen_random_code());
  END IF;

  IF NEW.client IS NOT NULL THEN
    uUserId := GetClientUserId(NEW.client);
    IF uUserId IS NOT NULL THEN
      UPDATE db.aou SET allow = allow | B'100' WHERE object = NEW.document AND userid = uUserId;
      IF NOT FOUND THEN
        INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'100';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_invoice_insert
  BEFORE INSERT ON db.invoice
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_invoice_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_invoice_update()
RETURNS trigger AS $$
DECLARE
  uOwner    uuid;
  uUserId    uuid;
BEGIN
  IF NEW.client IS DISTINCT FROM OLD.client THEN
    SELECT owner INTO uOwner FROM db.object WHERE id = NEW.document;

    IF NEW.client IS NOT NULL THEN
      uUserId := GetClientUserId(NEW.client);
      IF uOwner <> uUserId THEN
        UPDATE db.aou SET allow = allow | B'110' WHERE object = NEW.document AND userid = uUserId;
        IF NOT FOUND THEN
          INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'100';
        END IF;
      END IF;
    END IF;

    IF OLD.client IS NOT NULL THEN
      uUserId := GetClientUserId(OLD.client);
      IF uOwner <> uUserId THEN
        DELETE FROM db.aou WHERE object = OLD.document AND userid = uUserId;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_invoice_update
  BEFORE UPDATE ON db.invoice
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_invoice_update();
