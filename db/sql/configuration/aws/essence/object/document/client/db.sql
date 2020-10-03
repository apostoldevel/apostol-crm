--------------------------------------------------------------------------------
-- db.client -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.client (
    id			numeric(12) PRIMARY KEY,
    document	numeric(12) NOT NULL,
    code		varchar(30) NOT NULL,
    userId		numeric(12),
    phone		jsonb,
    email		jsonb,
    info		jsonb,
    CONSTRAINT fk_client_document FOREIGN KEY (document) REFERENCES db.document(id),
    CONSTRAINT fk_client_user FOREIGN KEY (userid) REFERENCES db.user(id)
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.client IS 'Клиент.';

COMMENT ON COLUMN db.client.id IS 'Идентификатор';
COMMENT ON COLUMN db.client.document IS 'Документ';
COMMENT ON COLUMN db.client.code IS 'Код клиента';
COMMENT ON COLUMN db.client.userid IS 'Учетная запись клиента';
COMMENT ON COLUMN db.client.phone IS 'Справочник телефонов';
COMMENT ON COLUMN db.client.email IS 'Электронные адреса';
COMMENT ON COLUMN db.client.info IS 'Дополнительная информация';

--------------------------------------------------------------------------------

CREATE INDEX ON db.client (document);

CREATE UNIQUE INDEX ON db.client (userid);
CREATE UNIQUE INDEX ON db.client (code);

CREATE INDEX ON db.client USING GIN (phone jsonb_path_ops);
CREATE INDEX ON db.client USING GIN (email jsonb_path_ops);
CREATE INDEX ON db.client USING GIN (info jsonb_path_ops);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_client_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL OR NEW.id = 0 THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := encode(gen_random_bytes(12), 'hex');
  END IF;

  IF NEW.userid IS NOT NULL THEN
    UPDATE db.object SET owner = NEW.userid WHERE id = NEW.document;
  END IF;

  RAISE DEBUG 'Создан клиент Id: %', NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_client_insert
  BEFORE INSERT ON db.client
  FOR EACH ROW
  EXECUTE PROCEDURE ft_client_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_client_update()
RETURNS trigger AS $$
DECLARE
  vStr    text;
BEGIN
  IF NOT CheckObjectAccess(NEW.document, B'010') THEN
    PERFORM AccessDenied();
  END IF;

  IF OLD.userid IS NULL AND NEW.userid IS NOT NULL THEN
    UPDATE db.object SET owner = NEW.userid WHERE id = NEW.document;
  END IF;

  IF NEW.email IS NOT NULL THEN
    IF jsonb_typeof(NEW.email) = 'array' THEN
      vStr = NEW.email->>0;
    ELSE
      vStr = NEW.email->>'default';
    END IF;

    IF vStr IS NOT NULL THEN
      UPDATE db.user SET email = vStr WHERE id = NEW.userid;
    END IF;
  END IF;

  IF NEW.phone IS NOT NULL THEN
    IF jsonb_typeof(NEW.phone) = 'array' THEN
      vStr = NEW.phone->>0;
    ELSE
      vStr = NEW.phone->>'mobile';
    END IF;

    IF vStr IS NOT NULL THEN
      UPDATE db.user SET phone = vStr WHERE id = NEW.userid;
    END IF;
  END IF;

  RAISE DEBUG 'Обнавлён клиент Id: %', NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_client_update
  BEFORE UPDATE ON db.client
  FOR EACH ROW
  EXECUTE PROCEDURE ft_client_update();

--------------------------------------------------------------------------------
-- db.client_name --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.client_name (
    Id			    numeric(12) PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_REF'),
    Client		    numeric(12) NOT NULL,
    Locale		    numeric(12) NOT NULL,
    Name		    text NOT NULL,
    Short		    text,
    First		    text,
    Last		    text,
    Middle		    text,
    validFromDate	timestamp DEFAULT Now() NOT NULL,
    validToDate		timestamp DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL,
    CONSTRAINT fk_client_name_client FOREIGN KEY (client) REFERENCES db.client(id),
    CONSTRAINT fk_client_name_locale FOREIGN KEY (locale) REFERENCES db.locale(id)
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.client_name IS 'Наименование клиента.';

COMMENT ON COLUMN db.client_name.client IS 'Идентификатор клиента';
COMMENT ON COLUMN db.client_name.locale IS 'Язык';
COMMENT ON COLUMN db.client_name.name IS 'Полное наименование компании/Ф.И.О.';
COMMENT ON COLUMN db.client_name.short IS 'Краткое наименование компании';
COMMENT ON COLUMN db.client_name.first IS 'Имя';
COMMENT ON COLUMN db.client_name.last IS 'Фамилия';
COMMENT ON COLUMN db.client_name.middle IS 'Отчество';
COMMENT ON COLUMN db.client_name.validFromDate IS 'Дата начала периода действия';
COMMENT ON COLUMN db.client_name.validToDate IS 'Дата окончания периода действия';

--------------------------------------------------------------------------------

CREATE INDEX ON db.client_name (client);
CREATE INDEX ON db.client_name (locale);
CREATE INDEX ON db.client_name (name);
CREATE INDEX ON db.client_name (name text_pattern_ops);
CREATE INDEX ON db.client_name (short);
CREATE INDEX ON db.client_name (short text_pattern_ops);
CREATE INDEX ON db.client_name (first);
CREATE INDEX ON db.client_name (first text_pattern_ops);
CREATE INDEX ON db.client_name (last);
CREATE INDEX ON db.client_name (last text_pattern_ops);
CREATE INDEX ON db.client_name (middle);
CREATE INDEX ON db.client_name (middle text_pattern_ops);
CREATE INDEX ON db.client_name (first, last, middle);

CREATE INDEX ON db.client_name (locale, validFromDate, validToDate);

CREATE UNIQUE INDEX ON db.client_name (client, locale, validFromDate, validToDate);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_client_name_insert_update()
RETURNS trigger AS $$
DECLARE
  nUserId	NUMERIC;
BEGIN
  IF NEW.Locale IS NULL THEN
    NEW.Locale := current_locale();
  END IF;

  IF NEW.Name IS NULL THEN
    IF NEW.Last IS NOT NULL THEN
      NEW.Name := NEW.Last;
    END IF;

    IF NEW.First IS NOT NULL THEN
      IF NEW.Name IS NULL THEN
        NEW.Name := NEW.First;
      ELSE
        NEW.Name := NEW.Name || ' ' || NEW.First;
      END IF;
    END IF;

    IF NEW.Middle IS NOT NULL THEN
      IF NEW.Name IS NOT NULL THEN
        NEW.Name := NEW.Name || ' ' || NEW.Middle;
      END IF;
    END IF;
  END IF;

  IF NEW.Name IS NULL THEN
    NEW.Name := 'Клиент ' || TRIM(TO_CHAR(NEW.Client, '999999999999'));
  END IF;

  UPDATE db.object SET label = NEW.Name WHERE Id = NEW.Client;

  SELECT UserId INTO nUserId FROM db.client WHERE Id = NEW.Client;
  IF nUserId IS NOT NULL THEN
    UPDATE db.user SET name = NEW.name WHERE Id = nUserId;
    UPDATE db.profile
       SET given_name = NEW.first,
           family_name = NEW.last,
           patronymic_name = NEW.middle
     WHERE userId = nUserId;
  END IF;

  --RAISE DEBUG '[%] [%] %, %, %, %', TG_OP, NEW.client, NEW.name, NEW.short, NEW.first, NEW.last, NEW.middle;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_client_name_insert_update
  BEFORE INSERT OR UPDATE ON db.client_name
  FOR EACH ROW
  EXECUTE PROCEDURE ft_client_name_insert_update();

--------------------------------------------------------------------------------
-- FUNCTION NewClientName ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет/обновляет наименование клиента.
 * @param {numeric} pClient - Идентификатор клиента
 * @param {text} pName - Полное наименование компании/Ф.И.О.
 * @param {text} pFirst - Имя
 * @param {text} pLast - Фамилия
 * @param {text} pMiddle - Отчество
 * @param {text} pShort - Краткое наименование компании
 * @param {varchar} pLocaleCode - Код языка
 * @param {timestamp} pDateFrom - Дата изменения
 * @return {(void|exception)}
 */
CREATE OR REPLACE FUNCTION NewClientName (
  pClient	    numeric,
  pName		    text,
  pShort	    text default null,
  pFirst	    text default null,
  pLast		    text default null,
  pMiddle	    text default null,
  pLocaleCode   varchar default locale_code(),
  pDateFrom	    timestamp default oper_date()
) RETURNS 	    void
AS $$
DECLARE
  nId		    numeric;
  nLocale       numeric;

  dtDateFrom    timestamp;
  dtDateTo 	    timestamp;
BEGIN
  nId := null;

  pName := NULLIF(pName, '');
  pShort := NULLIF(pShort, '');
  pFirst := NULLIF(pFirst, '');
  pLast := NULLIF(pLast, '');
  pMiddle := NULLIF(pMiddle, '');

  SELECT id INTO nLocale FROM db.locale WHERE code = coalesce(pLocaleCode, 'ru');

  IF not found THEN
    PERFORM IncorrectLocaleCode(pLocaleCode);
  END IF;

  -- получим дату значения в текущем диапозоне дат
  SELECT max(validFromDate), max(validToDate) INTO dtDateFrom, dtDateTo
    FROM db.client_name
   WHERE Client = pClient
     AND Locale = nLocale
     AND validFromDate <= pDateFrom
     AND validToDate > pDateFrom;

  IF dtDateFrom = pDateFrom THEN
    -- обновим значение в текущем диапозоне дат
    UPDATE db.client_name SET name = pName, short = pShort, first = pFirst, last = pLast, middle = pMiddle
     WHERE Client = pClient
       AND Locale = nLocale
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;
  ELSE
    -- обновим дату значения в текущем диапозоне дат
    UPDATE db.client_name SET validToDate = pDateFrom
     WHERE Client = pClient
       AND Locale = nLocale
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;

    INSERT INTO db.client_name (client, locale, name, short, first, last, middle, validfromdate, validToDate)
    VALUES (pClient, nLocale, pName, pShort, pFirst, pLast, pMiddle, pDateFrom, coalesce(dtDateTo, MAXDATE()));
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
 * @param {numeric} pClient - Идентификатор клиента
 * @param {text} pName - Полное наименование компании/Ф.И.О.
 * @param {text} pShort - Краткое наименование компании
 * @param {text} pFirst - Имя
 * @param {text} pLast - Фамилия
 * @param {text} pMiddle - Отчество
 * @param {varchar} pLocaleCode - Код языка
 * @param {timestamp} pDateFrom - Дата изменения
 * @return {(void|exception)}
 */
CREATE OR REPLACE FUNCTION EditClientName (
  pClient	    numeric,
  pName		    text,
  pShort	    text default null,
  pFirst	    text default null,
  pLast		    text default null,
  pMiddle	    text default null,
  pLocaleCode   varchar default locale_code(),
  pDateFrom	    timestamp default oper_date()
) RETURNS 	    void
AS $$
DECLARE
  nMethod	    numeric;

  vHash		    text;
  cHash		    text;

  r		        record;
BEGIN
  SELECT * INTO r FROM GetClientNameRec(pClient, pLocaleCode, pDateFrom);

  pName := coalesce(pName, r.name);
  pShort := coalesce(pShort, r.short, '<null>');
  pFirst := coalesce(pFirst, r.first, '<null>');
  pLast := coalesce(pLast, r.last, '<null>');
  pMiddle := coalesce(pMiddle, r.middle, '<null>');

  vHash := encode(digest(pName || pShort || pFirst || pLast || pMiddle, 'md5'), 'hex');
  cHash := encode(digest(r.name || coalesce(r.short, '<null>') || coalesce(r.first, '<null>') || coalesce(r.last, '<null>') || coalesce(r.middle, '<null>'), 'md5'), 'hex');

  IF vHash <> cHash THEN
    PERFORM NewClientName(pClient, pName, CheckNull(pShort), CheckNull(pFirst), CheckNull(pLast), CheckNull(pMiddle), pLocaleCode, pDateFrom);

    nMethod := GetMethod(GetObjectClass(pClient), null, GetAction('edit'));
    PERFORM ExecuteMethod(pClient, nMethod);
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetClientNameRec ---------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает наименование клиента.
 * @param {numeric} pClient - Идентификатор клиента
 * @param {varchar} pLocaleCode - Код языка
 * @param {timestamp} pDate - Дата
 * @return {SETOF db.client_name}
 */
CREATE OR REPLACE FUNCTION GetClientNameRec (
  pClient	    numeric,
  pLocaleCode   varchar default locale_code(),
  pDate		    timestamp default oper_date()
) RETURNS	    SETOF db.client_name
AS $$
DECLARE
  nLocale       numeric;
BEGIN
  SELECT id INTO nLocale FROM db.locale WHERE code = coalesce(pLocaleCode, 'ru');

  IF NOT FOUND THEN
    PERFORM IncorrectLocaleCode(pLocaleCode);
  END IF;

  RETURN QUERY SELECT *
    FROM db.client_name n
   WHERE n.client = pClient
     AND n.locale = nLocale
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
 * @param {numeric} pClient - Идентификатор клиента
 * @param {varchar} pLocaleCode - Код языка
 * @param {timestamp} pDate - Дата
 * @return {json}
 */
CREATE OR REPLACE FUNCTION GetClientNameJson (
  pClient	    numeric,
  pLocaleCode   varchar default locale_code(),
  pDate		    timestamp default oper_date()
) RETURNS       SETOF json
AS $$
DECLARE
  r             record;
  nLocale       numeric;
BEGIN
  SELECT id INTO nLocale FROM db.locale WHERE code = coalesce(pLocaleCode, 'ru');

  IF NOT FOUND THEN
    PERFORM IncorrectLocaleCode(pLocaleCode);
  END IF;

  FOR r IN
    SELECT *
      FROM db.client_name n
     WHERE n.client = pClient
       AND n.locale = nLocale
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
 * @param {numeric} pClient - Идентификатор клиента
 * @param {varchar} pLocaleCode - Код языка
 * @param {timestamp} pDate - Дата
 * @return {(text|null|exception)}
 */
CREATE OR REPLACE FUNCTION GetClientName (
  pClient       numeric,
  pLocaleCode	varchar default locale_code(),
  pDate		    timestamp default oper_date()
) RETURNS       text
AS $$
DECLARE
  vName		    text;
BEGIN
  SELECT name INTO vName FROM GetClientNameRec(pClient, pLocaleCode, pDate);

  RETURN vName;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetClientShortName -------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает краткое наименование клиента.
 * @param {numeric} pClient - Идентификатор клиента
 * @param {varchar} pLocaleCode - Код языка
 * @param {timestamp} pDate - Дата
 * @return {(text|null|exception)}
 */
CREATE OR REPLACE FUNCTION GetClientShortName (
  pClient	    numeric,
  pLocaleCode   varchar default locale_code(),
  pDate         timestamp default oper_date()
) RETURNS       text
AS $$
DECLARE
  vShort        text;
BEGIN
  SELECT short INTO vShort FROM GetClientNameRec(pClient, pLocaleCode, pDate);

  RETURN vShort;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClient ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт нового клиента
 * @param {numeric} pParent - Ссылка на родительский объект: VObject.Parent | null
 * @param {numeric} pType - Тип: VClientType.Id
 * @param {varchar} pCode - ИНН - для юридического лица | null
 * @param {numeric} pUserId - Пользователь (users): Учётная запись клиента
 * @param {jsonb} pPhone - Справочник телефонов
 * @param {jsonb} pEmail - Электронные адреса
 * @param {jsonb} pAddress - Почтовые адреса
 * @param {jsonb} pInfo - Дополнительная информация
 * @param {text} pDescription - Описание
 * @return {numeric} - Id клиента
 */
CREATE OR REPLACE FUNCTION CreateClient (
  pParent	    numeric,
  pType		    numeric,
  pCode		    varchar,
  pUserId	    numeric default null,
  pPhone	    jsonb default null,
  pEmail	    jsonb default null,
  pInfo         jsonb default null,
  pDescription	text default null
) RETURNS 	    numeric
AS $$
DECLARE
  nId		    numeric;
  nClient	    numeric;
  nDocument	    numeric;

  nClass	    numeric;
  nMethod	    numeric;
BEGIN
  SELECT class INTO nClass FROM type WHERE id = pType;

  IF nClass IS NULL OR GetClassCode(nClass) <> 'client' THEN
    PERFORM IncorrectClassType();
  END IF;

  SELECT id INTO nId FROM db.client WHERE code = pCode;

  IF found THEN
    PERFORM ClientCodeExists(pCode);
  END IF;

  nDocument := CreateDocument(pParent, pType, null, pDescription);

  INSERT INTO db.client (id, document, code, userid, phone, email, info)
  VALUES (nDocument, nDocument, pCode, pUserId, pPhone, pEmail, pInfo)
  RETURNING id INTO nClient;

  nMethod := GetMethod(nClass, null, GetAction('create'));
  PERFORM ExecuteMethod(nClient, nMethod);

  RETURN nClient;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditClient ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Меняет основные параметры клиента.
 * @param {numeric} pId - Идентификатор клиента
 * @param {numeric} pParent - Ссылка на родительский объект: VObject.Parent | null
 * @param {numeric} pType - Тип: VClientType.Id
 * @param {varchar} pCode - ИНН - для юридического лица | null
 * @param {numeric} pUserId - Пользователь (users): Учётная запись клиента
 * @param {jsonb} pPhone - Справочник телефонов
 * @param {jsonb} pEmail - Электронные адреса
 * @param {jsonb} pInfo - Дополнительная информация
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION EditClient (
  pId		    numeric,
  pParent	    numeric default null,
  pType		    numeric default null,
  pCode		    varchar default null,
  pUserId	    numeric default null,
  pPhone	    jsonb default null,
  pEmail	    jsonb default null,
  pInfo         jsonb default null,
  pDescription	text default null
) RETURNS 	    void
AS $$
DECLARE
  nId		    numeric;
  nMethod	    numeric;

  old           db.client%rowtype;
  new           db.client%rowtype;

  -- current
  cParent	    numeric;
  cType		    numeric;
  cCode		    varchar;
  cUserId	    numeric;
  cDescription	text;
BEGIN
  SELECT parent, type INTO cParent, cType FROM db.object WHERE id = pId;
  SELECT description INTO cDescription FROM db.document WHERE id = pId;
  SELECT code, userid INTO cCode, cUserId FROM db.client WHERE id = pId;

  pParent := coalesce(pParent, cParent, 0);
  pType := coalesce(pType, cType);
  pCode := coalesce(pCode, cCode);
  pUserId := coalesce(pUserId, cUserId, 0);
  pDescription := coalesce(pDescription, cDescription, '<null>');

  IF pCode <> cCode THEN
    SELECT id INTO nId FROM db.client WHERE code = pCode;
    IF found THEN
      PERFORM ClientCodeExists(pCode);
    END IF;
  END IF;

  IF pParent <> coalesce(cParent, 0) THEN
    UPDATE db.object SET parent = CheckNull(pParent) WHERE id = pId;
  END IF;

  IF pType <> cType THEN
    UPDATE db.object SET type = pType WHERE id = pId;
  END IF;

  IF pDescription <> coalesce(cDescription, '<null>') THEN
    UPDATE db.document SET description = CheckNull(pDescription) WHERE id = pId;
  END IF;

  SELECT * INTO old FROM db.client WHERE id = pId;

  UPDATE db.client
     SET code = pCode,
         userid = CheckNull(pUserId),
         phone = CheckNull(coalesce(pPhone, phone, '{}')),
         email = CheckNull(coalesce(pEmail, email, '{}')),
         info = CheckNull(coalesce(pInfo, info, '{}'))
   WHERE id = pId;

  SELECT * INTO new FROM db.client WHERE id = pId;

  nMethod := GetMethod(GetObjectClass(pId), null, GetAction('edit'));
  PERFORM ExecuteMethod(pId, nMethod, jsonb_build_object('old', row_to_json(old), 'new', row_to_json(new)));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClient -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetClient (
  pCode		varchar
) RETURNS	numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  SELECT id INTO nId FROM db.client WHERE code = pCode;
  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClientUserId -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetClientUserId (
  pClient	numeric
) RETURNS	numeric
AS $$
DECLARE
  nUserId	numeric;
BEGIN
  SELECT userid INTO nUserId FROM db.client WHERE id = pClient;
  RETURN nUserId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClientByUserId -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetClientByUserId (
  pUserId       numeric
) RETURNS       numeric
AS $$
DECLARE
  nId           numeric;
BEGIN
  SELECT id INTO nId FROM db.client WHERE userid = pUserId;
  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- ClientName ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ClientName (Id, Client, Locale, LocaleCode, LocaleName, LocaleDescription,
  FullName, ShortName, LastName, FirstName, MiddleName, validFromDate, validToDate
)
AS
  SELECT n.id, n.client, n.locale, l.code, l.name, l.description,
         n.name, n.short, n.last, n.first, n.middle, n.validfromdate, n.validToDate
    FROM db.client_name n INNER JOIN db.locale l ON l.id = n.locale;

GRANT SELECT ON ClientName TO administrator;

--------------------------------------------------------------------------------
-- Client ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Client (Id, Document, Code, UserId,
  FullName, ShortName, LastName, FirstName, MiddleName,
  Phone, Email, Info, EmailVerified, PhoneVerified,
  Locale, LocaleCode, LocaleName, LocaleDescription
)
AS
  WITH lc AS (
    SELECT id FROM db.locale WHERE code = locale_code()
  )
  SELECT c.id, c.document, c.code, c.userid,
         n.name, n.short, n.last, n.first, n.middle,
         c.phone, c.email, c.info, up.email_verified, up.phone_verified,
         n.locale, l.code, l.name, l.description
    FROM db.client c INNER JOIN db.client_name n ON n.client = c.id AND n.validfromdate <= now() AND n.validToDate > now()
                     INNER JOIN lc               ON n.locale = lc.id
                     INNER JOIN db.profile up    ON c.userid = up.userid
                     INNER JOIN db.locale l      ON l.id = n.locale;

GRANT SELECT ON Client TO administrator;

--------------------------------------------------------------------------------
-- ObjectClient ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectClient (Id, Object, Parent,
  Essence, EssenceCode, EssenceName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, UserId,
  FullName, ShortName, LastName, FirstName, MiddleName,
  Phone, Email, Info, EmailVerified, PhoneVerified,
  Locale, LocaleCode, LocaleName, LocaleDescription,
  Label, Description,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Area, AreaCode, AreaName
)
AS
  SELECT c.id, d.object, d.parent,
         d.essence, d.essencecode, d.essencename,
         d.class, d.classcode, d.classlabel,
         d.type, d.typecode, d.typename, d.typedescription,
         c.code, c.userid,
         c.fullname, c.shortname, c.lastname, c.firstname, c.middlename,
         c.phone, c.email, c.info, emailverified, phoneverified,
         c.locale, c.localecode, c.localename, c.localedescription,
         d.label, d.description,
         d.statetype, d.statetypecode, d.statetypename,
         d.state, d.statecode, d.statelabel, d.lastupdate,
         d.owner, d.ownercode, d.ownername, d.created,
         d.oper, d.opercode, d.opername, d.operdate,
         d.area, d.areacode, d.areaname
    FROM Client c INNER JOIN ObjectDocument d ON d.id = c.document;

GRANT SELECT ON ObjectClient TO administrator;

--------------------------------------------------------------------------------
-- ClientTariff ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ClientTariff (Id, Client, Tariff, TypeCode,
    Code, Name, Description, Cost,
    validFromDate, validToDate
)
AS
  SELECT ol.id, ol.object, ol.linked, ol.key,
         r.code, r.name, r.description, f.cost,
         ol.validfromdate, ol.validtodate
    FROM db.object_link ol INNER JOIN db.reference r ON r.id = ol.linked
                           INNER JOIN db.tariff f ON f.reference = r.id;

GRANT SELECT ON ClientTariff TO administrator;

--------------------------------------------------------------------------------
-- FUNCTION GetClientTariff ----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает стоимость тарифа.
 * @param {numeric} pObject - Идентификатор объекта (клиента)
 * @param {numeric} pType - Идентификатор типа тарифа
 * @param {timestamp} pDate - Дата
 * @return {text}
 */
CREATE OR REPLACE FUNCTION GetClientTariff (
  pObject	numeric,
  pKey	    varchar,
  pDate		timestamp DEFAULT oper_date()
) RETURNS	numeric
AS $$
DECLARE
  nTariff	numeric;
BEGIN
  SELECT Linked INTO nTariff
    FROM db.object_link
   WHERE Object = pObject
     AND Key = pKey
     AND validFromDate <= pDate
     AND ValidToDate > pDate;

  RETURN GetTariffCost(nTariff);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClientTariff -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetClientTariff (
  pClient	numeric,
  pDate		timestamp default oper_date()
) RETURNS	text[]
AS $$
DECLARE
  arResult	text[];
  r		    ClientTariff%rowtype;
BEGIN
  FOR r IN
    SELECT Tariff as Id, TypeCode,
           Code, Name, Description, Cost, validFromDate, validToDate
      FROM ClientTariff
     WHERE client = pClient
       AND validFromDate <= pDate
       AND ValidToDate > pDate
  LOOP
    arResult := array_cat(arResult, ARRAY[r.id, r.typecode, r.code, r.name, r.description, r.cost, r.validFromDate, r.validToDate]);
  END LOOP;

  RETURN arResult;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClientTariffJson ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetClientTariffJson (
  pClient	numeric,
  pDate		timestamp default oper_date()
) RETURNS	json
AS $$
DECLARE
  arResult	json[];
  r		    record;
BEGIN
  FOR r IN
    SELECT Tariff as Id, TypeCode,
           Code, Name, Description, Cost, validFromDate, validToDate
      FROM ClientTariff
     WHERE client = pClient
       AND validFromDate <= pDate
       AND ValidToDate > pDate
  LOOP
    arResult := array_append(arResult, row_to_json(r));
  END LOOP;

  RETURN array_to_json(arResult);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClientTariffJsonb --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetClientTariffJsonb (
  pObject	numeric,
  pDate		timestamp default oper_date()
) RETURNS	jsonb
AS $$
BEGIN
  RETURN GetClientTariffJson(pObject, pDate);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
