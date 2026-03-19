--------------------------------------------------------------------------------
-- EventReferenceCreate --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles reference creation event.
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventReferenceCreate (
  pObject        uuid default context_object()
) RETURNS        void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Reference created.', pObject);
END;
$$ LANGUAGE plpgsql;
