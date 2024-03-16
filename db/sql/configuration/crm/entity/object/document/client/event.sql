--------------------------------------------------------------------------------
-- CLIENT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventClientCreate -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientCreate (
  pObject       uuid default context_object()
) RETURNS        void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Клиент создан.', pObject);
  PERFORM CreateClientAccounts(pObject);
  PERFORM DoEnable(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientOpen -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientOpen (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Клиент открыт на просмотр.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientEdit -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientEdit (
  pObject       uuid default context_object(),
  pParams       jsonb default context_params()
) RETURNS       void
AS $$
DECLARE
  old_email     jsonb;
  new_email     jsonb;
BEGIN
  old_email = pParams#>'{old, email}';
  new_email = pParams#>'{new, email}';

  IF coalesce(old_email, '{}') <> coalesce(new_email, '{}') THEN
    PERFORM EventMessageConfirmEmail(pObject, new_email);
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'edit', 'Клиент изменён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientSave -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientSave (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Клиент сохранён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientEnable -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientEnable (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  r             record;

  uArea         uuid;
  uUserId       uuid;
  uInterface    uuid;
BEGIN
  SELECT userid INTO uUserId FROM db.client WHERE id = pObject;

  IF uUserId IS NOT NULL THEN
    PERFORM UserUnLock(uUserId);

    PERFORM DeleteGroupForMember(uUserId, GetGroup('guest'));

    PERFORM AddMemberToGroup(uUserId, GetGroup('user'));

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

    FOR r IN SELECT id FROM db.card WHERE client = pObject
    LOOP
      IF IsDisabled(r.id) THEN
        PERFORM DoEnable(r.id);
      END IF;
    END LOOP;

    FOR r IN SELECT id FROM db.account WHERE client = pObject
    LOOP
      IF IsDisabled(r.id) THEN
        PERFORM DoEnable(r.id);
      END IF;
    END LOOP;

    --PERFORM EventMessageConfirmEmail(pObject);
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'enable', 'Клиент утверждён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientDisable ----------------------------------------------------------
--------------------------------------------------------------------------------

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

  FOR r IN SELECT id FROM db.card WHERE client = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
  END LOOP;

  FOR r IN SELECT id FROM db.account WHERE client = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'disable', 'Клиент закрыт.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientDelete -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientDelete (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  r             record;
  l             record;

  uUserId       uuid;

  vOAuthSecret  text;
BEGIN
  PERFORM FROM db.invoice i INNER JOIN db.object o ON i.document = o.id AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid WHERE client = pObject;

  IF FOUND THEN
    FOR l IN SELECT code FROM db.locale WHERE id = current_locale()
    LOOP
      IF l.code = 'ru' THEN
        RAISE EXCEPTION 'ERR-40000: Найдены неоплаченные счета. Операция прервана.';
      ELSE
        RAISE EXCEPTION 'ERR-40000: Unpaid bills found. Operation aborted.';
      END IF;
    END LOOP;
  END IF;

  SELECT userid INTO uUserId FROM db.client WHERE id = pObject;

  IF uUserId = current_userid() THEN
    SELECT secret INTO vOAuthSecret FROM oauth2.audience WHERE code = current_database();
    IF FOUND THEN
      PERFORM SessionOut(current_session(), true);
      PERFORM SignIn(CreateSystemOAuth2(), current_database(), vOAuthSecret);
      PERFORM SubstituteUser(GetUser('apibot'), vOAuthSecret);
    END IF;
  END IF;

  FOR r IN SELECT id FROM db.card WHERE client = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
    PERFORM DoDelete(r.id);
  END LOOP;

  FOR r IN SELECT id FROM db.account WHERE client = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
    PERFORM DoDelete(r.id);
  END LOOP;

  IF uUserId IS NOT NULL THEN
    UPDATE db.client SET code = encode(gen_random_bytes(12), 'hex'), userid = null WHERE id = pObject;
    PERFORM DeleteUser(uUserId);
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'delete', 'Клиент удалён.', pObject);
END;
$$ LANGUAGE plpgsql
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- EventClientRestore ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientRestore (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Клиент восстановлен.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientDrop -------------------------------------------------------------
--------------------------------------------------------------------------------

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

  FOR r IN SELECT id FROM db.card WHERE client = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
    IF IsDisabled(r.id) THEN
      PERFORM DoDelete(r.id);
    END IF;
    PERFORM DoDrop(r.id);
  END LOOP;

  FOR r IN SELECT id FROM db.generation WHERE client = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
    IF IsDisabled(r.id) THEN
      PERFORM DoDelete(r.id);
    END IF;
    PERFORM DoDrop(r.id);
  END LOOP;

  FOR r IN SELECT id FROM db.subscription WHERE client = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
    IF IsDisabled(r.id) THEN
      PERFORM DoDelete(r.id);
    END IF;
    PERFORM DoDrop(r.id);
  END LOOP;

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

  FOR r IN SELECT id FROM db.invoice WHERE client = pObject
  LOOP
    IF IsActive(r.id) THEN
      PERFORM DoDisable(r.id);
    END IF;
    IF IsDisabled(r.id) THEN
      PERFORM DoDelete(r.id);
    END IF;
    PERFORM DoDrop(r.id);
  END LOOP;

  DELETE FROM db.object_file WHERE object = pObject;

  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  SELECT userid INTO uUserId FROM client WHERE id = pObject;
  IF uUserId IS NOT NULL THEN
    UPDATE db.client SET userid = null WHERE id = pObject;
    PERFORM DeleteUser(uUserId);
  END IF;

  DELETE FROM db.client_name WHERE client = pObject;
  DELETE FROM db.client WHERE id = pObject;

  PERFORM WriteToEventLog('W', 1000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Клиент уничтожен.');
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientConfirm ----------------------------------------------------------
--------------------------------------------------------------------------------

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
