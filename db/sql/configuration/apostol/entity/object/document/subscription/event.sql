--------------------------------------------------------------------------------
-- SUBSCRIPTION ----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventSubscriptionCreate -----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionCreate (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Subscription created.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionOpen -------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionOpen (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Subscription opened for viewing.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionEdit -------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription edit event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionEdit (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Subscription modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionSave -------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription save event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionSave (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Subscription saved.', pObject);
  PERFORM EventSubscriptionCancel(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionEnable -----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionEnable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Trial subscription.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionPay --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription pay event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionPay (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'pay', 'Subscription paid.', pObject);
  PERFORM SubscriptionPaid(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionExpire -----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription expire event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionExpire (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'expire', 'Subscription expired.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionCancel -----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription cancel event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionCancel (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  uNew      uuid;
BEGIN
  PERFORM SubscriptionCanceled(pObject);

  SELECT t.id INTO uNew
    FROM db.subscription t INNER JOIN db.object o ON t.document = o.id
   WHERE t.id != pObject
     AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
   ORDER BY o.pdate DESC
   LIMIT 1;

  IF FOUND THEN
    PERFORM SubscriptionPaid(uNew);
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'cancel', 'Subscription cancelled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionStop -------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription stop event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionStop (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'stop', 'Subscription stopped.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionFail -------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription fail event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionFail (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'fail', 'Subscription payment issues.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionDisable ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionDisable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'disable', 'Subscription disabled.', pObject);
END
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionDelete -----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionDelete (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Subscription deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionRestore ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionRestore (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Subscription restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventSubscriptionDrop -------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the subscription drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventSubscriptionDrop (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.subscription WHERE id = pObject;

  PERFORM WriteToEventLog('M', 2000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Subscription dropped.');
END;
$$ LANGUAGE plpgsql;
