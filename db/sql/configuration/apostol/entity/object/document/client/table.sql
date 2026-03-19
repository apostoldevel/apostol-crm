--------------------------------------------------------------------------------
-- db.client -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.client (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    company         uuid NOT NULL REFERENCES db.company(id),
    userId          uuid REFERENCES db.user(id) ON DELETE RESTRICT,
    code            text NOT NULL,
    phone           text,
    email           text,
    birthday        date,
    birthplace      text,
    series          text,
    number          text,
    issued          text,
    issued_date     date,
    issued_code     text,
    inn             text,
    pin             text,
    kpp             text,
    ogrn            text,
    bic             text,
    account         text,
    address         text,
    photo           bytea,
    metadata        jsonb
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.client IS 'Client (individual or legal entity) belonging to a company. Central entity linking users, accounts, and documents.';

COMMENT ON COLUMN db.client.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.client.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.client.company IS 'Company this client belongs to.';
COMMENT ON COLUMN db.client.userid IS 'Associated user account for authentication, if any.';
COMMENT ON COLUMN db.client.code IS 'Unique client code, auto-generated if not provided. Synced to username.';
COMMENT ON COLUMN db.client.phone IS 'Contact phone number.';
COMMENT ON COLUMN db.client.email IS 'Contact email address.';
COMMENT ON COLUMN db.client.birthday IS 'Date of birth (individuals).';
COMMENT ON COLUMN db.client.birthplace IS 'Place of birth (individuals).';
COMMENT ON COLUMN db.client.series IS 'Identity document series (e.g., passport series).';
COMMENT ON COLUMN db.client.number IS 'Identity document number (e.g., passport number).';
COMMENT ON COLUMN db.client.issued IS 'Authority that issued the identity document.';
COMMENT ON COLUMN db.client.issued_date IS 'Date the identity document was issued.';
COMMENT ON COLUMN db.client.issued_code IS 'Issuing authority subdivision code.';
COMMENT ON COLUMN db.client.inn IS 'Taxpayer identification number (INN).';
COMMENT ON COLUMN db.client.pin IS 'Social insurance number (SNILS).';
COMMENT ON COLUMN db.client.kpp IS 'Tax registration reason code (KPP), for legal entities.';
COMMENT ON COLUMN db.client.ogrn IS 'Primary state registration number (OGRN/OGRNIP).';
COMMENT ON COLUMN db.client.bic IS 'Bank identifier code (BIC).';
COMMENT ON COLUMN db.client.account IS 'Bank settlement account number.';
COMMENT ON COLUMN db.client.address IS 'Postal or legal address.';
COMMENT ON COLUMN db.client.photo IS 'Client photo stored as binary data.';
COMMENT ON COLUMN db.client.metadata IS 'Additional client data in JSON format.';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.client (userid);
CREATE UNIQUE INDEX ON db.client (code);
CREATE UNIQUE INDEX ON db.client (inn);
CREATE UNIQUE INDEX ON db.client (pin);
CREATE UNIQUE INDEX ON db.client (ogrn);
CREATE UNIQUE INDEX ON db.client (account);
CREATE UNIQUE INDEX ON db.client (series, number);

CREATE INDEX ON db.client (document);
CREATE INDEX ON db.client (company);
CREATE INDEX ON db.client (phone);
CREATE INDEX ON db.client (email);

CREATE INDEX ON db.client USING GIN (metadata jsonb_path_ops);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_client_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := concat('client_', gen_random_code());
  END IF;

  IF NEW.userid IS NOT NULL THEN
    UPDATE db.object SET owner = NEW.userid WHERE id = NEW.document;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_client_insert
  BEFORE INSERT ON db.client
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_client_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_client_update()
RETURNS trigger AS $$
BEGIN
  IF NOT CheckObjectAccess(NEW.document, B'010') THEN
    PERFORM AccessDenied();
  END IF;

  IF OLD.userid IS NULL AND NEW.userid IS NOT NULL THEN
    UPDATE db.object SET owner = NEW.userid WHERE id = NEW.document;
  END IF;

  IF NEW.userid IS NOT NULL AND OLD.code IS DISTINCT FROM NEW.code THEN
    UPDATE db.user SET username = NEW.code WHERE id = NEW.userid;
  END IF;

  IF NEW.email IS NOT NULL THEN
    UPDATE db.user SET email = NEW.email WHERE id = NEW.userid;
  END IF;

  IF NEW.phone IS NOT NULL THEN
    UPDATE db.user SET phone = NEW.phone WHERE id = NEW.userid;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_client_update
  BEFORE UPDATE ON db.client
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_client_update();
