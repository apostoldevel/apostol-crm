--------------------------------------------------------------------------------
-- EventJobExecute -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the job execute event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventJobExecute (
  pObject		uuid default context_object()
) RETURNS		void
AS $$
BEGIN
--  PERFORM WriteToEventLog('M', 1000, 'execute', 'Job executing.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventJobComplete ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the job complete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventJobComplete (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'complete', 'Job completed.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventJobDone ----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the job done event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventJobDone (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  uScheduler	uuid;
  dtDateRun		timestamptz;

  iPeriod		interval;
BEGIN
  SELECT scheduler, daterun INTO uScheduler, dtDateRun FROM db.job WHERE id = pObject;
  SELECT period INTO iPeriod FROM db.scheduler WHERE id = uScheduler;

  iPeriod := coalesce(iPeriod, '0 seconds'::interval);

  IF dtDateRun > Now() THEN
    dtDateRun := Now();
  END IF;

  dtDateRun := dtDateRun + iPeriod;

  IF dtDateRun < Now() THEN
    dtDateRun := Now();
  END IF;

  UPDATE db.job SET daterun = dtDateRun WHERE id = pObject;

--  PERFORM WriteToEventLog('M', 1000, 'done', 'Job done.', pObject);
END;
$$ LANGUAGE plpgsql;
