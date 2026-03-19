--------------------------------------------------------------------------------
-- PROPERTY --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.property -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.property (
    id              uuid PRIMARY KEY,
    reference       uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE
);

COMMENT ON TABLE db.property IS 'Reusable property definition for describing model characteristics.';

COMMENT ON COLUMN db.property.id IS 'Primary key, matches the parent reference UUID.';
COMMENT ON COLUMN db.property.reference IS 'Link to the parent reference entry.';

CREATE INDEX ON db.property (reference);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_property_insert()
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

CREATE TRIGGER t_property_insert
  BEFORE INSERT ON db.property
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_property_insert();
