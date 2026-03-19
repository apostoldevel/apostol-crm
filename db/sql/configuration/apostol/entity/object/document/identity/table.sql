--------------------------------------------------------------------------------
-- db.identity -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.identity (
    id			    uuid PRIMARY KEY,
    document		uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    type            uuid NOT NULL REFERENCES db.type(id) ON DELETE RESTRICT,
    country         uuid NOT NULL REFERENCES db.country(id) ON DELETE RESTRICT,
    client          uuid NOT NULL REFERENCES db.client(id) ON DELETE RESTRICT,
    series          text,
    number          text NOT NULL,
    identity        text GENERATED ALWAYS AS (coalesce(series || ' ' || number, number)) STORED,
    code            text,
    issued          text,
    date            date,
    photo           bytea,
    reminderDate    timestamptz,
    validFromDate	timestamptz DEFAULT NOW() NOT NULL,
    validToDate		timestamptz DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL
);

COMMENT ON TABLE db.identity IS 'Identity document (passport, driver license, etc.) issued to a client with a validity period.';

COMMENT ON COLUMN db.identity.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.identity.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.identity.type IS 'Type of identity document (passport, license, etc.).';
COMMENT ON COLUMN db.identity.country IS 'Country of citizenship or document origin.';
COMMENT ON COLUMN db.identity.client IS 'Client who holds this identity document.';
COMMENT ON COLUMN db.identity.series IS 'Document series (e.g., passport series).';
COMMENT ON COLUMN db.identity.number IS 'Document number.';
COMMENT ON COLUMN db.identity.identity IS 'Combined series and number (auto-generated, read-only stored column).';
COMMENT ON COLUMN db.identity.code IS 'Issuing authority subdivision code or other auxiliary code.';
COMMENT ON COLUMN db.identity.issued IS 'Name of the authority that issued the document.';
COMMENT ON COLUMN db.identity.date IS 'Date the document was issued.';
COMMENT ON COLUMN db.identity.photo IS 'Photo or scan of the document stored as binary data.';
COMMENT ON COLUMN db.identity.reminderDate IS 'Date to send an expiration reminder.';
COMMENT ON COLUMN db.identity.validFromDate IS 'Start of the document validity period.';
COMMENT ON COLUMN db.identity.validToDate IS 'End of the document validity period.';

CREATE UNIQUE INDEX ON db.identity (type, identity);
CREATE UNIQUE INDEX ON db.identity (type, client, validFromDate, validToDate);

CREATE INDEX ON db.identity (document);
CREATE INDEX ON db.identity (type);
CREATE INDEX ON db.identity (country);
CREATE INDEX ON db.identity (client);
CREATE INDEX ON db.identity (identity);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_identity_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NEW.type IS NULL THEN
    SELECT type INTO NEW.type FROM db.object WHERE id = NEW.document;
  END IF;

  IF NEW.date IS NOT NULL THEN
	SELECT NEW.date INTO NEW.validfromdate;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_identity_insert
  BEFORE INSERT ON db.identity
  FOR EACH ROW
  EXECUTE PROCEDURE ft_identity_insert();
