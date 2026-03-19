--------------------------------------------------------------------------------
-- CALENDAR --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.calendar ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Calendar API view.
 * @field {uuid} id - Identifier
 * @field {uuid} object - Reference identifier
 * @field {uuid} parent - Parent object identifier
 * @field {uuid} class - Class identifier
 * @field {text} code - Code
 * @field {text} name - Name
 * @field {text} description - Description
 * @field {integer} week - Working days per week
 * @field {integer[]} dayoff - Weekend days array [1..7, ...]
 * @field {integer[][]} holiday - Holiday array [[month,day], ...]
 * @field {interval} workstart - Work day start time
 * @field {interval} workcount - Working hours count
 * @field {interval} reststart - Break start time
 * @field {interval} restcount - Break hours count
 * @field {uuid} state - State identifier
 * @field {timestamp} lastupdate - Last update timestamp
 * @field {uuid} owner - Owner account identifier
 * @field {timestamp} created - Creation timestamp
 * @field {uuid} oper - Operator account identifier
 * @field {timestamp} operdate - Operation timestamp
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.calendar
AS
  SELECT * FROM ObjectCalendar;

GRANT SELECT ON api.calendar TO administrator;

--------------------------------------------------------------------------------
-- api.add_calendar ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new calendar.
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {integer} pWeek - Number of working days per week
 * @param {jsonb} pDayOff - Weekend days array [1..7, ...]
 * @param {jsonb} pHoliday - Holiday array [[month,day], ...], values [[1..12, 1..31], ...]
 * @param {interval} pWorkStart - Work day start time
 * @param {interval} pWorkCount - Working hours count
 * @param {interval} pRestStart - Break start time
 * @param {interval} pRestCount - Break hours count
 * @param {jsonb} pSchedule - Weekly schedule [[day_of_week, start_time, stop_time], ...]
 * @param {text} pDescription - Description
 * @return {uuid} - New calendar identifier
 * @since 1.0.0
 */
/**
 * @brief Creates a new calendar.
 * @return {uuid} - New calendar identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_calendar (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pWeek         integer,
  pDayOff       jsonb,
  pHoliday      jsonb,
  pWorkStart    interval,
  pWorkCount    interval,
  pRestStart    interval,
  pRestCount    interval,
  pSchedule     jsonb DEFAULT null,
  pDescription  text DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  r             record;

  aHoliday      integer[][2];
  aSchedule     text[][3];
BEGIN
  pHoliday := coalesce(pHoliday, '[[1,1], [1,7], [2,23], [3,8], [5,1], [5,9], [6,12], [11,4]]'::jsonb);

  IF pHoliday IS NOT NULL THEN
    aHoliday := ARRAY[[0,0]];
    IF jsonb_typeof(pHoliday) = 'array' THEN
      FOR r IN SELECT * FROM jsonb_array_elements(pHoliday)
      LOOP
        IF jsonb_typeof(r.value) = 'array' THEN
          aHoliday := array_cat(aHoliday, JsonbToIntArray(r.value));
        ELSE
          PERFORM IncorrectJsonType(jsonb_typeof(r.value), 'array');
        END IF;
      END LOOP;
    ELSE
      PERFORM IncorrectJsonType(jsonb_typeof(pHoliday), 'array');
    END IF;
  END IF;

  IF pSchedule IS NOT NULL THEN
    aSchedule := ARRAY[['0','0','0']];
    IF jsonb_typeof(pSchedule) = 'array' THEN
      FOR r IN SELECT * FROM jsonb_array_elements(pSchedule)
      LOOP
        IF jsonb_typeof(r.value) = 'array' THEN
          aSchedule := array_cat(aSchedule, JsonbToStrArray(r.value));
        ELSE
          PERFORM IncorrectJsonType(jsonb_typeof(r.value), 'array');
        END IF;
      END LOOP;
    ELSE
      PERFORM IncorrectJsonType(jsonb_typeof(pSchedule), 'array');
    END IF;
  END IF;

  RETURN CreateCalendar(pParent, coalesce(pType, GetType('workday.calendar')), pCode, pName, coalesce(pWeek, 5), JsonbToIntArray(coalesce(pDayOff, '[6,7]'::jsonb)), aHoliday[2:], coalesce(pWorkStart, '9 hour'::interval), coalesce(pWorkCount, '8 hour'::interval), coalesce(pRestStart, '13 hour'), coalesce(pRestCount, '1 hour'), aSchedule[2:], pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_calendar ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing calendar.
 * @param {uuid} pId - Calendar identifier
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {integer} pWeek - Number of working days per week
 * @param {jsonb} pDayOff - Weekend days array [1..7, ...]
 * @param {jsonb} pHoliday - Holiday array [[month,day], ...], values [[1..12, 1..31], ...]
 * @param {interval} pWorkStart - Work day start time
 * @param {interval} pWorkCount - Working hours count
 * @param {interval} pRestStart - Break start time
 * @param {interval} pRestCount - Break hours count
 * @param {jsonb} pSchedule - Weekly schedule [[day_of_week, start_time, stop_time], ...]
 * @param {text} pDescription - Description
 * @return {void}
 * @since 1.0.0
 */
/**
 * @brief Updates an existing calendar.
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_calendar (
  pId           uuid,
  pParent       uuid DEFAULT null,
  pType         uuid DEFAULT null,
  pCode         text DEFAULT null,
  pName         text DEFAULT null,
  pWeek         integer DEFAULT null,
  pDayOff       jsonb DEFAULT null,
  pHoliday      jsonb DEFAULT null,
  pWorkStart    interval DEFAULT null,
  pWorkCount    interval DEFAULT null,
  pRestStart    interval DEFAULT null,
  pRestCount    interval DEFAULT null,
  pSchedule     jsonb DEFAULT null,
  pDescription  text DEFAULT null
) RETURNS       void
AS $$
DECLARE
  r             record;
  nCalendar     uuid;
  aHoliday      integer[][2];
  aSchedule     text[][3];
BEGIN
  SELECT c.id INTO nCalendar FROM calendar c WHERE c.id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('календарь', 'id', pId);
  END IF;

  IF pHoliday IS NOT NULL THEN
    aHoliday := ARRAY[[0,0]];
    IF jsonb_typeof(pHoliday) = 'array' THEN
      FOR r IN SELECT * FROM jsonb_array_elements(pHoliday)
      LOOP
        IF jsonb_typeof(r.value) = 'array' THEN
          aHoliday := array_cat(aHoliday, JsonbToIntArray(r.value));
        ELSE
          PERFORM IncorrectJsonType(jsonb_typeof(r.value), 'array');
        END IF;
      END LOOP;
    ELSE
      PERFORM IncorrectJsonType(jsonb_typeof(pHoliday), 'array');
    END IF;
  END IF;

  IF pSchedule IS NOT NULL THEN
    aSchedule := ARRAY[['0','0','0']];
    IF jsonb_typeof(pSchedule) = 'array' THEN
      FOR r IN SELECT * FROM jsonb_array_elements(pSchedule)
      LOOP
        IF jsonb_typeof(r.value) = 'array' THEN
          aSchedule := array_cat(aSchedule, JsonbToStrArray(r.value));
        ELSE
          PERFORM IncorrectJsonType(jsonb_typeof(r.value), 'array');
        END IF;
      END LOOP;
    ELSE
      PERFORM IncorrectJsonType(jsonb_typeof(pSchedule), 'array');
    END IF;
  END IF;

  PERFORM EditCalendar(nCalendar, pParent, pType, pCode, pName, pWeek, JsonbToIntArray(pDayOff), aHoliday[2:], pWorkStart, pWorkCount, pRestStart, pRestCount, aSchedule[2:], pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_calendar ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a calendar (upsert).
 * @return {SETOF api.calendar} - Updated calendar record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_calendar (
  pId           uuid,
  pParent       uuid DEFAULT null,
  pType         uuid DEFAULT null,
  pCode         text DEFAULT null,
  pName         text DEFAULT null,
  pWeek         integer DEFAULT null,
  pDayOff       jsonb DEFAULT null,
  pHoliday      jsonb DEFAULT null,
  pWorkStart    interval DEFAULT null,
  pWorkCount    interval DEFAULT null,
  pRestStart    interval DEFAULT null,
  pRestCount    interval DEFAULT null,
  pSchedule     jsonb DEFAULT null,
  pDescription  text DEFAULT null
) RETURNS       SETOF api.calendar
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_calendar(pParent, pType, pCode, pName, pWeek, pDayOff, pHoliday, pWorkStart, pWorkCount, pRestStart, pRestCount, pSchedule, pDescription);
  ELSE
    PERFORM api.update_calendar(pId, pParent, pType, pCode, pName, pWeek, pDayOff, pHoliday, pWorkStart, pWorkCount, pRestStart, pRestCount, pSchedule, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.calendar WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_calendar ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a calendar by identifier.
 * @param {uuid} pId - Calendar identifier
 * @return {api.calendar} - Calendar record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_calendar (
  pId           uuid
) RETURNS       SETOF api.calendar
AS $$
  SELECT * FROM api.calendar WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_calendar -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a calendar by identifier.
 * @param {jsonb} pSearch - Search conditions: '[{"condition": "AND|OR", "field": "<field>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<value>"}, ...]'
 * @param {jsonb} pFilter - Filter: '{"<field>": "<value>"}'
 * @param {integer} pLimit - Row limit
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort by fields array
 * @return {SETOF api.calendar} - Calendar record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_calendar (
  pSearch       jsonb DEFAULT null,
  pFilter       jsonb DEFAULT null,
  pLimit        integer DEFAULT null,
  pOffSet       integer DEFAULT null,
  pOrderBy      jsonb DEFAULT null
) RETURNS       SETOF api.calendar
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'calendar', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION api.fill_calendar --------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Fills calendar with dates for a given period.
 * @param {uuid} pCalendar - Calendar identifier
 * @param {date} pDateFrom - Period start date
 * @param {date} pDateTo - Period end date
 * @param {uuid} pUserId - User account identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.fill_calendar (
  pCalendar     uuid,
  pDateFrom     date,
  pDateTo       date,
  pUserId       uuid DEFAULT null
) RETURNS       void
AS $$
BEGIN
  PERFORM FillCalendar(pCalendar, pDateFrom, pDateTo, pUserId);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- VIEW api.calendar_date ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief API view for calendar date records.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.calendar_date
AS
  SELECT * FROM calendar_date;

GRANT SELECT ON api.calendar_date TO administrator;

--------------------------------------------------------------------------------
-- VIEW api.calendardate -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief API view for extended calendar date records with calendar and user details.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.calendardate
AS
  SELECT * FROM CalendarDate;

GRANT SELECT ON api.calendardate TO administrator;

--------------------------------------------------------------------------------
-- FUNCTION api.list_calendar_date ---------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns calendar dates for a period. User-specific dates override common dates.
 * @param {uuid} pCalendar - Calendar identifier
 * @param {date} pDateFrom - Period start date
 * @param {date} pDateTo - Period end date
 * @param {uuid} pUserId - User account identifier
 * @return {SETOF api.calendar_date} - Calendar date records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_calendar_date (
  pCalendar     uuid,
  pDateFrom     date,
  pDateTo       date,
  pUserId       uuid DEFAULT null
) RETURNS       SETOF api.calendar_date
AS $$
  SELECT * FROM calendar_date(pCalendar, coalesce(pDateFrom, date_trunc('year', now())::date), coalesce(pDateTo, (date_trunc('year', now()) + INTERVAL '1 year' - INTERVAL '1 day')::date), pUserId) ORDER BY date;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION api.list_calendar_user ---------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns calendar dates for a specific user only.
 * @param {uuid} pCalendar - Calendar identifier
 * @param {date} pDateFrom - Period start date
 * @param {date} pDateTo - Period end date
 * @param {uuid} pUserId - User account identifier
 * @return {SETOF api.calendar_date} - Calendar date records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_calendar_user (
  pCalendar     uuid,
  pDateFrom     date,
  pDateTo       date,
  pUserId       uuid DEFAULT current_userid()
) RETURNS       SETOF api.calendar_date
AS $$
  SELECT *
    FROM calendar_date
   WHERE calendar = pCalendar
     AND (date >= coalesce(pDateFrom, date_trunc('year', now())::date) AND date < coalesce(pDateTo, (date_trunc('year', now()) + INTERVAL '1 year')::date))
     AND userid = coalesce(pUserId, userid)
   ORDER BY date
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION api.get_calendar_date ----------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a specific calendar date for a user.
 * @param {uuid} pCalendar - Calendar identifier
 * @param {date} pDate - Date
 * @param {uuid} pUserId - User account identifier
 * @return {api.calendardate} - Calendar date record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_calendar_date (
  pCalendar     uuid,
  pDate         date,
  pUserId       uuid DEFAULT null
) RETURNS       SETOF api.calendar_date
AS $$
  SELECT * FROM calendar_date(pCalendar, pDate, pDate, pUserId);
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION api.set_calendar_date ----------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Sets a calendar date entry (upsert).
 * @param {uuid} pCalendar - Calendar identifier
 * @param {date} pDate - Date
 * @param {bit} pFlag - Flag: 1000=pre-holiday, 0100=holiday, 0010=weekend, 0001=non-working, 0000=working
 * @param {interval} pWorkStart - Work day start time
 * @param {interval} pWorkCount - Working hours count
 * @param {interval} pRestStart - Break start time
 * @param {interval} pRestCount - Break hours count
 * @param {jsonb} pSchedule - Schedule [[start_time, stop_time], ...]
 * @param {uuid} pUserId - User account identifier
 * @out param {uuid} id - Calendar date identifier
 * @return {uuid}
 * @since 1.0.0
 */
/**
 * @brief Sets a calendar date entry (upsert).
 * @return {SETOF api.calendar_date} - Calendar date record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_calendar_date (
  pCalendar     uuid,
  pDate         date,
  pFlag         bit DEFAULT null,
  pWorkStart    interval DEFAULT null,
  pWorkCount    interval DEFAULT null,
  pRestStart    interval DEFAULT null,
  pRestCount    interval DEFAULT null,
  pSchedule     jsonb DEFAULT null,
  pUserId       uuid DEFAULT null
) RETURNS       SETOF api.calendar_date
AS $$
DECLARE
  r             record;
  uId           uuid;
  aSchedule     interval[][];
BEGIN
  IF pSchedule IS NOT NULL THEN
    aSchedule := ARRAY[[interval '00:00', interval '00:00']];
    IF jsonb_typeof(pSchedule) = 'array' THEN
      FOR r IN SELECT * FROM jsonb_array_elements(pSchedule)
      LOOP
        IF jsonb_typeof(r.value) = 'array' THEN
          aSchedule := array_cat(aSchedule, JsonbToIntervalArray(r.value));
        ELSE
          PERFORM IncorrectJsonType(jsonb_typeof(r.value), 'array');
        END IF;
      END LOOP;
    ELSE
      PERFORM IncorrectJsonType(jsonb_typeof(pSchedule), 'array');
    END IF;
  END IF;

  uId := GetCalendarDate(pCalendar, pDate, pUserId);
  IF uId IS NOT NULL THEN
    PERFORM EditCalendarDate(uId, pCalendar, pDate, pFlag, pWorkStart, pWorkCount, pRestStart, pRestCount, aSchedule[2:], pUserId);
  ELSE
    uId := AddCalendarDate(pCalendar, pDate, pFlag, pWorkStart, pWorkCount, pRestStart, pRestCount, aSchedule[2:], pUserId);
  END IF;

  RETURN QUERY SELECT * FROM api.calendar_date WHERE id = uId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION api.delete_calendar_date -------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Deletes a calendar date entry.
 * @param {uuid} pCalendar - Calendar identifier
 * @param {date} pDate - Date
 * @param {uuid} pUserId - User account identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.delete_calendar_date (
  pCalendar     uuid,
  pDate         date,
  pUserId       uuid DEFAULT null
) RETURNS       void
AS $$
DECLARE
  uId           uuid;
BEGIN
  uId := GetCalendarDate(pCalendar, pDate, pUserId);
  IF uId IS NOT NULL THEN
    PERFORM DeleteCalendarDate(uId);
  ELSE
    RAISE EXCEPTION 'ERR-40000: В календаре нет указанной даты для заданного пользователя.';
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
