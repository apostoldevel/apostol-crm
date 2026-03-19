--------------------------------------------------------------------------------
-- ADDRESS ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.address (
    id          uuid PRIMARY KEY,
    reference   uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE,
    country     uuid NOT NULL REFERENCES db.country(id) ON DELETE CASCADE,
    kladr       text,
    index       text,
    region      text,
    district    text,
    city        text,
    settlement  text,
    street      text,
    house       text,
    building    text,
    structure   text,
    apartment   text,
    sortnum     integer NOT NULL
);

COMMENT ON TABLE db.address IS 'Structured postal address associated with an entity, supporting KLADR classification.';

COMMENT ON COLUMN db.address.id IS 'Primary key, matches the parent reference UUID.';
COMMENT ON COLUMN db.address.reference IS 'Link to the parent reference entry.';
COMMENT ON COLUMN db.address.kladr IS 'KLADR code: CC SS RRR GGG PPP UUUU where CC=country, SS=federal subject, RRR=district, GGG=city, PPP=settlement, UUUU=street.';
COMMENT ON COLUMN db.address.index IS 'Postal/ZIP code.';
COMMENT ON COLUMN db.address.country IS 'Country reference.';
COMMENT ON COLUMN db.address.region IS 'Region or federal subject name.';
COMMENT ON COLUMN db.address.district IS 'District or county name.';
COMMENT ON COLUMN db.address.city IS 'City name.';
COMMENT ON COLUMN db.address.settlement IS 'Settlement or locality name (village, township).';
COMMENT ON COLUMN db.address.street IS 'Street name.';
COMMENT ON COLUMN db.address.house IS 'House number.';
COMMENT ON COLUMN db.address.building IS 'Building or block number within a complex.';
COMMENT ON COLUMN db.address.structure IS 'Structure number (additional building identifier).';
COMMENT ON COLUMN db.address.apartment IS 'Apartment, suite, or unit number.';
COMMENT ON COLUMN db.address.sortnum IS 'Numeric position used for display ordering.';

CREATE INDEX ON db.address (reference);
CREATE INDEX ON db.address (country);
CREATE INDEX ON db.address (kladr);
CREATE INDEX ON db.address (index);
CREATE INDEX ON db.address (city);
CREATE INDEX ON db.address (street);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_address_insert()
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

CREATE TRIGGER t_address_insert
  BEFORE INSERT ON db.address
  FOR EACH ROW
  EXECUTE PROCEDURE ft_address_insert();
