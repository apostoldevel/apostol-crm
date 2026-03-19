--------------------------------------------------------------------------------
-- db.calendar -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.calendar (
    id            uuid PRIMARY KEY,
    reference     uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE,
    week          integer NOT NULL DEFAULT 5,
    dayoff        integer[] DEFAULT ARRAY[6,7],
    holiday       integer[][] DEFAULT ARRAY[[1,1], [1,7], [2,23], [3,8], [5,1], [5,9], [6,12], [11,4]],
    work_start    interval DEFAULT '9 hour',
    work_count    interval DEFAULT '8 hour',
    rest_start    interval DEFAULT '13 hour',
    rest_count    interval DEFAULT '1 hour',
    schedule      text[][] DEFAULT null,
    CHECK (week BETWEEN 1 AND 7),
    CHECK (min_array(dayoff) >= 1 AND max_array(dayoff) <= 7)
);

COMMENT ON TABLE db.calendar IS 'Work calendar defining business hours, days off, and holidays for scheduling.';

COMMENT ON COLUMN db.calendar.id IS 'Primary key, matches the parent reference UUID.';
COMMENT ON COLUMN db.calendar.reference IS 'Link to the parent reference entry.';
COMMENT ON COLUMN db.calendar.week IS 'Number of working days per week (1-7).';
COMMENT ON COLUMN db.calendar.dayoff IS 'Array of day-off day numbers within a week. Values range from 1 (Mon) to 7 (Sun).';
COMMENT ON COLUMN db.calendar.holiday IS 'Array of public holiday dates as [month, day] pairs, e.g. [[1,1], [12,31]].';
COMMENT ON COLUMN db.calendar.work_start IS 'Start of the working day as an interval offset from midnight.';
COMMENT ON COLUMN db.calendar.work_count IS 'Duration of the working day.';
COMMENT ON COLUMN db.calendar.rest_start IS 'Start of the lunch/rest break as an interval offset from midnight.';
COMMENT ON COLUMN db.calendar.rest_count IS 'Duration of the lunch/rest break.';
COMMENT ON COLUMN db.calendar.schedule IS 'Weekly schedule override. Format: [[day_of_week, start_time, stop_time], ...].';

CREATE INDEX ON db.calendar (reference);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_calendar_insert()
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

CREATE TRIGGER t_calendar_insert
  BEFORE INSERT ON db.calendar
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_calendar_insert();

--------------------------------------------------------------------------------
-- db.cdate --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.cdate (
    id              uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    calendar        uuid NOT NULL REFERENCES db.calendar(id) ON DELETE CASCADE,
    date            date NOT NULL,
    flag            bit(4) NOT NULL DEFAULT B'0000',
    work_start      interval,
    work_count      interval,
    rest_start      interval,
    rest_count      interval,
    schedule        interval[][] DEFAULT null,
    userid          uuid REFERENCES db.user(id)
);

COMMENT ON TABLE db.cdate IS 'Individual calendar date entries with per-day overrides for work hours and flags.';

COMMENT ON COLUMN db.cdate.id IS 'Primary key (auto-generated UUID).';
COMMENT ON COLUMN db.cdate.calendar IS 'Parent calendar this date belongs to.';
COMMENT ON COLUMN db.cdate.date IS 'Calendar date.';
COMMENT ON COLUMN db.cdate.flag IS 'Day type bitmask: 1000 = pre-holiday, 0100 = holiday, 0010 = day off, 0001 = non-working, 0000 = working.';
COMMENT ON COLUMN db.cdate.work_start IS 'Start of the working day (overrides calendar default).';
COMMENT ON COLUMN db.cdate.work_count IS 'Duration of the working day (overrides calendar default).';
COMMENT ON COLUMN db.cdate.rest_start IS 'Start of the rest break (overrides calendar default).';
COMMENT ON COLUMN db.cdate.rest_count IS 'Duration of the rest break (overrides calendar default).';
COMMENT ON COLUMN db.cdate.schedule IS 'Per-day schedule override. Format: [[start_time, stop_time], ...].';

--------------------------------------------------------------------------------

CREATE INDEX ON db.cdate (calendar);
CREATE INDEX ON db.cdate (date);
CREATE INDEX ON db.cdate (userid);

CREATE UNIQUE INDEX ON db.cdate (calendar, date, userid);
