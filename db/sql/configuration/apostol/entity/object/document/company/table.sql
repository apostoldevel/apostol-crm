--------------------------------------------------------------------------------
-- COMPANY ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.company ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.company (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    root            uuid NOT NULL REFERENCES db.company(id),
    node            uuid REFERENCES db.company(id),
    code            text NOT NULL,
    level           integer NOT NULL,
    sequence		integer NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.company IS 'Company entity organized in a tree hierarchy. Each company has a root, optional parent node, and nesting level.';

COMMENT ON COLUMN db.company.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.company.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.company.root IS 'Root node of the company tree (top-level ancestor).';
COMMENT ON COLUMN db.company.node IS 'Parent node in the company hierarchy.';
COMMENT ON COLUMN db.company.level IS 'Nesting depth in the hierarchy (0 = root).';
COMMENT ON COLUMN db.company.sequence IS 'Sort order among sibling companies.';

CREATE INDEX ON db.company (document);
CREATE INDEX ON db.company (root);
CREATE INDEX ON db.company (node);

CREATE UNIQUE INDEX ON db.company (code);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_company_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := concat('com_', gen_random_code());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_company_insert
  BEFORE INSERT ON db.company
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_company_insert();
