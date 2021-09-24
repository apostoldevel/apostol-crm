--------------------------------------------------------------------------------
-- MODE ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.mode ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.mode (
    id			    uuid PRIMARY KEY,
    reference		uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE
);

COMMENT ON TABLE db.mode IS 'Режим.';

COMMENT ON COLUMN db.mode.id IS 'Идентификатор.';
COMMENT ON COLUMN db.mode.reference IS 'Справочник.';

CREATE INDEX ON db.mode (reference);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_mode_insert()
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

CREATE TRIGGER t_mode_insert
  BEFORE INSERT ON db.mode
  FOR EACH ROW
  EXECUTE PROCEDURE ft_mode_insert();
