--------------------------------------------------------------------------------
-- db.card ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.card (
    id          uuid PRIMARY KEY,
    document    uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    client      uuid REFERENCES db.client(id),
    code        text NOT NULL,
    name        text,
    expiry      date,
    binding     text,
    sequence    integer NOT NULL DEFAULT 0
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.card IS 'Physical or virtual card that can be bound to a client and used for payments or device access.';

COMMENT ON COLUMN db.card.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.card.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.card.client IS 'Client who owns this card, if assigned.';
COMMENT ON COLUMN db.card.code IS 'Unique card code, auto-generated if not provided.';
COMMENT ON COLUMN db.card.name IS 'Display name or label for the card.';
COMMENT ON COLUMN db.card.expiry IS 'Expiration date of the card.';
COMMENT ON COLUMN db.card.binding IS 'Unique binding identifier linking the card to an external system.';
COMMENT ON COLUMN db.card.sequence IS 'Sort order among the client cards.';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.card (client, code);
CREATE UNIQUE INDEX ON db.card (binding);

CREATE INDEX ON db.card (document);
CREATE INDEX ON db.card (client);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_card_before_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := concat('card_', gen_random_code());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_card_before_insert
  BEFORE INSERT ON db.card
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_card_before_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_card_after_insert()
RETURNS trigger AS $$
DECLARE
  uUserId    uuid;
BEGIN
  IF NEW.client IS NOT NULL THEN
    uUserId := GetClientUserId(NEW.client);
    IF uUserId IS NOT NULL THEN
      UPDATE db.object SET owner = uUserId WHERE id = NEW.document;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_card_after_insert
  AFTER INSERT ON db.card
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_card_after_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_card_before_update()
RETURNS trigger AS $$
DECLARE
  uParent    uuid;
  uUserId    uuid;
BEGIN
  IF OLD.client IS NULL AND NEW.client IS NOT NULL THEN
    uUserId := GetClientUserId(NEW.client);
    PERFORM CheckObjectAccess(NEW.document, B'010', uUserId);
    SELECT parent INTO uParent FROM db.object WHERE id = NEW.document;
    IF uParent IS NOT NULL THEN
      PERFORM CheckObjectAccess(uParent, B'010', uUserId);
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_card_before_update
  BEFORE UPDATE ON db.card
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_card_before_update();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_card_after_update_client()
RETURNS trigger AS $$
DECLARE
  uUserId    uuid;
BEGIN
  IF NEW.client IS NOT NULL THEN
    uUserId := GetClientUserId(NEW.client);
    IF uUserId IS NOT NULL THEN
      INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'100';
    END IF;
  END IF;

  IF OLD.client IS NOT NULL THEN
    uUserId := GetClientUserId(OLD.client);
    IF uUserId IS NOT NULL THEN
      DELETE FROM db.aou WHERE object = OLD.document AND userid = uUserId;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_card_after_update_client
  AFTER UPDATE ON db.card
  FOR EACH ROW
  WHEN (OLD.client IS DISTINCT FROM NEW.client)
  EXECUTE PROCEDURE db.ft_card_after_update_client();

--------------------------------------------------------------------------------
-- db.card_data ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.card_data (
  card          uuid NOT NULL REFERENCES db.card(id) ON DELETE CASCADE,
  agent         uuid NOT NULL REFERENCES db.agent(id) ON DELETE RESTRICT,
  card_id       text,
  binding       text,
  encrypted     text,
  data          jsonb,
  created       timestamptz NOT NULL DEFAULT Now(),
  updated       timestamptz NOT NULL DEFAULT Now(),
  PRIMARY KEY (card, agent)
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.card_data IS 'Card integration data for online acquiring agents. Stores per-agent card identifiers and bindings.';

COMMENT ON COLUMN db.card_data.card IS 'Reference to the card.';
COMMENT ON COLUMN db.card_data.agent IS 'Acquiring agent (payment gateway) this data belongs to.';
COMMENT ON COLUMN db.card_data.card_id IS 'Card identifier in the agent system.';
COMMENT ON COLUMN db.card_data.binding IS 'Recurring payment or auto-pay binding identifier in the agent system.';
COMMENT ON COLUMN db.card_data.encrypted IS 'Encrypted card data (e.g., masked PAN, token).';
COMMENT ON COLUMN db.card_data.data IS 'Arbitrary card-related data in JSON format.';
COMMENT ON COLUMN db.card_data.created IS 'Timestamp when the record was created.';
COMMENT ON COLUMN db.card_data.updated IS 'Timestamp of the last update.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.card_data (card);
CREATE INDEX ON db.card_data (agent);

CREATE UNIQUE INDEX ON db.card_data (card, agent, binding);
