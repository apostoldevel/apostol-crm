--------------------------------------------------------------------------------
-- SUBSCRIPTION ----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.subscription -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.subscription (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    price           uuid NOT NULL REFERENCES db.price(id),
    client          uuid REFERENCES db.client(id),
    code            text NOT NULL,
    customer        text NOT NULL,
    period_start    timestamptz NOT NULL DEFAULT Now(),
    period_end      timestamptz NOT NULL DEFAULT Now() + INTERVAL '1 month', 
    metadata        jsonb NOT NULL,
    current         bool NOT NULL DEFAULT false
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.subscription IS 'Client subscription to a product at a specific price with a billing period.';

COMMENT ON COLUMN db.subscription.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.subscription.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.subscription.price IS 'Price tier this subscription is linked to.';
COMMENT ON COLUMN db.subscription.client IS 'Client who holds this subscription.';
COMMENT ON COLUMN db.subscription.code IS 'Unique subscription code, auto-generated if not provided.';
COMMENT ON COLUMN db.subscription.customer IS 'External customer identifier in the payment provider (e.g., Stripe customer ID).';
COMMENT ON COLUMN db.subscription.period_start IS 'Start of the current billing period.';
COMMENT ON COLUMN db.subscription.period_end IS 'End of the current billing period.';
COMMENT ON COLUMN db.subscription.metadata IS 'Additional subscription data in JSON format.';
COMMENT ON COLUMN db.subscription.current IS 'Whether this is the currently active subscription for the client.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.subscription (document);
CREATE INDEX ON db.subscription (price);
CREATE INDEX ON db.subscription (client);
CREATE INDEX ON db.subscription (customer);

CREATE UNIQUE INDEX ON db.subscription (code);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_subscription_insert()
RETURNS trigger AS $$
DECLARE
  uOwner    uuid;
  uUserId   uuid;
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := concat('sub_', gen_random_code());
  END IF;

  IF NEW.client IS NOT NULL THEN
    SELECT owner INTO uOwner FROM db.object WHERE id = NEW.document;

    uUserId := GetClientUserId(NEW.client);
    IF uOwner <> uUserId THEN
      UPDATE db.aou SET allow = allow | B'110' WHERE object = NEW.document AND userid = uUserId;
      IF NOT FOUND THEN
        INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'110';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_subscription_insert
  BEFORE INSERT ON db.subscription
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_subscription_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_subscription_after_update()
RETURNS trigger AS $$
DECLARE
  uOwner    uuid;
  uUserId   uuid;
BEGIN
  SELECT owner INTO uOwner FROM db.object WHERE id = NEW.document;

  IF NEW.client IS NOT NULL THEN
    uUserId := GetClientUserId(NEW.client);
    IF uOwner <> uUserId THEN
      UPDATE db.aou SET allow = allow | B'110' WHERE object = NEW.document AND userid = uUserId;
      IF NOT FOUND THEN
        INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'110';
      END IF;
    END IF;
  END IF;

  IF OLD.client IS NOT NULL THEN
    uUserId := GetClientUserId(OLD.client);
    IF uOwner <> uUserId THEN
      DELETE FROM db.aou WHERE object = OLD.document AND userid = uUserId;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

CREATE TRIGGER t_subscription_after_update
  AFTER UPDATE ON db.subscription
  FOR EACH ROW
  WHEN (OLD.client IS DISTINCT FROM NEW.client)
  EXECUTE PROCEDURE db.ft_subscription_after_update();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_subscription_price_update()
RETURNS trigger AS $$
BEGIN
  PERFORM SubscriptionSwitch(NEW.id, NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

CREATE TRIGGER t_subscription_price_update
  AFTER UPDATE ON db.subscription
  FOR EACH ROW
  WHEN (OLD.price IS DISTINCT FROM NEW.price)
  EXECUTE PROCEDURE db.ft_subscription_price_update();
