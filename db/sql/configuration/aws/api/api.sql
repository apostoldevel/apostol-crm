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

  nClient     numeric;
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
    jEmail := jsonb_build_object('default', pEmail);
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
-- api.signin ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Вход в систему по имени и паролю пользователя.
 * @param {text} pUserName - Пользователь (login)
 * @param {text} pPassword - Пароль
 * @param {text} pAgent - Агент
 * @param {inet} pHost - IP адрес
 * @out param {text} session - Сессия
 * @out param {text} secret - Секретный ключ для подписи методом HMAC-256
 * @out param {text} code - Одноразовый код авторизации для получения маркера см. OAuth 2.0
 * @return {record}
 */
CREATE OR REPLACE FUNCTION api.signin (
  pUserName     text,
  pPassword     text,
  pAgent        text DEFAULT null,
  pHost         inet DEFAULT null,
  OUT session   text,
  OUT secret    text,
  OUT code      text
) RETURNS       record
AS $$
DECLARE
  nAudience     numeric;
BEGIN
  SELECT a.id INTO nAudience FROM oauth2.audience a WHERE a.code = oauth2_current_client_id();

  IF NOT found THEN
    PERFORM AudienceNotFound();
  END IF;

  session := SignIn(CreateOAuth2(nAudience, ARRAY['api']), pUserName, pPassword, pAgent, pHost);

  IF session IS NULL THEN
    RAISE EXCEPTION '%', GetErrorMessage();
  END IF;

  code := oauth2_current_code(session);
  secret := session_secret(session);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.signout -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Выход из системы.
 * @param {text} pSession - Сессия
 * @param {boolean} pCloseAll - Закрыть все сессии
 * @out param {boolean} result - Результат
 * @out param {text} message - Текст ошибки
 * @return {record}
 */
CREATE OR REPLACE FUNCTION api.signout (
  pSession      text DEFAULT current_session(),
  pCloseAll 	boolean DEFAULT false
) RETURNS       boolean
AS $$
BEGIN
  IF NOT SignOut(pSession, pCloseAll) THEN
    RAISE EXCEPTION '%', GetErrorMessage();
  END IF;
  RETURN true;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.authenticate ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Аутентификация.
 * @param {text} pSession - Сессия
 * @param {text} pSecret - Секретный код
 * @param {text} pAgent - Агент
 * @param {inet} pHost - IP адрес
 * @return {text}
 */
CREATE OR REPLACE FUNCTION api.authenticate (
  pSession    text,
  pSecret     text,
  pAgent      text DEFAULT null,
  pHost       inet DEFAULT null
) RETURNS     text
AS $$
DECLARE
  vCode       text;
BEGIN
  vCode := Authenticate(pSession, pSecret, pAgent, pHost);
  IF vCode IS NULL THEN
    RAISE EXCEPTION '%', GetErrorMessage();
  END IF;
  RETURN vCode;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.authorize ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Авторизовать.
 * @param {text} pSession - Сессия
 * @param {boolean} authorized - Результат
 * @param {text} message - Сообшение
 * @return {record}
 */
CREATE OR REPLACE FUNCTION api.authorize (
  pSession          text,
  OUT authorized    boolean,
  OUT message       text
) RETURNS           record
AS $$
BEGIN
  authorized := Authorize(pSession) IS NOT NULL;
  message := GetErrorMessage();
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.whoami ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает информацию о виртуальном пользователе.
 * @out param {numeric} id - Идентификатор клиента
 * @out param {numeric} userid - Идентификатор виртуального пользователя (учётной записи)
 * @out param {numeric} suid - Идентификатор системного пользователя (учётной записи)
 * @out param {boolean} admin - Признак администратора системы
 * @out param {boolean} guest - Признак гостевого входа в систему
 * @out param {json} profile - Профиль пользователя
 * @out param {json} name - Ф.И.О. клиента
 * @out param {json} email - Справочник электронных адресов клиента
 * @out param {json} phone - Телефоный справочник клиента
 * @out param {json} session - Сессия
 * @out param {json} locale - Язык
 * @out param {json} area - Зона
 * @out param {json} interface - Интерфейс
 * @return {table}
 */
CREATE OR REPLACE FUNCTION api.whoami (
) RETURNS TABLE (
  id                numeric,
  userid            numeric,
  suid              numeric,
  admin             boolean,
  guest             boolean,
  profile           json,
  name              json,
  email             json,
  phone             json,
  session           json,
  locale            json,
  area              json,
  interface         json
)
AS $$
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
                       LEFT JOIN client c ON c.userid = s.userid
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
