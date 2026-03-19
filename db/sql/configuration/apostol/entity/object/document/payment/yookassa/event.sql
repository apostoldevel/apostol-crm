--------------------------------------------------------------------------------
-- ORDER -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventYooKassaCreate ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the YooKassa payment creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventYooKassaCreate (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM DoAction(pObject, 'pay');
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventYooKassaDelete ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the YooKassa payment delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventYooKassaDelete (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN

END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventYooKassaPay ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the YooKassa payment pay event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventYooKassaPay (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'pay', 'Payment process started.', pObject);

  IF GetObjectTypeCode(pObject) != 'validation.yookassa' THEN
    PERFORM YK_CreatePayment(pObject);
  END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventYooKassaExpire ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the YooKassa payment expire event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventYooKassaExpire (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'expire', 'Order expired.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventYooKassaConfirm --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the YooKassa payment confirm event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventYooKassaConfirm (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'confirm', 'Payment confirmation.', pObject);

  PERFORM YK_Capture(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventYooKassaRefund ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief EventYooKassaRefund
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventYooKassaRefund (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'refund', 'Payment refund.', pObject);

  PERFORM YK_Refund(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventYooKassaCancel ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the YooKassa payment cancel event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventYooKassaCancel (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'cancel', 'Payment cancellation.', pObject);

  PERFORM YK_Cancel(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventYooKassaReject ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the YooKassa payment reject event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventYooKassaReject (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'reject', 'Payment rejection.', pObject);
END;
$$ LANGUAGE plpgsql;
