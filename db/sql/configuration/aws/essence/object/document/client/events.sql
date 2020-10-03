--------------------------------------------------------------------------------
-- CLIENT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventClientCreate -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientCreate (
  pObject	numeric default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1010, 'Клиент создан.', pObject);
  PERFORM ExecuteObjectAction(pObject, GetAction('enable'));
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientOpen -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientOpen (
  pObject	numeric default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1011, 'Клиент открыт на просмотр.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientEdit -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientEdit (
  pObject	numeric default context_object(),
  pForm		jsonb default context_form()
) RETURNS	void
AS $$
DECLARE
  old_email	jsonb;
  new_email	jsonb;
BEGIN
  old_email = pForm#>'{old, email}';
  new_email = pForm#>'{new, email}';

  IF coalesce(old_email, '{}') <> coalesce(new_email, '{}') THEN
    PERFORM EventClientConfirmEmail(pObject, new_email);
  END IF;

  PERFORM WriteToEventLog('M', 1012, 'Клиент изменён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientSave -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientSave (
  pObject	numeric default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1013, 'Клиент сохранён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientEnable -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientEnable (
  pObject	numeric default context_object()
) RETURNS	void
AS $$
DECLARE
  nUserId	numeric;
BEGIN
  SELECT userid INTO nUserId FROM db.client WHERE id = pObject;

  IF nUserId IS NOT NULL THEN
    PERFORM UserUnLock(nUserId);
    PERFORM DeleteGroupForMember(nUserId, GetGroup('guest'));

    PERFORM AddMemberToGroup(nUserId, GetGroup('user'));
    PERFORM AddMemberToArea(nUserId, current_area());

    PERFORM SetDefaultArea(current_area(), nUserId);
    PERFORM SetArea(current_area(), nUserId);

    UPDATE db.session SET area = current_area() WHERE userid = nUserId;

    PERFORM SetDefaultInterface(GetInterface('I:1:0:3'), nUserId);
    PERFORM SetInterface(GetInterface('I:1:0:3'), nUserId);

    PERFORM EventClientConfirmEmail(pObject);
  END IF;

  PERFORM WriteToEventLog('M', 1014, 'Клиент утверждён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientDisable ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientDisable (
  pObject	numeric default context_object()
) RETURNS	void
AS $$
DECLARE
  nUserId	numeric;
BEGIN
  SELECT userid INTO nUserId FROM db.client WHERE id = pObject;

  IF nUserId IS NOT NULL THEN
    PERFORM UserLock(nUserId);
  END IF;

  PERFORM WriteToEventLog('M', 1015, 'Клиент закрыт.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientDelete -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientDelete (
  pObject	numeric default context_object()
) RETURNS	void
AS $$
DECLARE
  nUserId	numeric;
BEGIN
  SELECT userid INTO nUserId FROM client WHERE id = pObject;

  IF nUserId IS NOT NULL THEN
    DELETE FROM db.session WHERE userid = nUserId;
    PERFORM UserLock(nUserId);
    UPDATE db.user SET pswhash = null WHERE id = nUserId;
  END IF;

  PERFORM WriteToEventLog('M', 1016, 'Клиент удалён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientRestore ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientRestore (
  pObject	numeric default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1017, 'Клиент восстановлен.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientDrop -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientDrop (
  pObject	numeric default context_object()
) RETURNS	void
AS $$
DECLARE
  r		    record;
  nUserId   numeric;
BEGIN
  SELECT label INTO r FROM db.object WHERE id = pObject;

  SELECT userid INTO nUserId FROM client WHERE id = pObject;
  IF nUserId IS NOT NULL THEN
    UPDATE db.client SET userid = null WHERE id = pObject;
    DELETE FROM db.session WHERE userid = nUserId;
    PERFORM DeleteUser(nUserId);
  END IF;

  DELETE FROM db.client_name WHERE client = pObject;
  DELETE FROM db.client WHERE id = pObject;

  PERFORM WriteToEventLog('W', 2010, '[' || pObject || '] [' || coalesce(r.label, '<null>') || '] Клиент уничтожен.');
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientConfirm ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientConfirm (
  pObject	    numeric default context_object()
) RETURNS	    void
AS $$
DECLARE
  nUserId       numeric;
  vEmail        text;
  bVerified     bool;
BEGIN
  SELECT userid INTO nUserId FROM db.client WHERE id = pObject;

  IF nUserId IS NOT NULL THEN

	SELECT email, email_verified INTO vEmail, bVerified
	  FROM db.user u INNER JOIN db.profile p ON u.id = p.userid AND u.type = 'U'
	 WHERE id = nUserId;

	IF vEmail IS NULL THEN
      PERFORM EmailAddressNotSet();
    END IF;

    IF NOT bVerified THEN
      PERFORM EmailAddressNotVerified(vEmail);
    END IF;

    PERFORM EventClientAccountInfo(pObject);
  END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientReconfirm --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientReconfirm (
  pObject	    numeric default context_object()
) RETURNS	    void
AS $$
DECLARE
  nUserId       numeric;
BEGIN
  SELECT userid INTO nUserId FROM db.client WHERE id = pObject;
  IF nUserId IS NOT NULL THEN
	UPDATE db.profile SET email_verified = false WHERE userid = nUserId;
    PERFORM EventClientConfirmEmail(pObject);
  END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientConfirmEmail -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientConfirmEmail (
  pObject		numeric default context_object(),
  pForm		    jsonb default context_form()
) RETURNS		void
AS $$
DECLARE
  nUserId       numeric;
  vName			text;
  vUserName     text;
  vText			text;
  vEmail		text;
  vProject		text;
  vHost         text;
  vSupport		text;
  bVerified		bool;
BEGIN
  SELECT userid INTO nUserId FROM db.client WHERE id = pObject;
  IF nUserId IS NOT NULL THEN

    IF pForm IS NOT NULL THEN
	  UPDATE db.client SET email = pForm WHERE id = nUserId;
	END IF;

	SELECT username, name, email, email_verified INTO vUserName, vName, vEmail, bVerified
	  FROM db.user u INNER JOIN db.profile p ON u.id = p.userid AND u.type = 'U'
	 WHERE id = nUserId;

	IF vEmail IS NOT NULL AND NOT bVerified THEN
	  vProject := (RegGetValue(RegOpenKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Name')).vString;
	  vHost := (RegGetValue(RegOpenKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Host')).vString;
	  vSupport := (RegGetValue(RegOpenKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Support')).vString;

      vText := 'Подтверждение email: ' || vEmail;

      PERFORM SendMessage(CreateMessage(pObject, GetType('outbox.message'), GetAgent('smtp.agent'), 'noreply', vEmail, 'Пожалуйста, подтвердите адрес вашей электронной почты', GetConfirmEmailHTML(vName, vUserName, GetVerificationCode(NewVerificationCode(nUserId)), vProject, vHost, vSupport), vText));
      PERFORM WriteToEventLog('M', 1110, vText, pObject);
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventClientAccountInfo ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventClientAccountInfo (
  pObject		numeric default context_object()
) RETURNS		void
AS $$
DECLARE
  nUserId       numeric;
  vName			text;
  vUserName     text;
  vSecret       text;
  vText			text;
  vEmail		text;
  vProject		text;
  vHost         text;
  vSupport		text;
  bVerified		bool;
BEGIN
  SELECT userid INTO nUserId FROM db.client WHERE id = pObject;
  IF nUserId IS NOT NULL THEN

	SELECT username, name, encode(hmac(secret::text, GetSecretKey(), 'sha512'), 'hex'), email, email_verified INTO vUserName, vName, vSecret, vEmail, bVerified
	  FROM db.user u INNER JOIN db.profile p ON u.id = p.userid AND u.type = 'U'
	 WHERE id = nUserId;

	IF vEmail IS NOT NULL AND bVerified THEN
	  vProject := (RegGetValue(RegOpenKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Name')).vString;
	  vHost := (RegGetValue(RegOpenKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Host')).vString;
	  vSupport := (RegGetValue(RegOpenKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Support')).vString;

      vText := 'Информация об учетной записи: ' || vUserName;

      PERFORM SendMessage(CreateMessage(pObject, GetType('outbox.message'), GetAgent('smtp.agent'), 'noreply', vEmail, 'Информация о вашей учетной записи', GetAccountInfoHTML(vName, vUserName, vSecret, vProject, vSupport), vText));
      PERFORM WriteToEventLog('M', 1110, vText, pObject);
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql;
