--------------------------------------------------------------------------------
-- CATEGORY --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.category -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.category (
    id          uuid PRIMARY KEY,
    reference   uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE
);

COMMENT ON TABLE db.category IS 'Generic classification category for grouping services, models, and other entities.';

COMMENT ON COLUMN db.category.id IS 'Primary key, matches the parent reference UUID.';
COMMENT ON COLUMN db.category.reference IS 'Link to the parent reference entry.';

CREATE INDEX ON db.category (reference);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_category_insert()
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

CREATE TRIGGER t_category_insert
  BEFORE INSERT ON db.category
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_category_insert();

