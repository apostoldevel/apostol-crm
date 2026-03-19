--------------------------------------------------------------------------------
-- IDENTITY --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventIdentityCreate ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the identity document creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventIdentityCreate (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Identity document created.', pObject);
  PERFORM DoEnable(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventIdentityOpen -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the identity document open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventIdentityOpen (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Identity document opened.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventIdentityEdit -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the identity document edit event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventIdentityEdit (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Identity document modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventIdentitySave -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the identity document save event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventIdentitySave (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Identity document saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventIdentityEnable ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the identity document enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventIdentityEnable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Identity document enabled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventIdentityDisable --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the identity document disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventIdentityDisable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'disable', 'Identity document disabled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventIdentityCheck ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the identity document check event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventIdentityCheck (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r         record;
  i         record;

  iPeriod   interval;
  vLabel    text;
BEGIN
  SELECT * INTO i FROM db.identity WHERE id = pObject;

  iPeriod := i.validtodate - i.reminderdate;

  IF iPeriod <= interval '7 day' THEN
    UPDATE db.identity SET reminderdate = MAXDATE() WHERE id = pObject;
  ELSIF iPeriod <= interval '30 day' THEN
    UPDATE db.identity SET reminderdate = validtodate - interval '7 day' WHERE id = pObject;
  ELSIF iPeriod <= interval '60 day' THEN
    UPDATE db.identity SET reminderdate = validtodate - interval '30 day' WHERE id = pObject;
  END IF;

  vLabel := format('Срок действия удостоверения личности заканчивается: %s.', i.validToDate);

  FOR r IN SELECT s.id, s.userid FROM db.client s WHERE s.id = i.client
  LOOP
	PERFORM CreateNotice(r.userid, pObject, vLabel, 'identity');
	PERFORM CreateTask(pObject, GetType('system.task'), GetCalendar('default.calendar'), r.id, vLabel, false, iPeriod, localtimestamp, localtimestamp + iPeriod);
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'check', 'Identity document verified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventIdentityReturn ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the identity document return event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventIdentityReturn (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'return', 'Identity document returned.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventIdentityExpire ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the identity document expire event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventIdentityExpire (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  i         record;

  vLabel    text;
BEGIN
  SELECT * INTO i FROM db.identity WHERE id = pObject;

  vLabel := format('Закончился срок действия удостоверения личности: %s.', GetObjectLabel(pObject));

  PERFORM CreateNotice(GetClientUserId(i.client), pObject, vLabel, 'identity');
  PERFORM CreateTask(pObject, GetType('system.task'), GetCalendar('default.calendar'), i.client, vLabel, false, interval '10 day', Now(), Now() + interval '10 day');

  PERFORM WriteToEventLog('M', 1000, 'expire', vLabel, pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventIdentityDelete ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the identity document delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventIdentityDelete (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Identity document deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventIdentityRestore --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the identity document restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventIdentityRestore (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Identity document restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventIdentityDrop -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the identity document drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventIdentityDrop (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r			record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.identity WHERE id = pObject;

  PERFORM WriteToEventLog('W', 1000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Документ удостоверяющий личность уничтожен.');
END;
$$ LANGUAGE plpgsql;
