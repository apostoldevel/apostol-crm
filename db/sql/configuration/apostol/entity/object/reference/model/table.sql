--------------------------------------------------------------------------------
-- MODEL -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.model --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.model (
    id              uuid PRIMARY KEY,
    reference       uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE,
    vendor          uuid NOT NULL REFERENCES db.vendor(id) ON DELETE RESTRICT,
    category        uuid REFERENCES db.category(id) ON DELETE RESTRICT
);

COMMENT ON TABLE db.model IS 'Equipment or product model associated with a vendor and optional category.';

COMMENT ON COLUMN db.model.id IS 'Primary key, matches the parent reference UUID.';
COMMENT ON COLUMN db.model.reference IS 'Link to the parent reference entry.';
COMMENT ON COLUMN db.model.vendor IS 'Vendor (manufacturer) of this model.';
COMMENT ON COLUMN db.model.category IS 'Optional category for model classification.';

CREATE INDEX ON db.model (reference);
CREATE INDEX ON db.model (vendor);
CREATE INDEX ON db.model (category);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_model_insert()
RETURNS trigger AS $$
DECLARE
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

CREATE TRIGGER t_model_insert
  BEFORE INSERT ON db.model
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_model_insert();

--------------------------------------------------------------------------------
-- db.model_property -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.model_property (
    model       uuid NOT NULL REFERENCES db.model(id) ON DELETE CASCADE,
    property    uuid NOT NULL REFERENCES db.property(id) ON DELETE RESTRICT,
    measure     uuid REFERENCES db.measure(id),
    value       variant,
    format      text,
    sequence    integer NOT NULL,
    PRIMARY KEY (model, property)
);

COMMENT ON TABLE db.model_property IS 'Property values assigned to a model, linking properties with measures and display order.';

COMMENT ON COLUMN db.model_property.model IS 'Parent model this property belongs to.';
COMMENT ON COLUMN db.model_property.property IS 'Property definition reference.';
COMMENT ON COLUMN db.model_property.measure IS 'Optional unit of measure for the property value.';
COMMENT ON COLUMN db.model_property.value IS 'Property value stored as a variant type.';
COMMENT ON COLUMN db.model_property.format IS 'Display format string for rendering the value.';
COMMENT ON COLUMN db.model_property.sequence IS 'Sort order for display purposes.';

CREATE INDEX ON db.model_property (model);
CREATE INDEX ON db.model_property (property);
CREATE INDEX ON db.model_property (measure);

--------------------------------------------------------------------------------
