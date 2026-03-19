--------------------------------------------------------------------------------
-- ORDER -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventCloudPaymentsCreate ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the CloudPayments payment creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCloudPaymentsCreate (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM DoAction(pObject, 'pay');
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCloudPaymentsDelete ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the CloudPayments payment delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCloudPaymentsDelete (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN

END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCloudPaymentsPay -------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the CloudPayments payment pay event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCloudPaymentsPay (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'pay', 'Payment process started.', pObject);

  IF GetObjectTypeCode(pObject) = 'validation.cloudpayments' THEN
    PERFORM CP_Payment(pObject);
  ELSE
    PERFORM CP_Charge(pObject);
  END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCloudPaymentsExpire ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the CloudPayments payment expire event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCloudPaymentsExpire (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'expire', 'Order expired.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCloudPaymentsConfirm ---------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the CloudPayments payment confirm event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCloudPaymentsConfirm (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'confirm', 'Payment confirmation.', pObject);

  PERFORM CP_Confirm(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCloudPaymentsRefund ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief EventCloudPaymentsRefund
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCloudPaymentsRefund (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'refund', 'Payment refund.', pObject);

  PERFORM CP_Refund(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCloudPaymentsCancel ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the CloudPayments payment cancel event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCloudPaymentsCancel (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'cancel', 'Payment cancellation.', pObject);

  PERFORM CP_Cancel(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCloudPaymentsReject ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the CloudPayments payment reject event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCloudPaymentsReject (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'reject', 'Payment rejection.', pObject);
END;
$$ LANGUAGE plpgsql;
