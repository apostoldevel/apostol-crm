--------------------------------------------------------------------------------
-- TARIFF ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.tariff -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.tariff (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    product         uuid NOT NULL REFERENCES db.product(id),
    currency        uuid NOT NULL REFERENCES db.currency(id),
    service         uuid NOT NULL REFERENCES db.service(id),
    tag             text NOT NULL DEFAULT 'default',
    code            text NOT NULL,
    price           numeric(12,4) NOT NULL,
    commission      numeric(12,2) DEFAULT 0 NOT NULL,
    tax             numeric(12,2) DEFAULT 0 NOT NULL
);

COMMENT ON TABLE db.tariff IS 'Tariff defining the price, commission, and tax for a specific service, product, and currency combination.';

COMMENT ON COLUMN db.tariff.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.tariff.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.tariff.product IS 'Product this tariff applies to.';
COMMENT ON COLUMN db.tariff.service IS 'Service this tariff applies to.';
COMMENT ON COLUMN db.tariff.currency IS 'Currency in which the tariff is denominated.';
COMMENT ON COLUMN db.tariff.tag IS 'Tag for distinguishing tariff variants (default: "default").';
COMMENT ON COLUMN db.tariff.code IS 'Unique tariff code, auto-generated if not provided.';
COMMENT ON COLUMN db.tariff.price IS 'Unit price for the service.';
COMMENT ON COLUMN db.tariff.commission IS 'Commission rate as a percentage.';
COMMENT ON COLUMN db.tariff.tax IS 'Tax rate as a percentage.';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.tariff (code);
CREATE UNIQUE INDEX ON db.tariff (product, service, currency, tag);

CREATE INDEX ON db.tariff (document);
CREATE INDEX ON db.tariff (product);
CREATE INDEX ON db.tariff (service);
CREATE INDEX ON db.tariff (currency);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_tariff_before_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := concat('tariff_', gen_random_code());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_tariff_before_insert
  BEFORE INSERT ON db.tariff
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_tariff_before_insert();

--------------------------------------------------------------------------------
-- db.tariff_scheme ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.tariff_scheme (
    service         uuid NOT NULL REFERENCES db.service(id),
    currency        uuid NOT NULL REFERENCES db.currency(id),
    tag             text NOT NULL DEFAULT 'default',
    price           numeric(12,4) NOT NULL,
    commission      numeric(12,2) DEFAULT 0 NOT NULL,
    tax             numeric(12,2) DEFAULT 0 NOT NULL,
    PRIMARY KEY (service, currency, tag)
);

COMMENT ON TABLE db.tariff_scheme IS 'Default tariff scheme that provides fallback pricing when no specific tariff document exists.';

COMMENT ON COLUMN db.tariff_scheme.service IS 'Service this scheme applies to.';
COMMENT ON COLUMN db.tariff_scheme.currency IS 'Currency for the scheme pricing.';
COMMENT ON COLUMN db.tariff_scheme.tag IS 'Tag for distinguishing scheme variants (default: "default").';
COMMENT ON COLUMN db.tariff_scheme.price IS 'Unit price for the service.';
COMMENT ON COLUMN db.tariff_scheme.commission IS 'Commission rate as a percentage.';
COMMENT ON COLUMN db.tariff_scheme.tax IS 'Tax rate as a percentage.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.tariff_scheme (service);
CREATE INDEX ON db.tariff_scheme (currency);
