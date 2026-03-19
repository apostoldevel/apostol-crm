--------------------------------------------------------------------------------
-- TASK ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.task ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.task (
    id			    uuid PRIMARY KEY,
    document	    uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    calendar        uuid NOT NULL REFERENCES db.calendar(id) ON DELETE RESTRICT,
    executor        uuid NOT NULL REFERENCES db.client(id) ON DELETE RESTRICT,
    read			boolean NOT NULL DEFAULT false,
    period			interval NOT NULL,
    validFromDate   timestamptz DEFAULT Now() NOT NULL,
    validToDate     timestamptz DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.task IS 'Task assigned to an executor with a deadline computed from a business calendar.';

COMMENT ON COLUMN db.task.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.task.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.task.calendar IS 'Business calendar used to compute the deadline.';
COMMENT ON COLUMN db.task.executor IS 'Client responsible for completing this task.';
COMMENT ON COLUMN db.task.read IS 'Whether the executor has read/acknowledged the task.';
COMMENT ON COLUMN db.task.period IS 'Execution period (duration). Used with the calendar to compute the deadline.';
COMMENT ON COLUMN db.task.validFromDate IS 'Start date of the task validity period.';
COMMENT ON COLUMN db.task.validToDate IS 'Computed deadline (end of the validity period).';

--------------------------------------------------------------------------------

CREATE INDEX ON db.task (document);
CREATE INDEX ON db.task (calendar);
CREATE INDEX ON db.task (executor);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_task_before_insert()
RETURNS trigger AS $$
DECLARE
  uOwner    uuid;
  uUserId   uuid;
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NEW.executor IS NOT NULL THEN
    SELECT owner INTO uOwner FROM db.object WHERE id = NEW.document;

    uUserId := GetClientUserId(NEW.executor);
    IF uOwner <> uUserId THEN
      UPDATE db.aou SET allow = allow | B'110' WHERE object = NEW.document AND userid = uUserId;
      IF NOT FOUND THEN
        INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'110';
      END IF;
    END IF;
  END IF;

  IF NEW.validFromDate IS NULL THEN
	NEW.validFromDate := Now();
  END IF;

  IF NEW.period IS NULL THEN
	NEW.period := interval '8 hour';
  END IF;

  IF NEW.validToDate IS NULL THEN
	NEW.validToDate := GetTaskValidToDate(NEW.calendar, NEW.validFromDate, NEW.period);
  ELSE
	NEW.period := GetTaskPeriod(NEW.calendar, NEW.validFromDate, NEW.validToDate);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_task_insert
  BEFORE INSERT ON db.task
  FOR EACH ROW
  EXECUTE PROCEDURE ft_task_before_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_task_before_update()
RETURNS trigger AS $$
BEGIN
  IF NEW.validFromDate IS NULL THEN
	NEW.validFromDate := Now();
  END IF;

  IF NEW.period IS NULL THEN
	NEW.period := interval '8 hour';
  END IF;

  IF (OLD.period <> NEW.period) OR (OLD.validFromDate <> NEW.validFromDate) OR (OLD.calendar <> NEW.calendar) THEN
	NEW.validToDate := GetTaskValidToDate(NEW.calendar, NEW.validFromDate, NEW.period);
  ELSIF OLD.validToDate <> NEW.validToDate THEN
	NEW.period := GetTaskPeriod(NEW.calendar, NEW.validFromDate, NEW.validToDate);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_task_before_update
  BEFORE UPDATE ON db.task
  FOR EACH ROW
  EXECUTE PROCEDURE ft_task_before_update();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_task_after_update()
RETURNS trigger AS $$
DECLARE
  uOwner    uuid;
  uUserId   uuid;
BEGIN
  IF OLD.executor <> NEW.executor THEN
    SELECT owner INTO uOwner FROM db.object WHERE id = NEW.document;

    IF NEW.executor IS NOT NULL THEN
      uUserId := GetClientUserId(NEW.executor);
      IF uOwner <> uUserId THEN
        UPDATE db.aou SET allow = allow | B'110' WHERE object = NEW.document AND userid = uUserId;
        IF NOT FOUND THEN
          INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'110';
        END IF;
      END IF;
    END IF;

    IF OLD.executor IS NOT NULL THEN
      uUserId := GetClientUserId(OLD.executor);
      IF uOwner <> uUserId THEN
        DELETE FROM db.aou WHERE object = OLD.document AND userid = uUserId;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_task_after_update
  AFTER UPDATE ON db.task
  FOR EACH ROW
  EXECUTE PROCEDURE ft_task_after_update();
