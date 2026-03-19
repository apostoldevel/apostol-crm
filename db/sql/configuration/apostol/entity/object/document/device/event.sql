--------------------------------------------------------------------------------
-- DEVICE ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventDeviceCreate -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the device creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceCreate (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  uClient   uuid;
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Device created.', pObject);

  SELECT client INTO uClient FROM db.device WHERE id = pObject;
  IF uClient IS NULL THEN
	uClient := current_client();
	IF GetObjectClass(uClient) IN (GetClass('customer')) THEN
	  UPDATE db.device SET client = uClient WHERE id = pObject;
	END IF;
  END IF;

  PERFORM DoEnable(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDeviceOpen -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the device open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceOpen (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Device opened for viewing.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDeviceEdit -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the device edit event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceEdit (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Device modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDeviceSave -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the device save event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceSave (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Device saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDeviceEnable -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the device enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceEnable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Device enabled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDeviceHeartbeat --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief EventDeviceHeartbeat
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceHeartbeat (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'heartbeat', 'Device sent status: Heartbeat.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDeviceAvailable --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief EventDeviceAvailable
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceAvailable (
  pObject	uuid default context_object(),
  pParams   jsonb default context_params()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'available', 'Device sent status: Available.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDeviceUnavailable ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief EventDeviceUnavailable
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceUnavailable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM CloseTransactions(pObject);
  PERFORM BuildInvoice(pObject);

  PERFORM WriteToEventLog('M', 1000, 'unavailable', 'Device sent status: Unavailable.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDeviceFaulted ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief EventDeviceFaulted
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceFaulted (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM CloseTransactions(pObject);
  PERFORM BuildInvoice(pObject);

  PERFORM WriteToEventLog('M', 1000, 'faulted', 'Device sent status: Faulted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDeviceDisable ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the device disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceDisable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'disable', 'Device disabled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDeviceDelete -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the device delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceDelete (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Device deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDeviceRestore ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the device restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceRestore (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Device restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDeviceDrop -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the device drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventDeviceDrop (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r		    record;
  nCount    integer;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  SELECT Count(id) INTO nCount FROM db.device_value WHERE device = pObject;
  IF nCount > 0 THEN
    RAISE EXCEPTION 'ERR-40000: Обнаружены данные, операция прервана.';
  END IF;

  DELETE FROM db.device WHERE id = pObject;

  PERFORM WriteToEventLog('W', 1000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '<null>') || '] Device dropped.');
END;
$$ LANGUAGE plpgsql;
