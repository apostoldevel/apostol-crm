--------------------------------------------------------------------------------
-- PRICE -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.price --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.price (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    currency        uuid NOT NULL REFERENCES db.currency(id),
    product         uuid NOT NULL REFERENCES db.product(id),
    code            text NOT NULL,
    amount          numeric(12,2) NOT NULL,
    payment_link    text,
    metadata        jsonb
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.price IS 'Price point for a product in a specific currency. Used by subscriptions and invoices.';

COMMENT ON COLUMN db.price.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.price.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.price.currency IS 'Currency for this price.';
COMMENT ON COLUMN db.price.product IS 'Product this price belongs to.';
COMMENT ON COLUMN db.price.code IS 'Unique price code (e.g., Stripe Price ID), auto-generated if not provided.';
COMMENT ON COLUMN db.price.amount IS 'Price amount in the specified currency.';
COMMENT ON COLUMN db.price.payment_link IS 'Shareable payment link URL that takes customers to a hosted payment page.';
COMMENT ON COLUMN db.price.metadata IS 'Full price object from the payment provider in JSON format.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.price (document);
CREATE INDEX ON db.price (currency);
CREATE INDEX ON db.price (product);

CREATE UNIQUE INDEX ON db.price (code);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_price_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := concat('price_', gen_random_code());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_price_insert
  BEFORE INSERT ON db.price
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_price_insert();
