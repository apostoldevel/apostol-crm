--------------------------------------------------------------------------------
-- FORMAT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.format -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.format (
    id              uuid PRIMARY KEY,
    reference       uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE
);

COMMENT ON TABLE db.format IS 'Data format definition used for parsing and rendering values.';

COMMENT ON COLUMN db.format.id IS 'Primary key, matches the parent reference UUID.';
COMMENT ON COLUMN db.format.reference IS 'Link to the parent reference entry.';

CREATE INDEX ON db.format (reference);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_format_insert()
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

CREATE TRIGGER t_format_insert
  BEFORE INSERT ON db.format
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_format_insert();
