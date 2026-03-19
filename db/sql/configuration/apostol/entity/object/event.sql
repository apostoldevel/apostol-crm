--------------------------------------------------------------------------------
-- OBJECT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the object creation event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventObjectCreate (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Object created.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the object open event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventObjectOpen (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Object opened.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the object edit event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventObjectEdit (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Object modified.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the object save event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventObjectSave (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Object saved.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the object enable event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventObjectEnable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Object enabled.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the object disable event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventObjectDisable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'disable', 'Object disabled.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the object delete event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventObjectDelete (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Object deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the object restore event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventObjectRestore (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Object restored.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the object drop event (permanent deletion with cascade cleanup)
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventObjectDrop (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r			record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.comment      WHERE object = pObject;
  DELETE FROM db.notice       WHERE object = pObject;
  DELETE FROM db.object_link  WHERE object = pObject;
  DELETE FROM db.object_file  WHERE object = pObject;
  DELETE FROM db.object_data  WHERE object = pObject;
  DELETE FROM db.object_state WHERE object = pObject;
  DELETE FROM db.method_stack WHERE object = pObject;
  DELETE FROM db.notification WHERE object = pObject;
  DELETE FROM db.log          WHERE object = pObject;

  UPDATE db.object SET parent = null WHERE parent = pObject;
  DELETE FROM db.object WHERE id = pObject;

  PERFORM WriteToEventLog('W', 1000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Object dropped.');
END;
$$ LANGUAGE plpgsql;
