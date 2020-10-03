--------------------------------------------------------------------------------
-- API -------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.signup ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Регистрация.
 * @param {varchar} pType - Tип клиента
 * @param {text} pUserName - Имя пользователя (login)
 * @param {text} pPassword - Пароль
 * @param {jsonb} pName - Полное наименование компании/Ф.И.О.
 * @param {text} pPhone - Телефон
 * @param {text} pEmail - Электронный адрес
 * @param {jsonb} pInfo - Дополнительная информация
 * @param {text} pDescription - Информация о клиенте
 * @out param {text} session - Сессия
 * @out param {text} secret - Секретный ключ для подписи методом HMAC-256
 * @out param {text} code - Одноразовый код авторизации для получения маркера см. OAuth 2.0
 * @return {record}
 */
CREATE OR REPLACE FUNCTION api.signup (
  pType         varchar,
  pUserName     text,
  pPassword     text,
  pName         jsonb,
  pPhone        text DEFAULT null,
  pEmail        text DEFAULT null,
  pInfo         jsonb DEFAULT null,
  pDescription  text DEFAULT null,
  OUT id        numeric,
  OUT userId    numeric
) RETURNS       record
AS $$
DECLARE
  cn            record;

  nClient       numeric;
  nUserId       numeric;

  jPhone        jsonb;
  jEmail        jsonb;

  vSecret       text;

  arKeys        text[];
BEGIN
  pType := lower(coalesce(pType, 'physical'));
  pPassword := coalesce(NULLIF(pPassword, ''), GenSecretKey(9));
  pPhone := NULLIF(pPhone, '');
  pEmail := NULLIF(pEmail, '');
  pDescription := NULLIF(pDescription, '');

  SELECT u.id INTO nUserId FROM db.user u WHERE type = 'U' AND username = pUserName;

  IF found THEN
    RAISE EXCEPTION 'ERR-40005: Учётная запись "%" уже зарегистрирована.', pUserName;
  END IF;

  SELECT u.id INTO nUserId FROM db.user u WHERE type = 'U' AND phone = pPhone;

  IF found THEN
    RAISE EXCEPTION 'ERR-40005: Учётная запись с номером телефона "%" уже зарегистрирована.', pPhone;
  END IF;

  SELECT u.id INTO nUserId FROM db.user u WHERE type = 'U' AND email = pEmail;

  IF found THEN
    RAISE EXCEPTION 'ERR-40005: Учётная запись с электронным адресом "%" уже зарегистрирована.', pEmail;
  END IF;

  arKeys := array_cat(arKeys, ARRAY['name', 'short', 'first', 'last', 'middle']);
  PERFORM CheckJsonbKeys('/sign/up', arKeys, pName);

  SELECT * INTO cn FROM jsonb_to_record(pName) AS x(name varchar, short varchar, first varchar, last varchar, middle varchar);

  IF NULLIF(cn.name, '') IS NULL THEN
    cn.name := pUserName;
  END IF;

  SELECT secret INTO vSecret FROM oauth2.audience WHERE code = session_username();

  PERFORM SubstituteUser(GetUser('admin'), vSecret);

  nUserId := CreateUser(pUserName, pPassword, coalesce(NULLIF(trim(cn.short), ''), cn.name), pPhone, pEmail, cn.name, true, false, GetArea('guest'));

  PERFORM AddMemberToGroup(nUserId, GetGroup('guest'));

  IF pPhone IS NOT NULL THEN
    jPhone := jsonb_build_object('mobile', pPhone);
  END IF;

  IF pEmail IS NOT NULL THEN
    jEmail := jsonb_build_array(pEmail);
  END IF;

  nClient := CreateClient(null, CodeToType(pType, 'client'), pUserName, nUserId, jPhone, jEmail, pInfo, pDescription);

  PERFORM NewClientName(nClient, cn.name, cn.short, cn.first, cn.last, cn.middle);

  PERFORM SubstituteUser(session_userid(), vSecret);

  id := nClient;
  userId := nUserId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.whoami ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает информацию о виртуальном пользователе.
 * @field {numeric} id - Идентификатор клиента
 * @field {numeric} userid - Идентификатор виртуального пользователя (учётной записи)
 * @field {numeric} suid - Идентификатор системного пользователя (учётной записи)
 * @field {boolean} admin - Признак администратора системы
 * @field {boolean} guest - Признак гостевого входа в систему
 * @field {json} profile - Профиль пользователя
 * @field {json} name - Ф.И.О. клиента
 * @field {json} email - Справочник электронных адресов клиента
 * @field {json} phone - Телефоный справочник клиента
 * @field {json} session - Сессия
 * @field {json} locale - Язык
 * @field {json} area - Зона
 * @field {json} interface - Интерфейс
 */
CREATE OR REPLACE VIEW api.whoami
AS
  WITH cs AS (
      SELECT current_session() AS session, oper_date() AS oper_date
  )
  SELECT c.id, s.userid, s.suid,
         IsUserRole(GetGroup('administrator'), s.userid) AS admin,
         IsUserRole(GetGroup('guest'), s.userid) AS guest,
         row_to_json(u.*) AS profile,
         json_build_object('name', c.fullname, 'short', c.shortname, 'first', c.firstname, 'last', c.lastname, 'middle', c.middlename) AS name,
         c.email::json, c.phone::json,
         json_build_object('code', s.code, 'created', s.created, 'updated', s.updated, 'agent', s.agent, 'host', s.host) AS session,
         row_to_json(l.*) AS locale,
         row_to_json(a.*) AS area,
         row_to_json(i.*) AS interface
    FROM db.session s INNER JOIN cs ON s.code = cs.session
                      INNER JOIN users u ON u.id = s.userid
                      INNER JOIN db.locale l ON l.id = s.locale
                      INNER JOIN db.area a ON a.id = s.area
                      INNER JOIN db.interface i ON i.id = s.interface
                       LEFT JOIN client c ON c.userid = s.userid;

--------------------------------------------------------------------------------
-- api.whoami ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.whoami (
) RETURNS SETOF api.whoami
AS $$
  SELECT * FROM api.whoami
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.on_confirm_email --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * СОБЫТИЕ: Подтверждает адрес электронной почты.
 * @param {numeric} pId - Идентификатор кода подтверждения
 * @return {record}
 */
CREATE OR REPLACE FUNCTION api.on_confirm_email (
  pId		    numeric
) RETURNS       void
AS $$
DECLARE
  nUserId       numeric;
BEGIN
  SELECT userid INTO nUserId FROM db.verification_code WHERE id = pId;
  IF found THEN
    PERFORM ExecuteObjectAction(GetClientByUserId(nUserId), GetAction('confirm'));
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
