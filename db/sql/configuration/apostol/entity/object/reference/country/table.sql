--------------------------------------------------------------------------------
-- COUNTRY ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.country ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.country (
    id              uuid PRIMARY KEY,
    reference       uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE,
    alpha2          char(2) NOT NULL,
    alpha3          char(3),
    digital         integer,
    flag            text
);

COMMENT ON TABLE db.country IS 'Country reference based on ISO 3166-1 standard.';

COMMENT ON COLUMN db.country.id IS 'Primary key, matches the parent reference UUID.';
COMMENT ON COLUMN db.country.reference IS 'Link to the parent reference entry.';
COMMENT ON COLUMN db.country.alpha2 IS 'ISO 3166-1 alpha-2 letter code (e.g. "US", "RU").';
COMMENT ON COLUMN db.country.alpha3 IS 'ISO 3166-1 alpha-3 letter code (e.g. "USA", "RUS").';
COMMENT ON COLUMN db.country.digital IS 'ISO 3166-1 numeric code.';
COMMENT ON COLUMN db.country.flag IS 'Country flag image URL or emoji.';

CREATE INDEX ON db.country (reference);

CREATE INDEX ON db.country (alpha2);
CREATE INDEX ON db.country (alpha3);
CREATE INDEX ON db.country (digital);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_country_insert()
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

CREATE TRIGGER t_country_insert
  BEFORE INSERT ON db.country
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_country_insert();
