--------------------------------------------------------------------------------
-- PRODUCT ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventProductCreate ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the product creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventProductCreate (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Product created.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventProductOpen ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the product open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventProductOpen (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Product opened.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventProductEdit ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the product edit event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventProductEdit (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Product modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventProductSave ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the product save event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventProductSave (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Product saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventProductEnable ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the product enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventProductEnable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;

  uTariff   uuid;
BEGIN
  FOR r IN SELECT id FROM db.price WHERE product = pObject
  LOOP
    IF IsDisabled(r.id) THEN
      PERFORM DoEnable(r.id);
    END IF;
  END LOOP;

  FOR r IN SELECT t.service, t.currency, t.tag, t.price, t.commission, t.tax, s.name, s.description FROM TariffScheme t INNER JOIN Service s ON t.service = s.id
  LOOP
    SELECT id INTO uTariff FROM db.tariff t WHERE t.product = pObject AND t.service = r.service AND t.currency = r.currency AND t.tag = r.tag;
    IF FOUND THEN
      PERFORM EditTariff(uTariff, pObject, GetType('system.tariff'), pObject, r.service, r.currency, null, r.tag, r.price, r.commission, r.tax, r.name, replace(replace(r.description, 'услуга', 'тариф'), 'Услуга', 'Тариф'));

      IF IsDisabled(uTariff) THEN
	    PERFORM DoEnable(uTariff);
	  END IF;
    ELSE
      PERFORM CreateTariff(pObject, GetType('system.tariff'), pObject, r.service, r.currency, null, r.tag, r.price, r.commission, r.tax, r.name, replace(replace(r.description, 'услуга', 'тариф'), 'Услуга', 'Тариф'));
    END IF;
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'enable', 'Product available.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventProductDisable ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the product disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventProductDisable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  FOR r IN SELECT id FROM db.tariff WHERE product = pObject
  LOOP
    IF IsEnabled(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'disable', 'Product unavailable.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventProductDelete ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the product delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventProductDelete (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Product deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventProductRestore ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the product restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventProductRestore (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Product restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventProductDrop ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the product drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventProductDrop (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  FOR r IN SELECT id FROM db.tariff WHERE product = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
    IF IsDisabled(r.id) THEN
      PERFORM DoDelete(r.id);
    END IF;
    PERFORM DoDrop(r.id);
  END LOOP;

  FOR r IN SELECT id FROM db.price WHERE product = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
    IF IsDisabled(r.id) THEN
      PERFORM DoDelete(r.id);
    END IF;
    PERFORM DoDrop(r.id);
  END LOOP;

  DELETE FROM db.product WHERE id = pObject;

  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  PERFORM WriteToEventLog('W', 1000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Product dropped.');
END;
$$ LANGUAGE plpgsql;
