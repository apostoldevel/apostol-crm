--------------------------------------------------------------------------------
-- DOCUMENT --------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the document creation event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDocumentCreate (
  pObject	uuid DEFAULT context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Document created.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the document open event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDocumentOpen (
  pObject	uuid DEFAULT context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Document opened.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the document edit event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDocumentEdit (
  pObject	uuid DEFAULT context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Document modified.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the document save event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDocumentSave (
  pObject	uuid DEFAULT context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Document saved.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the document enable event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDocumentEnable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Document enabled.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the document disable event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDocumentDisable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'disable', 'Document disabled.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the document delete event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDocumentDelete (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Document deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the document restore event
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDocumentRestore (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Document restored.', pObject);
END;
$$ LANGUAGE plpgsql;

/**
 * @brief Handles the document drop event (permanent deletion of document record)
 * @param {uuid} pObject - Object identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDocumentDrop (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r         record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.document WHERE id = pObject;

  PERFORM WriteToEventLog('W', 1000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Document dropped.');
END;
$$ LANGUAGE plpgsql;
