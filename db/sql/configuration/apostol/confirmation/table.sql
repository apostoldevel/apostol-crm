--------------------------------------------------------------------------------
-- CONFIRMATION ----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.confirmation -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.confirmation (
  id                uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
  agent             uuid NOT NULL REFERENCES db.agent(id) ON DELETE RESTRICT,
  payment           uuid NOT NULL REFERENCES db.payment(id) ON DELETE RESTRICT,
  data              jsonb NOT NULL,
  validFromDate     timestamptz DEFAULT Now() NOT NULL,
  validToDate       timestamptz DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.confirmation IS 'Payment confirmation from an acquiring agent. Triggers a NOTIFY event on insert or data update.';

COMMENT ON COLUMN db.confirmation.id IS 'Primary key, auto-generated UUID.';
COMMENT ON COLUMN db.confirmation.agent IS 'Acquiring agent (payment gateway) that issued the confirmation.';
COMMENT ON COLUMN db.confirmation.payment IS 'Payment being confirmed.';
COMMENT ON COLUMN db.confirmation.data IS 'Confirmation payload from the agent in JSON format.';
COMMENT ON COLUMN db.confirmation.validFromDate IS 'Start of the confirmation validity period.';
COMMENT ON COLUMN db.confirmation.validToDate IS 'End of the confirmation validity period.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.confirmation (agent);
CREATE INDEX ON db.confirmation (payment);
CREATE INDEX ON db.confirmation (validFromDate, validToDate);

CREATE UNIQUE INDEX ON db.confirmation (payment, validFromDate, validToDate);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_confirmation_after_insert()
RETURNS trigger AS $$
BEGIN
  PERFORM pg_notify('confirmation', json_build_object('id', NEW.id, 'agent', NEW.agent, 'payment', NEW.payment)::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_confirmation_after_insert
  AFTER INSERT ON db.confirmation
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_confirmation_after_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_confirmation_after_update()
RETURNS trigger AS $$
BEGIN
  PERFORM pg_notify('confirmation', json_build_object('id', NEW.id, 'agent', NEW.agent, 'payment', NEW.payment)::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_confirmation_after_update
  AFTER UPDATE ON db.confirmation
  FOR EACH ROW
  WHEN (OLD.data IS DISTINCT FROM NEW.data)
  EXECUTE PROCEDURE db.ft_confirmation_after_update();
