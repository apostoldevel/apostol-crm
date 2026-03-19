--------------------------------------------------------------------------------
-- ORDER -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventOrderCreate ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the order creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventOrderCreate (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Order created.', pObject);
  PERFORM DoEnable(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderOpen --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the order open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventOrderOpen (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Order opened.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderEdit --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the order edit event
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventOrderEdit (
  pObject   uuid default context_object(),
  pParams   jsonb default context_params()
) RETURNS   void
AS $$
DECLARE
  nAmount   numeric;
BEGIN
  SELECT amount INTO nAmount FROM db.order WHERE id = pObject;

  IF nAmount = 0 THEN
    RAISE EXCEPTION 'ERR-40000: Invalid order amount';
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'edit', 'Order modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderSave --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the order save event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventOrderSave (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Order saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderEnable ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the order enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventOrderEnable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  SELECT code, debit, credit, amount INTO r FROM db.order WHERE id = pObject;

  IF NOT IsEnabled(r.debit) THEN
    PERFORM TransferringInactiveAccount(GetAccountCode(r.debit));
  END IF;

  IF NOT IsEnabled(r.credit) THEN
    PERFORM TransferringInactiveAccount(GetAccountCode(r.credit));
  END IF;

  PERFORM UpdateBalance(r.debit, r.amount * -1, 2);
  PERFORM UpdateBalance(r.credit, r.amount, 2);

  PERFORM WriteToEventLog('M', 1000, 'enable', format('Order %s processed.', r.code), pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderDisable -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the order disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventOrderDisable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  SELECT code, debit, credit, amount INTO r FROM db.order WHERE id = pObject;

  IF NOT IsEnabled(r.debit) THEN
    PERFORM TransferringInactiveAccount(GetAccountCode(r.debit));
  END IF;

  IF NOT IsEnabled(r.credit) THEN
    PERFORM TransferringInactiveAccount(GetAccountCode(r.credit));
  END IF;

  PERFORM UpdateBalance(r.debit, r.amount * -1, 1);
  PERFORM UpdateBalance(r.credit, r.amount, 1);

  PERFORM WriteToEventLog('M', 1000, 'disable', format('Order %s completed.', r.code), pObject);
END
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderCancel ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the order cancel event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventOrderCancel (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  SELECT code, debit, credit, amount INTO r FROM db.order WHERE id = pObject;

  IF NOT IsEnabled(r.debit) THEN
    PERFORM TransferringInactiveAccount(GetAccountCode(r.debit));
  END IF;

  IF NOT IsEnabled(r.credit) THEN
    PERFORM TransferringInactiveAccount(GetAccountCode(r.credit));
  END IF;

  PERFORM UpdateBalance(r.debit, r.amount, 2);
  PERFORM UpdateBalance(r.credit, r.amount * -1, 2);

  PERFORM WriteToEventLog('M', 1000, 'cancel', format('Order %s cancelled.', r.code), pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderRefund ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief EventOrderRefund
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventOrderRefund (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  SELECT code, debit, credit, amount INTO r FROM db.order WHERE id = pObject;

  IF NOT IsEnabled(r.debit) THEN
    PERFORM TransferringInactiveAccount(GetAccountCode(r.debit));
  END IF;

  IF NOT IsEnabled(r.credit) THEN
    PERFORM TransferringInactiveAccount(GetAccountCode(r.credit));
  END IF;

  PERFORM UpdateBalance(r.debit, r.amount, 1);
  PERFORM UpdateBalance(r.credit, r.amount * -1, 1);

  PERFORM UpdateBalance(r.debit, r.amount, 2);
  PERFORM UpdateBalance(r.credit, r.amount * -1, 2);

  PERFORM WriteToEventLog('M', 1000, 'return', 'Order returned.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderDelete ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the order delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventOrderDelete (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  IF session_user <> 'admin' THEN
    IF NOT IsUserRole(GetGroup('su')) THEN
      PERFORM AccessDenied();
    END IF;
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'delete', 'Order deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderRestore -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the order restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventOrderRestore (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Order restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderDrop --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the order drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventOrderDrop (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  IF session_user <> 'admin' THEN
    IF NOT IsUserRole(GetGroup('su')) THEN
      PERFORM AccessDenied();
    END IF;
  END IF;

  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.order WHERE id = pObject;

  PERFORM WriteToEventLog('M', 2000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Order dropped.');
END;
$$ LANGUAGE plpgsql;
