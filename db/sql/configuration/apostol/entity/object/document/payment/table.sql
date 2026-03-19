--------------------------------------------------------------------------------
-- PAYMENT ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.payment ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.payment (
  id                uuid PRIMARY KEY,
  document          uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
  currency          uuid NOT NULL REFERENCES db.currency(id),
  client            uuid NOT NULL REFERENCES db.client(id),
  card              uuid REFERENCES db.card(id),
  invoice           uuid REFERENCES db.invoice(id),
  "order"           uuid REFERENCES db.order(id),
  code              text NOT NULL,
  amount            numeric(12,2) NOT NULL,
  payment_id        text,
  metadata          jsonb
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.payment IS 'Payment record representing a monetary transaction initiated by a client.';

COMMENT ON COLUMN db.payment.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.payment.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.payment.currency IS 'Currency in which the payment is made.';
COMMENT ON COLUMN db.payment.client IS 'Client who initiated the payment.';
COMMENT ON COLUMN db.payment.card IS 'Card used for the payment, if applicable.';
COMMENT ON COLUMN db.payment.invoice IS 'Invoice that this payment covers, if applicable.';
COMMENT ON COLUMN db.payment."order" IS 'Financial order associated with this payment, if applicable.';
COMMENT ON COLUMN db.payment.code IS 'Unique human-readable payment code, auto-generated if not provided.';
COMMENT ON COLUMN db.payment.amount IS 'Payment amount in the specified currency.';
COMMENT ON COLUMN db.payment.payment_id IS 'External payment identifier in the payment gateway system. Must be unique.';
COMMENT ON COLUMN db.payment.metadata IS 'Additional data from the payment gateway in JSON format.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.payment (document);
CREATE INDEX ON db.payment (currency);
CREATE INDEX ON db.payment (client);
CREATE INDEX ON db.payment (card);
CREATE INDEX ON db.payment (invoice);
CREATE INDEX ON db.payment ("order");

CREATE UNIQUE INDEX ON db.payment (code);
CREATE UNIQUE INDEX ON db.payment (payment_id);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_payment_before_insert()
RETURNS trigger AS $$
DECLARE
  uUserId    uuid;
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := lower(concat('pay_', gen_random_code()));
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

CREATE TRIGGER t_payment_before_insert
  BEFORE INSERT ON db.payment
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_payment_before_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_payment_after_insert()
RETURNS trigger AS $$
DECLARE
  uUserId    uuid;
BEGIN
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

CREATE TRIGGER t_payment_after_insert
  AFTER INSERT ON db.payment
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_payment_after_insert();
