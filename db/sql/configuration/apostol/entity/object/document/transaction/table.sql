--------------------------------------------------------------------------------
-- TRANSACTION -----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.transaction --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.transaction (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    client          uuid NOT NULL REFERENCES db.client(id) ON DELETE RESTRICT,
    service         uuid NOT NULL REFERENCES db.service(id) ON DELETE RESTRICT,
    currency        uuid NOT NULL REFERENCES db.currency(id) ON DELETE RESTRICT,
    "order"         uuid REFERENCES db.order(id) ON DELETE RESTRICT,
    device          uuid REFERENCES db.device(id) ON DELETE RESTRICT,
    tariff          uuid REFERENCES db.tariff(id) ON DELETE RESTRICT,
    subscription    uuid REFERENCES db.subscription(id) ON DELETE RESTRICT,
    invoice         uuid REFERENCES db.invoice(id) ON DELETE RESTRICT,
    transactionId   bigint REFERENCES db.device_transaction(id) ON DELETE RESTRICT,
    code            text NOT NULL,
    price           numeric(12,2) NOT NULL,
    volume          numeric DEFAULT 0 NOT NULL,
    amount          numeric(12,2) DEFAULT 0 NOT NULL,
    commission      numeric(12,2) DEFAULT 0 NOT NULL,
    tax             numeric(12,2) DEFAULT 0 NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.transaction IS 'Business transaction recording service consumption by a client, with pricing, volume, and financial references.';

COMMENT ON COLUMN db.transaction.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.transaction.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.transaction.client IS 'Client who initiated or is billed for this transaction.';
COMMENT ON COLUMN db.transaction.service IS 'Service consumed in this transaction.';
COMMENT ON COLUMN db.transaction.currency IS 'Currency for all monetary amounts in this transaction.';
COMMENT ON COLUMN db.transaction."order" IS 'Financial order that moves funds for this transaction, if applicable.';
COMMENT ON COLUMN db.transaction.device IS 'Device on which the service was consumed, if applicable.';
COMMENT ON COLUMN db.transaction.tariff IS 'Tariff applied for pricing this transaction.';
COMMENT ON COLUMN db.transaction.subscription IS 'Subscription under which this transaction was performed, if applicable.';
COMMENT ON COLUMN db.transaction.invoice IS 'Invoice covering this transaction, if applicable.';
COMMENT ON COLUMN db.transaction.transactionId IS 'Reference to the device-level transaction record.';
COMMENT ON COLUMN db.transaction.code IS 'Unique transaction code, auto-generated if not provided.';
COMMENT ON COLUMN db.transaction.price IS 'Unit price applied to this transaction.';
COMMENT ON COLUMN db.transaction.volume IS 'Volume of service consumed (units depend on the service type).';
COMMENT ON COLUMN db.transaction.amount IS 'Total amount charged (price * volume or fixed).';
COMMENT ON COLUMN db.transaction.commission IS 'Commission amount charged on this transaction.';
COMMENT ON COLUMN db.transaction.tax IS 'Tax amount charged on this transaction.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.transaction (document);
CREATE INDEX ON db.transaction (client);
CREATE INDEX ON db.transaction (service);
CREATE INDEX ON db.transaction (currency);
CREATE INDEX ON db.transaction ("order");
CREATE INDEX ON db.transaction (device);
CREATE INDEX ON db.transaction (tariff);
CREATE INDEX ON db.transaction (subscription);
CREATE INDEX ON db.transaction (invoice);
CREATE INDEX ON db.transaction (transactionId);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_transaction_insert()
RETURNS trigger AS $$
DECLARE
  uUserId    uuid;
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := concat('tx_', gen_random_code());
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

CREATE TRIGGER t_transaction_insert
  BEFORE INSERT ON db.transaction
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_transaction_insert();
