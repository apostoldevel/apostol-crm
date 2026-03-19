--------------------------------------------------------------------------------
-- CUSTOMER --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventCustomerCreate ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the customer creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCustomerCreate (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Client created.', pObject);

  PERFORM DoEnable(CreateAccount(pObject, GetType('passive.account'), DefaultCurrency(), pObject, GetCategory('customer.category'), GenAccountCode(pObject, DefaultCurrency(), '000', true), null, 'Технический счёт.'));
  PERFORM DoEnable(CreateAccount(pObject, GetType('passive.account'), DefaultCurrency(), pObject, GetCategory('customer.category'), GenAccountCode(pObject, DefaultCurrency(), '100', true), null, 'Основной счёт.'));
  PERFORM DoEnable(CreateAccount(pObject, GetType('active.account'), DefaultCurrency(), pObject, GetCategory('customer.category'), GenAccountCode(pObject, DefaultCurrency(), '200', true), null, 'Сервисный счёт.'));
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCustomerOpen -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the customer open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCustomerOpen (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Client opened for viewing.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCustomerEdit -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the customer edit event
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCustomerEdit (
  pObject	uuid default context_object(),
  pParams	jsonb default context_params()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Client modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCustomerSave -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the customer save event
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCustomerSave (
  pObject	uuid default context_object(),
  pParams   jsonb default context_params()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Client saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCustomerEnable ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the customer enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCustomerEnable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  uUserId   uuid;
BEGIN
  SELECT userid INTO uUserId FROM db.client WHERE id = pObject;

  IF uUserId IS NOT NULL THEN
    PERFORM AddMemberToGroup(uUserId, GetGroup('customer'));
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'enable', 'Client approved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCustomerDisable --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the customer disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCustomerDisable (
  pObject	    uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'disable', 'Client disabled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCustomerDelete ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the customer delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCustomerDelete (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Client deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCustomerRestore --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the customer restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCustomerRestore (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Client restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCustomerDrop -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the customer drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCustomerDrop (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r         record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  PERFORM WriteToEventLog('W', 1000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Client dropped.');
END;
$$ LANGUAGE plpgsql;
