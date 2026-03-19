--------------------------------------------------------------------------------
-- ACCOUNT ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventAccountCreate ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the account creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventAccountCreate (
  pObject    uuid default context_object()
) RETURNS    void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Account created.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventAccountOpen ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the account open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventAccountOpen (
  pObject    uuid default context_object()
) RETURNS    void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Account opened.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventAccountEdit ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the account edit event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventAccountEdit (
  pObject    uuid default context_object()
) RETURNS    void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Account modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventAccountSave ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the account save event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventAccountSave (
  pObject    uuid default context_object()
) RETURNS    void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Account saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventAccountEnable ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the account enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventAccountEnable (
  pObject    uuid default context_object()
) RETURNS    void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Account enabled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventAccountDisable ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the account disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventAccountDisable (
  pObject    uuid default context_object()
) RETURNS    void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'disable', 'Account closed.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventAccountDelete ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the account delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventAccountDelete (
  pObject    uuid default context_object()
) RETURNS    void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Account deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventAccountRestore ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the account restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventAccountRestore (
  pObject    uuid default context_object()
) RETURNS    void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Account restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventAccountDrop ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the account drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventAccountDrop (
  pObject    uuid default context_object()
) RETURNS    void
AS $$
DECLARE
  r            record;
BEGIN
  IF session_user <> 'admin' THEN
    IF NOT IsUserRole(GetGroup('su')) THEN
      PERFORM AccessDenied();
    END IF;
  END IF;

  FOR r IN SELECT id FROM db.order WHERE debit = pObject OR credit = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDelete(r.id);
    END IF;
    IF IsDisabled(r.id) THEN
      PERFORM DoDelete(r.id);
    END IF;
    PERFORM DoDrop(r.id);
  END LOOP;

  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.turnover WHERE account = pObject;
  DELETE FROM db.balance WHERE account = pObject;
  DELETE FROM db.account WHERE id = pObject;

  PERFORM WriteToEventLog('W', 1000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Account dropped.');
END;
$$ LANGUAGE plpgsql;
