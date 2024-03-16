--------------------------------------------------------------------------------
-- FUNCTION NewClientName ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет/обновляет наименование клиента.
 * @param {uuid} pClient - Идентификатор клиента
 * @param {text} pName - Полное наименование компании/Ф.И.О.
 * @param {text} pFirst - Имя
 * @param {text} pLast - Фамилия
 * @param {text} pMiddle - Отчество
 * @param {text} pShort - Краткое наименование компании
 * @param {uuid} pLocale - Идентификатор локали
 * @param {timestamptz} pDateFrom - Дата изменения
 * @return {(void|exception)}
 */
CREATE OR REPLACE FUNCTION NewClientName (
  pClient       uuid,
  pName         text,
  pShort        text default null,
  pFirst        text default null,
  pLast         text default null,
  pMiddle       text default null,
  pLocale       uuid default current_locale(),
  pDateFrom     timestamptz default oper_date()
) RETURNS       void
AS $$
DECLARE
  uId           uuid;

  dtDateFrom    timestamptz;
  dtDateTo      timestamptz;
BEGIN
  uId := null;

  pName := NULLIF(trim(pName), '');
  pShort := NULLIF(trim(pShort), '');
  pFirst := NULLIF(trim(pFirst), '');
  pLast := NULLIF(trim(pLast), '');
  pMiddle := NULLIF(trim(pMiddle), '');

  -- получим дату значения в текущем диапозоне дат
  SELECT validFromDate, validToDate INTO dtDateFrom, dtDateTo
    FROM db.client_name
   WHERE client = pClient
     AND locale = pLocale
     AND validFromDate <= pDateFrom
     AND validToDate > pDateFrom;

  IF coalesce(dtDateFrom, MINDATE()) = pDateFrom THEN
    -- обновим значение в текущем диапозоне дат
    UPDATE db.client_name SET name = pName, short = pShort, first = pFirst, last = pLast, middle = pMiddle
     WHERE client = pClient
       AND locale = pLocale
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;
  ELSE
    -- обновим дату значения в текущем диапозоне дат
    UPDATE db.client_name SET validToDate = pDateFrom
     WHERE client = pClient
       AND locale = pLocale
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;

    INSERT INTO db.client_name (client, locale, name, short, first, last, middle, validfromdate, validToDate)
    VALUES (pClient, pLocale, pName, pShort, pFirst, pLast, pMiddle, pDateFrom, coalesce(dtDateTo, MAXDATE()));
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION EditClientName -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет/обновляет наименование клиента (вызывает метод действия 'edit').
 * @param {uuid} pClient - Идентификатор клиента
 * @param {text} pName - Полное наименование компании/Ф.И.О.
 * @param {text} pShort - Краткое наименование компании
 * @param {text} pFirst - Имя
 * @param {text} pLast - Фамилия
 * @param {text} pMiddle - Отчество
 * @param {uuid} pLocale - Идентификатор локали
 * @param {timestamptz} pDateFrom - Дата изменения
 * @return {(void|exception)}
 */
CREATE OR REPLACE FUNCTION EditClientName (
  pClient       uuid,
  pName         text,
  pShort        text default null,
  pFirst        text default null,
  pLast         text default null,
  pMiddle       text default null,
  pLocale       uuid default current_locale(),
  pDateFrom     timestamptz default oper_date()
) RETURNS       void
AS $$
DECLARE
  uMethod       uuid;

  vHash         text;
  cHash         text;

  r             record;
BEGIN
  SELECT * INTO r FROM GetClientNameRec(pClient, pLocale, pDateFrom);

  pName := coalesce(pName, r.name);
  pShort := coalesce(pShort, r.short, '');
  pFirst := coalesce(pFirst, r.first, '');
  pLast := coalesce(pLast, r.last, '');
  pMiddle := coalesce(pMiddle, r.middle, '');

  vHash := encode(digest(pName || pShort || pFirst || pLast || pMiddle, 'md5'), 'hex');
  cHash := encode(digest(r.name || coalesce(r.short, '') || coalesce(r.first, '') || coalesce(r.last, '') || coalesce(r.middle, ''), 'md5'), 'hex');

  IF vHash IS DISTINCT FROM cHash THEN
    PERFORM NewClientName(pClient, pName, CheckNull(pShort), CheckNull(pFirst), CheckNull(pLast), CheckNull(pMiddle), pLocale, pDateFrom);

    uMethod := GetMethod(GetObjectClass(pClient), GetAction('edit'));
    PERFORM ExecuteMethod(pClient, uMethod);
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetClientNameRec ---------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает наименование клиента.
 * @param {uuid} pClient - Идентификатор клиента
 * @param {uuid} pLocale - Идентификатор локали
 * @param {timestamptz} pDate - Дата
 * @return {SETOF db.client_name}
 */
CREATE OR REPLACE FUNCTION GetClientNameRec (
  pClient       uuid,
  pLocale       uuid default current_locale(),
  pDate         timestamptz default oper_date()
) RETURNS       SETOF db.client_name
AS $$
BEGIN
  RETURN QUERY SELECT *
    FROM db.client_name n
   WHERE n.client = pClient
     AND n.locale = pLocale
     AND n.validFromDate <= pDate
     AND n.validToDate > pDate;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetClientNameJson --------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает наименование клиента.
 * @param {uuid} pClient - Идентификатор клиента
 * @param {uuid} pLocale - Идентификатор локали
 * @param {timestamptz} pDate - Дата
 * @return {json}
 */
CREATE OR REPLACE FUNCTION GetClientNameJson (
  pClient       uuid,
  pLocale       uuid default current_locale(),
  pDate         timestamptz default oper_date()
) RETURNS       SETOF json
AS $$
DECLARE
  r             record;
BEGIN
  FOR r IN
    SELECT *
      FROM db.client_name n
     WHERE n.client = pClient
       AND n.locale = pLocale
       AND n.validFromDate <= pDate
       AND n.validToDate > pDate
  LOOP
    RETURN NEXT row_to_json(r);
  END LOOP;

  RETURN;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetClientName ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает полное наименование клиента.
 * @param {uuid} pClient - Идентификатор клиента
 * @param {uuid} pLocale - Идентификатор локали
 * @param {timestamptz} pDate - Дата
 * @return {(text|null|exception)}
 */
CREATE OR REPLACE FUNCTION GetClientName (
  pClient       uuid,
  pLocale       uuid default current_locale(),
  pDate         timestamptz default oper_date()
) RETURNS       text
AS $$
  SELECT name FROM GetClientNameRec(pClient, pLocale, pDate);
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetClientShortName -------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает краткое наименование клиента.
 * @param {uuid} pClient - Идентификатор клиента
 * @param {uuid} pLocale - Идентификатор локали
 * @param {timestamptz} pDate - Дата
 * @return {(text|null|exception)}
 */
CREATE OR REPLACE FUNCTION GetClientShortName (
  pClient       uuid,
  pLocale       uuid default current_locale(),
  pDate         timestamptz default oper_date()
) RETURNS       text
AS $$
  SELECT short FROM GetClientNameRec(pClient, pLocale, pDate);
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClient ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт нового клиента
 * @param {uuid} pParent - Ссылка на родительский объект
 * @param {uuid} pType - Идентификатор типа
 * @param {text} pCode - ИНН - для юридического лица | Имя пользователя (login) | null
 * @param {uuid} pUserId - Пользователь (users): Учётная запись клиента
 * @param {jsonb} pName - Полное наименование компании/Ф.И.О.
 * @param {jsonb} pPhone - Справочник телефонов
 * @param {jsonb} pEmail - Электронные адреса
 * @param {jsonb} pAddress - Почтовые адреса
 * @param {jsonb} pInfo - Дополнительная информация
 * @param {date} pBirthDay - Дата открытия | Дата рождения | null
 * @param {text} pBirthPlace - Место рождения | null
 * @param {text} pDescription - Описание
 * @return {uuid} - Id клиента
 */
CREATE OR REPLACE FUNCTION CreateClient (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pUserId       uuid,
  pName         jsonb,
  pPhone        jsonb default null,
  pEmail        jsonb default null,
  pInfo         jsonb default null,
  pBirthDay     date default null,
  pBirthPlace   text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
DECLARE
  l             record;

  uClient       uuid;
  uDocument     uuid;

  cn            record;

  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'client' THEN
    PERFORM IncorrectClassType();
  END IF;

  PERFORM FROM db.client WHERE code = pCode;

  IF FOUND THEN
    PERFORM ClientCodeExists(pCode);
  END IF;

  uDocument := CreateDocument(pParent, pType, null, pDescription);

  SELECT * INTO cn FROM jsonb_to_record(pName) AS x(name text, short text, first text, last text, middle text);

  IF NULLIF(trim(cn.short), '') IS NULL THEN
    cn.short := coalesce(NULLIF(trim(cn.name), ''), pCode);
  END IF;

  IF pUserId = null_uuid() THEN
    pUserId := CreateUser(pCode, pCode, cn.short, pPhone->>0, pEmail->>0, NULLIF(trim(cn.name), ''));
  END IF;

  INSERT INTO db.client (id, document, code, birthday, birthplace, userid, phone, email, info)
  VALUES (uDocument, uDocument, pCode, pBirthDay, pBirthPlace, pUserId, pPhone, pEmail, pInfo)
  RETURNING id INTO uClient;

  FOR l IN SELECT id FROM db.locale
  LOOP
    PERFORM NewClientName(uClient, cn.name, cn.short, cn.first, cn.last, cn.middle, l.id);
  END LOOP;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uClient, uMethod);

  RETURN uClient;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditClient ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует основные параметры клиента.
 * @param {uuid} pId - Идентификатор клиента
 * @param {uuid} pParent - Ссылка на родительский объект
 * @param {uuid} pType - Идентификатор типа
 * @param {text} pCode - ИНН - для юридического лица | Имя пользователя (login) | null
 * @param {uuid} pUserId - Пользователь (users): Учётная запись клиента
 * @param {jsonb} pName - Полное наименование компании/Ф.И.О.
 * @param {jsonb} pPhone - Справочник телефонов
 * @param {jsonb} pEmail - Электронные адреса
 * @param {jsonb} pInfo - Дополнительная информация
 * @param {date} pBirthDay - Дата открытия | Дата рождения | null
 * @param {text} pBirthPlace - Место рождения | null
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION EditClient (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pUserId       uuid default null,
  pName         jsonb default null,
  pPhone        jsonb default null,
  pEmail        jsonb default null,
  pInfo         jsonb default null,
  pBirthDay     date default null,
  pBirthPlace   text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uMethod       uuid;

  r             record;

  old           Client%rowtype;
  new           Client%rowtype;

  -- current
  cCode         text;
  cUserId       uuid;
BEGIN
  SELECT code, userid INTO cCode, cUserId FROM db.client WHERE id = pId;

  pCode := coalesce(pCode, cCode);
  pUserId := coalesce(pUserId, cUserId, null_uuid());

  IF pCode <> cCode THEN
    PERFORM FROM db.client WHERE code = pCode;
    IF FOUND THEN
      PERFORM ClientCodeExists(pCode);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, null, pDescription, pDescription, current_locale());

  SELECT * INTO old FROM Client WHERE id = pId;

  UPDATE db.client
     SET code = pCode,
         userid = CheckNull(pUserId),
         phone = CheckNull(coalesce(pPhone, phone, '{}')),
         email = CheckNull(coalesce(pEmail, email, '{}')),
         info = CheckNull(coalesce(pInfo, info, '{}')),
         birthday = CheckNull(coalesce(pBirthDay, birthday, MINDATE())),
         birthplace = CheckNull(coalesce(pBirthPlace, birthplace, ''))
   WHERE id = pId;

  FOR r IN SELECT * FROM jsonb_to_record(pName) AS x(name text, short text, first text, last text, middle text)
  LOOP
    PERFORM EditClientName(pId, r.name, r.short, r.first, r.last, r.middle);
  END LOOP;

  SELECT * INTO new FROM Client WHERE id = pId;

  uMethod := GetMethod(GetObjectClass(pId), GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod, jsonb_build_object('old', row_to_json(old), 'new', row_to_json(new)));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClient -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetClient (
  pCode     text
) RETURNS   uuid
AS $$
  SELECT id FROM db.client WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClientCode ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetClientCode (
  pClient   uuid
) RETURNS   text
AS $$
  SELECT code FROM db.client WHERE id = pClient;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClientUserId -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetClientUserId (
  pClient   uuid
) RETURNS   uuid
AS $$
  SELECT userid FROM db.client WHERE id = pClient;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClientByUserId -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetClientByUserId (
  pUserId   uuid
) RETURNS   uuid
AS $$
  SELECT id FROM db.client WHERE userid = pUserId
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION current_client -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает идентификатор текущего клиента.
 * @return {uuid} - Клиент
 */
CREATE OR REPLACE FUNCTION current_client()
RETURNS     uuid
AS $$
  SELECT id FROM db.client WHERE userid = current_userid();
$$ LANGUAGE sql STABLE
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SendPushAll -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION SendPushAll (
  pTitle    text,
  pBody     text
) RETURNS   integer
AS $$
DECLARE
  r         record;
  result    integer DEFAULT 0;
BEGIN
  IF NOT IsUserRole(GetGroup('message')) THEN
    PERFORM AccessDenied();
  END IF;

  FOR r IN SELECT c.id, userId FROM db.client c INNER JOIN db.object o ON c.document = o.id AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
  LOOP
    PERFORM SendPush(r.id, pTitle, pBody, r.userid);
    result := result + 1;
  END LOOP;

  RETURN result;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClientAccounts --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClientAccounts (
  pClient       uuid
) RETURNS       void
AS $$
DECLARE
  uActive       uuid;
  uPassive      uuid;
  uCurrency     uuid;
  uCategory     uuid;
  uDebit        uuid;
  uCredit       uuid;
BEGIN
  uActive := GetType('active.account');
  uPassive := GetType('passive.account');

  uCategory := GetCategory('chat.category');

  uCurrency := GetCurrency('USD');

  PERFORM DoEnable(CreateAccount(pClient, uActive, uCurrency, pClient, uCategory, GenAccountCode(pClient, uActive, uCurrency), 'USD account (active)'));
  PERFORM DoEnable(CreateAccount(pClient, uPassive, uCurrency, pClient, uCategory, GenAccountCode(pClient, uPassive, uCurrency), 'USD account (passive)'));

  uCurrency := GetCurrency('NIL');

  uDebit := CreateAccount(pClient, uActive, uCurrency, pClient, uCategory, GenAccountCode(pClient, uActive, uCurrency, 'gpt'), 'The account for counting the number of spent tokens (ChatGPT) (active)');
  uCredit := CreateAccount(pClient, uPassive, uCurrency, pClient, uCategory, GenAccountCode(pClient, uPassive, uCurrency, 'gpt'), 'The account for counting the number of spent tokens (ChatGPT) (passive)');

  PERFORM DoEnable(uDebit);
  PERFORM DoEnable(uCredit);

  uDebit := CreateAccount(pClient, uActive, uCurrency, pClient, uCategory, GenAccountCode(pClient, uActive, uCurrency, 'wrd'), 'An account for counting the number of words (active)');
  uCredit := CreateAccount(pClient, uPassive, uCurrency, pClient, uCategory, GenAccountCode(pClient, uPassive, uCurrency, 'wrd'), 'An account for counting the number of words (passive)');

  PERFORM DoEnable(uDebit);
  PERFORM DoEnable(uCredit);

  PERFORM DoDisable(Payment(pClient, uDebit, uCredit, 1000, 'Trial words for Chat.'));

  uCurrency := GetCurrency('GEN');
  uCategory := GetCategory('text.category');

  uDebit := CreateAccount(pClient, uActive, uCurrency, pClient, uCategory, GenAccountCode(pClient, uActive, uCurrency, 'txt'), 'Text generation account (active)');
  uCredit := CreateAccount(pClient, uPassive, uCurrency, pClient, uCategory, GenAccountCode(pClient, uPassive, uCurrency, 'txt'), 'Text generation account (passive)');

  PERFORM DoEnable(uDebit);
  PERFORM DoEnable(uCredit);

  PERFORM DoDisable(Payment(pClient, uDebit, uCredit, 5, 'For trial text generation.'));

  uCategory := GetCategory('media.category');

  uDebit := CreateAccount(pClient, uActive, uCurrency, pClient, uCategory, GenAccountCode(pClient, uActive, uCurrency, 'img'), 'Image generation account (active)');
  uCredit := CreateAccount(pClient, uPassive, uCurrency, pClient, uCategory, GenAccountCode(pClient, uPassive, uCurrency, 'img'), 'Image generation account (passive)');

  PERFORM DoEnable(uDebit);
  PERFORM DoEnable(uCredit);

  --PERFORM DoDisable(Payment(pClient, uDebit, uCredit, 3, 'For trial media generation.'));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
