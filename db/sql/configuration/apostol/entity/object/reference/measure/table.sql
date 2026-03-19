--------------------------------------------------------------------------------
-- MEASURE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.measure ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.measure (
    id              uuid PRIMARY KEY,
    reference       uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE
);

COMMENT ON TABLE db.measure IS 'Master catalog of measurement units (e.g. kg, m, pcs).';

COMMENT ON COLUMN db.measure.id IS 'Primary key, matches the parent reference UUID.';
COMMENT ON COLUMN db.measure.reference IS 'Link to the parent reference entry.';

CREATE INDEX ON db.measure (reference);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_measure_insert()
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

CREATE TRIGGER t_measure_insert
  BEFORE INSERT ON db.measure
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_measure_insert();
