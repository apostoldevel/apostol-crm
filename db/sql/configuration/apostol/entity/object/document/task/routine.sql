--------------------------------------------------------------------------------
-- CreateTask ------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new task
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCalendar - Calendar
 * @param {uuid} pExecutor - Executor
 * @param {text} pLabel - Label
 * @param {boolean} pRead - Read
 * @param {interval} pPeriod - Period
 * @param {timestamptz} pDateFrom - Start date
 * @param {timestamptz} pDateTo - End date
 * @param {text} pDescription - Description
 * @param {uuid} pPriority - Message priority
 * @param {text} pData - Additional data
 * @return {uuid}
 * @throws IncorrectClassType
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateTask (
  pParent           uuid,
  pType             uuid,
  pCalendar         uuid,
  pExecutor         uuid,
  pLabel            text,
  pRead				boolean default null,
  pPeriod			interval default null,
  pDateFrom			timestamptz default null,
  pDateTo			timestamptz default null,
  pDescription      text default null,
  pPriority         uuid default null,
  pData				text default null
) RETURNS           uuid
AS $$
DECLARE
  uId				uuid;
  uDocument         uuid;
  uClass            uuid;
  uMethod           uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetClassCode(uClass) <> 'task' THEN
    PERFORM IncorrectClassType();
  END IF;

  SELECT id INTO uId FROM db.calendar WHERE id = pCalendar;

  IF NOT FOUND THEN
	PERFORM ObjectNotFound('calendar', 'id', pCalendar);
  END IF;

  uDocument := CreateDocument(pParent, pType, pLabel, pDescription, coalesce(pData, pDescription), null, pPriority);

  INSERT INTO db.task (id, document, calendar, executor, read, period, validFromDate, validToDate)
  VALUES (uDocument, uDocument, pCalendar, pExecutor, coalesce(pRead, false), pPeriod, pDateFrom, pDateTo);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uDocument, uMethod);

  RETURN uDocument;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditTask --------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Edits an existing task
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCalendar - Calendar
 * @param {uuid} pExecutor - Executor
 * @param {text} pLabel - Label
 * @param {boolean} pRead - Read
 * @param {interval} pPeriod - Period
 * @param {timestamptz} pDateFrom - Start date
 * @param {timestamptz} pDateTo - End date
 * @param {text} pDescription - Description
 * @param {uuid} pPriority - Message priority
 * @param {text} pData - Additional data
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditTask (
  pId               uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pCalendar         uuid default null,
  pExecutor         uuid default null,
  pLabel            text default null,
  pRead				boolean default null,
  pPeriod			interval default null,
  pDateFrom			timestamptz default null,
  pDateTo			timestamptz default null,
  pDescription      text default null,
  pPriority         uuid default null,
  pData				text default null
) RETURNS           void
AS $$
DECLARE
  old               db.task%rowtype;
  new               db.task%rowtype;

  uClass            uuid;
  uMethod           uuid;
BEGIN
  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription, coalesce(pData, pDescription), current_locale(), pPriority);

  SELECT * INTO old FROM db.task WHERE id = pId;

  UPDATE db.task
     SET calendar = coalesce(pCalendar, calendar),
         executor = coalesce(pExecutor, executor),
         read = coalesce(pRead, read),
         period = coalesce(pPeriod, period),
         validFromDate = coalesce(pDateFrom, validFromDate),
         validToDate = coalesce(pDateTo, validToDate)
   WHERE id = pId;

  SELECT * INTO new FROM db.task WHERE id = pId;

  SELECT class INTO uClass FROM db.object WHERE id = pId;

  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod, jsonb_build_object('old', row_to_json(old), 'new', row_to_json(new)));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetTaskValidToDate ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the task by code
 * @param {uuid} pCalendar - Calendar
 * @param {timestamptz} pDateFrom - Start date
 * @param {interval} pPeriod - Period
 * @param {uuid} pUserId - User identifier
 * @return {timestamptz}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetTaskValidToDate (
  pCalendar		uuid,
  pDateFrom		timestamptz DEFAULT Now(),
  pPeriod		interval DEFAULT '8 hour',
  pUserId		uuid DEFAULT current_userid()
) RETURNS		timestamptz
AS $$
DECLARE
  r				record;
  c				record;
  wDate			date;
  iDelta		interval;
  dtDateTo		timestamptz;
BEGIN
  dtDateTo := pDateFrom;
  iDelta := pPeriod;

  SELECT work_start, work_count, rest_count INTO c FROM db.calendar WHERE id = pCalendar;

  wDate := date_trunc('DAY', dtDateTo);
  IF dtDateTo >= wDate + c.work_start + c.work_count + c.rest_count THEN
	dtDateTo := dtDateTo + interval '1 day';
  END IF;

  LOOP
    wDate := date_trunc('DAY', dtDateTo);
  	SELECT date, workstop, workcount INTO r FROM calendar_date(pCalendar, wDate, wDate, pUserId);

	EXIT WHEN NOT FOUND;

	IF r.workcount IS NOT NULL THEN
      iDelta := iDelta - LEAST(iDelta, r.workcount);
      EXIT WHEN iDelta = interval '0 month 0 day 0 hour 0 minute';
      pPeriod := pPeriod - r.workcount;
	END IF;

	dtDateTo := dtDateTo + interval '1 day';
  END LOOP;

  IF pPeriod > c.work_count / 2 THEN
	pPeriod := pPeriod + c.rest_count;
  END IF;

  RETURN wDate + c.work_start + pPeriod;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetTaskPeriod ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the task by code
 * @param {uuid} pCalendar - Calendar
 * @param {timestamptz} pDateFrom - Start date
 * @param {timestamptz} pDateTo - End date
 * @param {uuid} pUserId - User identifier
 * @return {interval}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetTaskPeriod (
  pCalendar		uuid,
  pDateFrom		timestamptz DEFAULT Now(),
  pDateTo		timestamptz DEFAULT Now(),
  pUserId		uuid DEFAULT current_userid()
) RETURNS		interval
AS $$
DECLARE
  r				record;

  dtDateFrom	date;
  dtDateTo		date;

  wPeriod		interval;
BEGIN
  dtDateFrom := date_trunc('DAY', pDateFrom);
  dtDateTo := date_trunc('DAY', pDateTo);

  wPeriod := interval '0 month 0 day 0 hour 0 minute';

  FOR r IN SELECT date, workstart, workcount, reststart, restcount FROM calendar_date(pCalendar, dtDateFrom, dtDateTo, pUserId) ORDER BY date
  LOOP
    IF r.workcount IS NOT NULL THEN
	  IF r.date = dtDateTo THEN
		IF pDateTo > r.date + coalesce(r.workstart, interval '0') THEN
		  wPeriod := wPeriod + LEAST(r.workcount, pDateTo - (r.date + coalesce(r.workstart, interval '0')));
		  IF pDateTo > r.date + coalesce(r.reststart, interval '13 hour') THEN
			wPeriod := wPeriod - coalesce(r.restcount, interval '1 hour');
		  END IF;
		END IF;
	  ELSE
        wPeriod := wPeriod + r.workcount;
      END IF;
    END IF;
  END LOOP;

  RETURN coalesce(wPeriod, interval '1 day');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CheckTask -------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Checks tasks for execution
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CheckTask (
) RETURNS	void
AS $$
DECLARE
  r			record;

  uEnable	uuid;
  uExpire	uuid;
BEGIN
  uEnable := GetAction('enable');
  uExpire := GetAction('expire');

  FOR r IN
	SELECT t.id
	  FROM db.task t INNER JOIN db.object o ON t.document = o.id AND o.scope = current_scope()
					 INNER JOIN db.state  s ON o.state = s.id AND s.code = 'enabled'
	 WHERE t.validToDate <= now()
  LOOP
	PERFORM ExecuteObjectAction(r.id, uExpire);
  END LOOP;

  FOR r IN
	SELECT t.id
	  FROM db.task t INNER JOIN db.object o ON t.document = o.id AND o.scope = current_scope()
					 INNER JOIN db.state  s ON o.state = s.id AND s.code = 'postponed'
	 WHERE t.validFromDate <= now()
  LOOP
	PERFORM ExecuteObjectAction(r.id, uEnable);
  END LOOP;

  FOR r IN
	SELECT t.id
	  FROM db.task t INNER JOIN db.object o ON t.document = o.id AND o.scope = current_scope()
					 INNER JOIN db.state  s ON o.state = s.id AND s.code = 'planned'
	 WHERE t.validFromDate <= now()
  LOOP
	PERFORM ExecuteObjectAction(r.id, uEnable);
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
