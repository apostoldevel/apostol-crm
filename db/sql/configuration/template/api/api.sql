--------------------------------------------------------------------------------
-- API -------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.signup ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Регистрация.
 * @param {varchar} pType - Tип клиента
 * @param {varchar} pUserName - Имя пользователя (login)
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
  pUserName     varchar,
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

  arTypes       text[];
  arKeys        text[];
BEGIN
  pType := coalesce(lower(pType), 'physical');

  IF StrPos(pType, '.client') = 0 THEN
    pType := pType || '.client';
  END IF;

  arTypes := array_cat(arTypes, GetTypeCodes(GetClass('client')));
  IF array_position(arTypes, pType::text) IS NULL THEN
    PERFORM IncorrectCode(pType, arTypes);
  END IF;

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

  pPassword := coalesce(NULLIF(pPassword, ''), GenSecretKey(9));

  PERFORM SetUserId(GetUser('admin'));

  nUserId := CreateUser(pUserName, pPassword, coalesce(cn.short, cn.name), pPhone, pEmail, cn.name);

  PERFORM AddMemberToGroup(nUserId, GetGroup('user'));

  IF pPhone IS NOT NULL THEN
    jPhone := jsonb_build_object('mobile', pPhone);
  END IF;

  IF pEmail IS NOT NULL THEN
    jEmail := jsonb_build_object('default', pEmail);
  END IF;

  nClient := CreateClient(null, GetType(pType), pUserName, nUserId, jPhone, jEmail, pInfo, pDescription);

  PERFORM NewClientName(nClient, cn.name, cn.short, cn.first, cn.last, cn.middle);

  PERFORM SetUserId(session_userid());

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
-- LOCALE ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.locale ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Язык
 */
CREATE OR REPLACE VIEW api.locale
AS
  SELECT * FROM Locale;

GRANT SELECT ON api.locale TO daemon;

--------------------------------------------------------------------------------
-- EVENT LOG -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.event_log
AS
  SELECT * FROM EventLog;

GRANT SELECT ON api.event_log TO daemon;

--------------------------------------------------------------------------------
-- api.event_log ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Журнал событий текущего пользователя.
 * @param {char} pType - Тип события: {M|W|E}
 * @param {integer} pCode - Код
 * @param {timestamp} pDateFrom - Дата начала периода
 * @param {timestamp} pDateTo - Дата окончания периода
 * @return {SETOF api.event_log} - Записи
 */
CREATE OR REPLACE FUNCTION api.event_log (
  pType		    char DEFAULT null,
  pCode		    numeric DEFAULT null,
  pDateFrom	    timestamp DEFAULT null,
  pDateTo	    timestamp DEFAULT null
) RETURNS	    SETOF api.event_log
AS $$
  SELECT *
    FROM api.event_log
   WHERE type = coalesce(pType, type)
     AND username = current_username()
     AND code = coalesce(pCode, code)
     AND datetime >= coalesce(pDateFrom, MINDATE())
     AND datetime < coalesce(pDateTo, MAXDATE())
   ORDER BY datetime DESC, id
   LIMIT 500
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.write_to_log ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.write_to_log (
  pType		    text,
  pCode		    numeric,
  pText		    text
) RETURNS	    boolean
AS $$
BEGIN
  PERFORM WriteToEventLog(pType, pCode, pText);

  RETURN true;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.sql ---------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает динамический SQL запрос.
 * @param {text} pScheme - Схема
 * @param {text} pTable - Таблица
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {text} - SQL запрос

 Где сравнение (compare):
   EQL - равно
   NEQ - не равно
   LSS - меньше
   LEQ - меньше или равно
   GTR - больше
   GEQ - больше или равно
   GIN - для поиска вхождений JSON

   LKE - LIKE - Значение ключа (value) должно передаваться вместе со знаком '%' в нужном вам месте
   ISN - IS NULL - Ключ (value) должен быть опушен
   INN - IS NOT NULL - Ключ (value) должен быть опушен
 */
CREATE OR REPLACE FUNCTION api.sql (
  pScheme       text,
  pTable        text,
  pSearch       jsonb DEFAULT null,
  pFilter       jsonb DEFAULT null,
  pLimit        integer DEFAULT null,
  pOffSet       integer DEFAULT null,
  pOrderBy      jsonb DEFAULT null
) RETURNS       text
AS $$
DECLARE
  r             record;

  vWith         text;
  vSelect       text;
  vWhere        text;
  vJoin         text;

  vCondition    text;
  vField        text;
  vCompare      text;
  vValue        text;
  vLStr         text;
  vRStr         text;

  arTables      text[];
  arValues      text[];
  arColumns     text[];
BEGIN
  arTables := array_cat(null, ARRAY['charge_point', 'card', 'client', 'invoice', 'order', 'tariff', 'client_tariff',
      'status_notification', 'transaction', 'meter_value', 'address', 'address_tree', 'calendar',
      'object_file', 'object_data', 'object_address', 'object_coordinates'
  ]);

  IF array_position(arTables, pTable) IS NULL THEN
    PERFORM IncorrectValueInArray(pTable, 'sql/api/table', arTables);
  END IF;

  vSelect := coalesce(vWith, '') || 'SELECT ' || coalesce(array_to_string(arColumns, ', '), 't.*') || E'\n  FROM ' || pScheme || '.' || pTable || ' t ' || coalesce(vJoin, '');

  IF pFilter IS NOT NULL THEN
    PERFORM CheckJsonbKeys(pTable || '/filter', arColumns, pFilter);

    FOR r IN SELECT * FROM jsonb_each(pFilter)
    LOOP
      pSearch := coalesce(pSearch, '[]'::jsonb) || jsonb_build_object('field', r.key, 'value', r.value);
    END LOOP;
  END IF;

  IF pSearch IS NOT NULL THEN

    IF jsonb_typeof(pSearch) = 'array' THEN

      PERFORM CheckJsonbKeys(pTable || '/search', ARRAY['condition', 'field', 'compare', 'value', 'valarr', 'lstr', 'rstr'], pSearch);

      FOR r IN SELECT * FROM jsonb_to_recordset(pSearch) AS x(condition text, field text, compare text, value text, valarr jsonb, lstr text, rstr text)
      LOOP
        vCondition := coalesce(upper(r.condition), 'AND');
        vField     := coalesce(lower(r.field), '<null>');
        vCompare   := coalesce(upper(r.compare), 'EQL');
        vLStr	   := coalesce(r.lstr, '');
        vRStr	   := coalesce(r.rstr, '');

        vField := quote_literal_json(vField);

        arValues := array_cat(null, ARRAY['AND', 'OR']);
        IF array_position(arValues, vCondition) IS NULL THEN
          PERFORM IncorrectValueInArray(coalesce(r.condition, '<null>'), 'condition', arValues);
        END IF;
/*
        IF array_position(arColumns, vField) IS NULL THEN
          PERFORM IncorrectValueInArray(coalesce(r.field, '<null>'), 'field', arColumns);
        END IF;
*/
        IF r.valarr IS NOT NULL THEN
          vValue := jsonb_array_to_string(r.valarr, ',');

          IF vWhere IS NULL THEN
            vWhere := E'\n WHERE ' || vField || ' IN (' || vValue || ')';
          ELSE
            vWhere := vWhere || E'\n  ' || vCondition || ' ' || vField || ' IN (' || vValue  || ')';
          END IF;

        ELSE
          vValue := quote_nullable(r.value);

          arValues := array_cat(null, ARRAY['EQL', 'NEQ', 'LSS', 'LEQ', 'GTR', 'GEQ', 'GIN', 'LKE', 'ISN', 'INN']);
          IF array_position(arValues, vCompare) IS NULL THEN
            PERFORM IncorrectValueInArray(coalesce(r.compare, '<null>'), 'compare', arValues);
          END IF;

          IF vWhere IS NULL THEN
            vWhere := E'\n WHERE ' || vLStr || vField || GetCompare(vCompare) || vValue || vRStr;
          ELSE
            vWhere := vWhere || E'\n  ' || vCondition || ' ' || vLStr || vField || GetCompare(vCompare) || vValue || vRStr;
          END IF;
        END IF;

      END LOOP;

    ELSE
      PERFORM IncorrectJsonType(jsonb_typeof(pSearch), 'array');
    END IF;

  END IF;

  vSelect := vSelect || coalesce(vWhere, '');

  IF pOrderBy IS NOT NULL THEN
--    PERFORM CheckJsonbValues('orderby', array_cat(arColumns, array_add_text(arColumns, ' desc')), pOrderBy);
    vSelect := vSelect || E'\n ORDER BY ' || array_to_string(array_quote_literal_json(JsonbToStrArray(pOrderBy)), ',');
  ELSE
    vSelect := vSelect || E'\n ORDER BY id';
  END IF;

  IF pLimit IS NOT NULL THEN
    vSelect := vSelect || E'\n LIMIT ' || pLimit;
  END IF;

  IF pOffSet IS NOT NULL THEN
    vSelect := vSelect || E'\nOFFSET ' || pOffSet;
  END IF;

  RAISE NOTICE '%', vSelect;

  RETURN vSelect;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
