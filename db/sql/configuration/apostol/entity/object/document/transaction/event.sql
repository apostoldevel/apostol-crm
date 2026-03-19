--------------------------------------------------------------------------------
-- TRANSACTION -----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventTransactionCreate ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the transaction creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTransactionCreate (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Transaction created.', pObject);
  PERFORM DoEnable(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionOpen --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the transaction open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTransactionOpen (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Transaction opened for viewing.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionEdit --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the transaction edit event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTransactionEdit (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Transaction modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionSave --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the transaction save event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTransactionSave (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Transaction saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionEnable ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the transaction enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTransactionEnable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Transaction opened.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionDisable -----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the transaction disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTransactionDisable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  FOR r IN SELECT id, client, service, currency, amount FROM db.transaction WHERE id = pObject
  LOOP
    PERFORM TransactionPayment(pObject, r.service, r.client,  r.currency, r.amount, GetObjectLabel(r.id));
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'disable', 'Transaction closed.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionCancel ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the transaction cancel event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTransactionCancel (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  FOR r IN
    SELECT t.id
      FROM db.order t INNER JOIN db.object o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
     WHERE o.parent = pObject
  LOOP
    PERFORM ExecuteObjectAction(r.id, context_action());
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'cancel', 'Transaction cancelled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionRefund ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief EventTransactionRefund
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTransactionRefund (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  FOR r IN
    SELECT t.id
      FROM db.order t INNER JOIN db.object o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000003'::uuid
     WHERE o.parent = pObject
  LOOP
    PERFORM ExecuteObjectAction(r.id, context_action());
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'return', 'Transaction returned.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionDelete ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the transaction delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTransactionDelete (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  FOR r IN
    SELECT t.id
      FROM db.order t INNER JOIN db.object o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000004'::uuid
     WHERE o.parent = pObject
  LOOP
    PERFORM ExecuteObjectAction(r.id, context_action());
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'delete', 'Transaction deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionRestore -----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the transaction restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTransactionRestore (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Transaction restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionDrop --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the transaction drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventTransactionDrop (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.transaction WHERE id = pObject;

  PERFORM WriteToEventLog('M', 2000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Transaction dropped.');
END;
$$ LANGUAGE plpgsql;
