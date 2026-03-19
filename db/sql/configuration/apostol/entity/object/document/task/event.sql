--------------------------------------------------------------------------------
-- TASK ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventTaskCreate -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the task creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskCreate (
  pObject		uuid default context_object()
) RETURNS		void
AS $$
DECLARE
  dtNow			timestamptz;
  dtFromDate	timestamptz;
  dtToDate		timestamptz;
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Task created.', pObject);

  SELECT validfromdate, validtodate INTO dtFromDate, dtToDate FROM db.task WHERE id = pObject;

  dtNow := Now();

  IF dtFromDate <= dtNow AND dtToDate > dtNow THEN
  	PERFORM ExecuteObjectAction(pObject, GetAction('enable'));
  ELSIF dtFromDate < dtNow AND dtToDate < dtNow THEN
  	PERFORM ExecuteObjectAction(pObject, GetAction('postpone'));
  ELSIF dtFromDate > dtNow AND dtToDate > dtNow THEN
  	PERFORM ExecuteObjectAction(pObject, GetAction('plan'));
  ELSE
    PERFORM IncorrectDateInterval();
  END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTaskEdit ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the task edit event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskEdit (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r         record;
  uParent   uuid;
BEGIN
  SELECT parent INTO uParent FROM db.object WHERE id = pObject;

  IF uParent IS NOT NULL THEN
    SELECT * INTO r FROM Object WHERE id = uParent;
    PERFORM SetObjectDataJSON(pObject, 'parent', row_to_json(r));
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'edit', 'Task modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTaskSave ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the task save event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskSave (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Task saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTaskEnable -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the task enable event
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskEnable (
  pObject		uuid default context_object(),
  pParams		jsonb default context_params()
) RETURNS		void
AS $$
DECLARE
  r				record;
  arKeys		text[];
BEGIN
  IF pParams IS NOT NULL THEN
	arKeys := array_cat(arKeys, ARRAY['period', 'fromdate', 'todate']);
	PERFORM CheckJsonbKeys('/task/enable', arKeys, pParams);

	FOR r IN SELECT * FROM jsonb_to_recordset(pParams) AS x(period interval, fromdate timestamptz, todate timestamptz)
	LOOP
	  UPDATE db.task SET period = r.period, validFromDate = r.fromdate, validtodate = r.todate WHERE id = pObject;
	END LOOP;
  ELSE
	UPDATE db.task SET period = INTERVAL '8 hour', validFromDate = Now() WHERE id = pObject;
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'enable', 'Task enabled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTaskDisable ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the task disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskDisable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'disable', 'Task completed.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTaskDelete -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the task delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskDelete (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Task deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTaskRestore ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the task restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskRestore (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Task restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTaskComplete -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the task complete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskComplete (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'complete', 'Task fulfilled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTaskReturn -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the task return event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskReturn (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'return', 'Task returned.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTaskExpire -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the task expire event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskExpire (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'expire', 'Task expired.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTaskPlan ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief EventTaskPlan
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskPlan (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'plan', 'Task scheduled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTaskPostpone -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the task postpone event
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskPostpone (
  pObject		uuid default context_object(),
  pParams		jsonb default context_params()
) RETURNS		void
AS $$
DECLARE
  r				record;
  dtToDate		timestamptz;
  arKeys		text[];
BEGIN
  IF pParams IS NOT NULL THEN
	arKeys := array_cat(arKeys, ARRAY['period', 'fromdate', 'todate']);
	PERFORM CheckJsonbKeys('/task/postpone', arKeys, pParams);

	FOR r IN SELECT * FROM jsonb_to_recordset(pParams) AS x(period interval, fromdate timestamptz, todate timestamptz)
	LOOP
	  UPDATE db.task SET period = r.period, validFromDate = r.fromdate, validtodate = r.todate WHERE id = pObject;
	END LOOP;
  ELSE
	UPDATE db.task SET period = INTERVAL '8 hour', validFromDate = Now() WHERE id = pObject;
  END IF;

  SELECT validtodate INTO dtToDate FROM db.task WHERE id = pObject;

  PERFORM WriteToEventLog('M', 1000, 'postpone', format('Task postponed until %s.', DateToStr(dtToDate)), pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTaskDrop ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the task drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTaskDrop (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r		    record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.task WHERE id = pObject;

  PERFORM WriteToEventLog('W', 1000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Task dropped.');
END;
$$ LANGUAGE plpgsql;
