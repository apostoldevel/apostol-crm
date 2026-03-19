--------------------------------------------------------------------------------
-- FORMAT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventRegionCreate -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles region creation event.
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventRegionCreate (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Регион создан.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventRegionOpen -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles region open event.
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventRegionOpen (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Регион открыт.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventRegionEdit -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles region edit event.
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventRegionEdit (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Регион изменён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventRegionSave -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles region save event.
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventRegionSave (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Регион сохранён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventRegionEnable -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles region enable event.
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventRegionEnable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  nId       integer;
  vCode     text;
BEGIN
  SELECT id INTO nId FROM db.address_tree WHERE code = '01000000000000000';

  IF NOT FOUND THEN
    nId := AddAddressTree(null, '01000000000000000', 'Российская Федерация', null, null, 0);
  END IF;

  SELECT code INTO vCode FROM db.reference WHERE id = pObject;

  PERFORM CopyFromKladr(nId, vCode);

  PERFORM WriteToEventLog('M', 1000, 'enable', 'Регион включен.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventRegionDisable ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles region disable event.
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventRegionDisable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'disable', 'Регион выключен.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventRegionDelete -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles region delete event.
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventRegionDelete (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Регион удалён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventRegionRestore ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles region restore event.
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventRegionRestore (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Регион восстановлен.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventRegionDrop -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles region drop (permanent delete) event.
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventRegionDrop (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.region WHERE id = pObject;

  PERFORM WriteToEventLog('M', 2000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Регион уничтожен.');
END;
$$ LANGUAGE plpgsql;
