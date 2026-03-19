--------------------------------------------------------------------------------
-- db.product ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.product (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    code            text NOT NULL,
    name            text NOT NULL,
    default_price   text,
    tax_code        text,
    url             text,
    metadata        jsonb
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.product IS 'Product available for sale. Can have multiple prices and be linked to subscriptions and tariffs.';

COMMENT ON COLUMN db.product.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.product.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.product.code IS 'Unique product identifier (e.g., Stripe product ID).';
COMMENT ON COLUMN db.product.name IS 'Display name of the product.';
COMMENT ON COLUMN db.product.default_price IS 'Default price identifier for this product (e.g., Stripe Price ID).';
COMMENT ON COLUMN db.product.tax_code IS 'Tax classification code for this product.';
COMMENT ON COLUMN db.product.url IS 'Public URL for the product page.';
COMMENT ON COLUMN db.product.metadata IS 'Full product object from the payment provider in JSON format.';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.product (code);

CREATE INDEX ON db.product (document);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_product_before_insert()
RETURNS trigger AS $$
DECLARE
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := concat('prod_', gen_random_code());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_product_before_insert
  BEFORE INSERT ON db.product
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_product_before_insert();
