--------------------------------------------------------------------------------
-- REGION ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.region -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.region (
    id              uuid PRIMARY KEY,
    reference       uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE
);

COMMENT ON TABLE db.region IS 'Geographic region or administrative division reference.';

COMMENT ON COLUMN db.region.id IS 'Primary key, matches the parent reference UUID.';
COMMENT ON COLUMN db.region.reference IS 'Link to the parent reference entry.';

CREATE INDEX ON db.region (reference);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_region_insert()
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

CREATE TRIGGER t_region_insert
  BEFORE INSERT ON db.region
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_region_insert();
