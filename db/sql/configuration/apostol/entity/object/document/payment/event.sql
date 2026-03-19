--------------------------------------------------------------------------------
-- PAYMENT ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventPaymentCreate ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the payment creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventPaymentCreate (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Payment created.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventPaymentOpen ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the payment open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventPaymentOpen (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Payment opened.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventPaymentEdit ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the payment edit event
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventPaymentEdit (
  pObject       uuid default context_object(),
  pParams       jsonb default context_params()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Payment modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventPaymentSave ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the payment save event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventPaymentSave (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Payment saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventPaymentEnable ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the payment enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventPaymentEnable (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Payment submitted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventPaymentDisable ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the payment disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventPaymentDisable (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'disable', 'Payment completed.', pObject);
END
$$ LANGUAGE plpgsql
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- EventPaymentDelete ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the payment delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventPaymentDelete (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Payment deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventPaymentRestore ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the payment restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventPaymentRestore (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Payment restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventPaymentDrop ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the payment drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventPaymentDrop (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  r             record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.payment WHERE id = pObject;

  PERFORM WriteToEventLog('M', 2000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Payment will be dropped.');
END;
$$ LANGUAGE plpgsql;
