--------------------------------------------------------------------------------
-- SERVICE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.service ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.service (
    id              uuid PRIMARY KEY,
    reference       uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE,
    category        uuid NOT NULL REFERENCES db.category(id),
    measure         uuid NOT NULL REFERENCES db.measure(id),
    value           numeric
);

COMMENT ON TABLE db.service IS 'Catalog of billable services linked to a category and unit of measure.';

COMMENT ON COLUMN db.service.id IS 'Primary key, matches the parent reference UUID.';
COMMENT ON COLUMN db.service.reference IS 'Link to the parent reference entry.';
COMMENT ON COLUMN db.service.category IS 'Service category for classification.';
COMMENT ON COLUMN db.service.measure IS 'Unit of measure for the service quantity.';
COMMENT ON COLUMN db.service.value IS 'Default quantity or rate value for the service.';

CREATE INDEX ON db.service (reference);
CREATE INDEX ON db.service (category);
CREATE INDEX ON db.service (measure);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_service_insert()
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

CREATE TRIGGER t_service_insert
  BEFORE INSERT ON db.service
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_service_insert();
