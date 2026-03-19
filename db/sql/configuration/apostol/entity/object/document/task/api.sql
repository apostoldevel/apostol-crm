--------------------------------------------------------------------------------
-- TASK ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.task --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.task
AS
  SELECT o.*, p.data::json AS binding
    FROM ObjectTask o LEFT JOIN db.object_data p ON o.object = p.object AND p.type = 'json' AND p.code = 'parent';

GRANT SELECT ON api.task TO administrator;

--------------------------------------------------------------------------------
-- FUNCTION api.task -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief api.task
 * @param {uuid} pState - State identifier
 * @param {timestamptz} pDateFrom - Start date
 * @return {SETOF api.task}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.task (
  pState    uuid,
  pDateFrom	timestamptz DEFAULT localtimestamp
) RETURNS	SETOF api.task
AS $$
  SELECT * FROM api.task WHERE state = pState AND validfromdate <= pDateFrom AND validtodate > pDateFrom;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.add_task ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Adds a new task
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCalendar - Calendar identifier
 * @param {uuid} pExecutor - Executor identifier
 * @param {text} pLabel - Label
 * @param {boolean} pRead - Read flag
 * @param {interval} pPeriod - Execution deadline
 * @param {timestamptz} pDateFrom - Period start date
 * @param {timestamptz} pDateTo - Period end date
 * @param {text} pDescription - Description
 * @param {uuid} pPriority - Priority
 * @param {text} pData - Additional data
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_task (
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
BEGIN
  pCalendar := coalesce(pCalendar, GetCalendar('default.calendar'));
  pPeriod := coalesce(pPeriod, INTERVAL '8 hour');
  RETURN CreateTask(pParent, coalesce(pType, GetType('user.task')), pCalendar, pExecutor, pLabel, pRead, pPeriod, pDateFrom, pDateTo, pDescription, pPriority, pData);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_task -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing task
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCalendar - Calendar identifier
 * @param {uuid} pExecutor - Executor identifier
 * @param {text} pLabel - Label
 * @param {boolean} pRead - Read flag
 * @param {interval} pPeriod - Execution deadline
 * @param {timestamptz} pDateFrom - Period start date
 * @param {timestamptz} pDateTo - Period end date
 * @param {text} pDescription - Description
 * @param {uuid} pPriority - Priority
 * @param {text} pData - Additional data
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_task (
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
  uTask             uuid;
BEGIN
  SELECT c.id INTO uTask FROM db.task c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('task', 'id', pId);
  END IF;

  PERFORM EditTask(uTask, pParent, pType, pCalendar, pExecutor, pLabel, pRead, pPeriod, pDateFrom, pDateTo, pDescription, pPriority, pData);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_task ----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a task (upsert)
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
 * @return {SETOF api.task}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_task (
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
) RETURNS           SETOF api.task
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_task(pParent, pType, pCalendar, pExecutor, pLabel, pRead, pPeriod, pDateFrom, pDateTo, pDescription, pPriority, pData);
  ELSE
    PERFORM api.update_task(pId, pParent, pType, pCalendar, pExecutor, pLabel, pRead, pPeriod, pDateFrom, pDateTo, pDescription, pPriority, pData);
  END IF;

  RETURN QUERY SELECT * FROM api.task WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_task ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a task by identifier
 * @param {uuid} pId - Identifier
 * @return {api.task}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_task (
  pId		uuid
) RETURNS	SETOF api.task
AS $$
  SELECT * FROM api.task WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_invoice -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of task records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_task (
  pSearch    jsonb default null,
  pFilter    jsonb default null
) RETURNS    SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('executor', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'task', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_task ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a filtered/sorted list of task records
 * @param {jsonb} pSearch - Search conditions array
 * @param {jsonb} pFilter - Filter object
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.task}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_task (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.task
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('executor', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'task', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.check_task --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Checks tasks for execution
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.check_task (
) RETURNS	void
AS $$
DECLARE
  vMessage      text;
  vContext      text;

  ErrorCode     int;
  ErrorMessage  text;
BEGIN
  PERFORM CheckTask();
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetErrorMessage(vMessage);

  SELECT * INTO ErrorCode, ErrorMessage FROM ParseMessage(vMessage);

  PERFORM WriteToEventLog('E', ErrorCode, ErrorMessage);
  PERFORM WriteToEventLog('D', ErrorCode, vContext);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
