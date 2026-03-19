--------------------------------------------------------------------------------
-- CLIENT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventClientCreate -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the client creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventClientCreate (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Client created.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientOpen -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the client open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventClientOpen (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Client opened for viewing.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientEdit -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the client edit event
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventClientEdit (
  pObject       uuid default context_object(),
  pParams       jsonb default context_params()
) RETURNS       void
AS $$
DECLARE
  old_email     text;
  new_email     text;
BEGIN
  old_email = pParams#>'{old, email}';
  new_email = pParams#>'{new, email}';

  IF old_email <> new_email THEN
    PERFORM EventMessageConfirmEmail(pObject);
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'edit', 'Client modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientSave -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the client save event
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventClientSave (
  pObject	uuid default context_object(),
  pParams   jsonb default context_params()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Client saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientEnable -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the client enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventClientEnable (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  r             record;

  uArea         uuid;
  uUserId       uuid;
  uInterface    uuid;
  uCompany      uuid;
BEGIN
  SELECT company, userid INTO uCompany, uUserId FROM db.client WHERE id = pObject;

  IF uUserId IS NOT NULL THEN
    PERFORM UserUnLock(uUserId);

    PERFORM DeleteGroupForMember(uUserId, GetGroup('guest'));

    PERFORM AddMemberToGroup(uUserId, GetGroup('user'));
    PERFORM AddMemberToGroup(uUserId, GetGroup(GetCompanyCode(uCompany)));

    SELECT area INTO uArea FROM db.document WHERE id = pObject;

    PERFORM AddMemberToArea(uUserId, uArea);
    PERFORM SetDefaultArea(uArea, uUserId);

    uInterface := GetInterface('all');
    PERFORM AddMemberToInterface(uUserId, uInterface);

    uInterface := GetInterface('user');
    PERFORM AddMemberToInterface(uUserId, uInterface);
    PERFORM SetDefaultInterface(uInterface, uUserId);

    FOR r IN SELECT code FROM db.session WHERE userid = uUserId
    LOOP
      PERFORM SetArea(GetDefaultArea(uUserId), uUserId, r.code);
      PERFORM SetInterface(GetDefaultInterface(uUserId), uUserId, r.code);
    END LOOP;

    FOR r IN SELECT id FROM db.account WHERE client = pObject
    LOOP
      IF IsDisabled(r.id) THEN
        PERFORM DoEnable(r.id);
      END IF;
    END LOOP;

    --PERFORM EventMessageConfirmEmail(pObject);
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'enable', 'Client approved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientDisable ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the client disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventClientDisable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
  uUserId   uuid;
BEGIN
  SELECT userid INTO uUserId FROM db.client WHERE id = pObject;

  IF uUserId IS NOT NULL THEN
    PERFORM UserLock(uUserId);

    PERFORM DeleteGroupForMember(uUserId);
    PERFORM DeleteAreaForMember(uUserId);
    PERFORM DeleteInterfaceForMember(uUserId);

    PERFORM AddMemberToGroup(uUserId, GetGroup('guest'));
    PERFORM AddMemberToArea(uUserId, GetArea('guest'));

    PERFORM SetDefaultArea(GetArea('guest'), uUserId);
    PERFORM SetDefaultInterface(GetInterface('guest'), uUserId);

    FOR r IN SELECT code FROM db.session WHERE userid = uUserId
    LOOP
      PERFORM SetArea(GetDefaultArea(uUserId), uUserId, r.code);
      PERFORM SetInterface(GetDefaultInterface(uUserId), uUserId, r.code);
    END LOOP;
  END IF;

  FOR r IN SELECT id FROM db.account WHERE client = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'disable', 'Client disabled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientDelete -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the client delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventClientDelete (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  r             record;

  uUserId       uuid;

  vOAuthSecret  text;
BEGIN
  SELECT userid INTO uUserId FROM db.client WHERE id = pObject;

  IF uUserId = current_userid() THEN
    SELECT secret INTO vOAuthSecret FROM oauth2.audience WHERE code = current_database();
    IF FOUND THEN
      PERFORM SessionOut(current_session(), true);
      PERFORM SignIn(CreateSystemOAuth2(), current_database(), vOAuthSecret);
      PERFORM SubstituteUser(GetUser('apibot'), vOAuthSecret);
    END IF;
  END IF;

  FOR r IN SELECT id FROM db.account WHERE client = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
    IF IsDisabled(r.id) THEN
      PERFORM DoDelete(r.id);
    END IF;
  END LOOP;

  IF uUserId IS NOT NULL THEN
    UPDATE db.client SET code = encode(gen_random_bytes(12), 'hex'), userid = null WHERE id = pObject;
    PERFORM DeleteUser(uUserId);
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'delete', 'Client deleted.', pObject);
END;
$$ LANGUAGE plpgsql
   SET search_path = kernel, public, pg_temp;
--------------------------------------------------------------------------------
-- EventClientRestore ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the client restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventClientRestore (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Client restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientDrop -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the client drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventClientDrop (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
  uUserId   uuid;
BEGIN
  IF session_user <> 'admin' THEN
    IF NOT IsUserRole(GetGroup('su')) THEN
      PERFORM AccessDenied();
    END IF;
  END IF;

  FOR r IN SELECT id FROM db.account WHERE client = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
    IF IsDisabled(r.id) THEN
      PERFORM DoDelete(r.id);
    END IF;
    PERFORM DoDrop(r.id);
  END LOOP;

  FOR r IN SELECT id FROM db.identity WHERE client = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
    IF IsDisabled(r.id) THEN
      PERFORM DoDelete(r.id);
    END IF;
    PERFORM DoDrop(r.id);
  END LOOP;

  DELETE FROM db.object_link WHERE linked = pObject;
  DELETE FROM db.object_file WHERE object = pObject;

  SELECT userid INTO uUserId FROM client WHERE id = pObject;
  IF uUserId IS NOT NULL THEN
    UPDATE db.client SET userid = null WHERE id = pObject;
    PERFORM DeleteUser(uUserId);
  END IF;

  DELETE FROM db.client_name WHERE client = pObject;
  DELETE FROM db.client WHERE id = pObject;

  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  PERFORM WriteToEventLog('W', 1000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Client dropped.');
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientConfirm ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the client confirm event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventClientConfirm (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  uUserId       uuid;
  vEmail        text;
  bVerified     bool;
BEGIN
  SELECT userid INTO uUserId FROM db.client WHERE id = pObject;

  IF uUserId IS NOT NULL THEN

    SELECT email, email_verified INTO vEmail, bVerified
      FROM db.user u INNER JOIN db.profile p ON u.id = p.userid AND u.type = 'U'
     WHERE id = uUserId;

    IF vEmail IS NULL THEN
      PERFORM EmailAddressNotSet();
    END IF;

    IF NOT bVerified THEN
      PERFORM EmailAddressNotVerified(vEmail);
    END IF;

    --PERFORM EventMessageAccountInfo(pObject);
  END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientReconfirm --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief EventClientReconfirm
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventClientReconfirm (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  uUserId       uuid;
BEGIN
  SELECT userid INTO uUserId FROM db.client WHERE id = pObject;
  IF uUserId IS NOT NULL THEN
    UPDATE db.profile SET email_verified = false WHERE userid = uUserId;
    PERFORM EventMessageConfirmEmail(pObject);
  END IF;
END;
$$ LANGUAGE plpgsql;
