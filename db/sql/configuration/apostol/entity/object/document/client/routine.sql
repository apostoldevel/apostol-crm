--------------------------------------------------------------------------------
-- CreateClient ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new client
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCompany - Company identifier
 * @param {uuid} pUserId - User account for the client
 * @param {text} pCode - Client code
 * @param {text} pName - Full company name / person full name
 * @param {text} pPhone - Phone number
 * @param {text} pEmail - Email address
 * @param {date} pBirthday - Opening date / date of birth
 * @param {text} pBirthPlace - Place of birth
 * @param {text} pSeries - Passport series
 * @param {text} pNumber - Passport number
 * @param {text} pIssued - Passport issued by
 * @param {date} pIssuedDate - Passport issue date
 * @param {text} pIssuedCode - Passport department code
 * @param {text} pInn - Tax identification number (INN)
 * @param {text} pPin - Individual insurance account number (SNILS)
 * @param {text} pKpp - Tax registration reason code (KPP)
 * @param {text} pOgrn - Primary state registration number (OGRN/IP)
 * @param {text} pBic - Bank identification code (BIK)
 * @param {text} pAccount - Settlement account number
 * @param {text} pAddress - Address identifier
 * @param {bytea} pPhoto - Photo URL
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Additional metadata
 * @return {uuid} - Client identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateClient (
  pParent       uuid,
  pType         uuid,
  pCompany      uuid,
  pUserId       uuid,
  pCode         text,
  pName         text,
  pPhone        text default null,
  pEmail        text default null,
  pBirthday     date default null,
  pBirthPlace   text default null,
  pSeries       text default null,
  pNumber       text default null,
  pIssued       text default null,
  pIssuedDate   date default null,
  pIssuedCode   text default null,
  pInn          text default null,
  pPin          text default null,
  pKpp          text default null,
  pOgrn         text default null,
  pBic          text default null,
  pAccount      text default null,
  pAddress      text default null,
  pPhoto        bytea default null,
  pDescription  text default null,
  pMetadata     jsonb default null
) RETURNS       uuid
AS $$
DECLARE
  l             record;

  uClient       uuid;
  uCountry      uuid;
  uAddress      uuid;
  uDocument     uuid;

  jName         jsonb;
  jAddress      jsonb;

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

  IF pBirthday IS NOT NULL AND EXTRACT(YEAR FROM pBirthday) < 1920 THEN
    PERFORM IncorrectDateValue(pBirthday);
  END IF;

  IF pIssuedDate IS NOT NULL AND EXTRACT(YEAR FROM pIssuedDate) < 1920 THEN
    PERFORM IncorrectDateValue(pIssuedDate);
  END IF;

  uCountry := GetCountry('RU');

  jName := BuildClientName(pType, pName);

  SELECT * INTO cn FROM jsonb_to_record(jName) AS x(name text, short text, first text, last text, middle text);

  IF NULLIF(trim(cn.short), '') IS NULL THEN
    cn.short := coalesce(NULLIF(trim(cn.name), ''), pCode);
  END IF;

  pCompany := coalesce(pCompany, current_company());
  pPhone := TrimPhone(NULLIF(trim(pPhone), ''));

  PERFORM FROM db.company WHERE id = pCompany;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('company', 'id', pCompany);
  END IF;

  IF pUserId = null_uuid() THEN
    pUserId := CreateUser(pCode, pCode, cn.short, pPhone, pEmail, NULLIF(trim(cn.name), ''));
  END IF;

  uDocument := CreateDocument(pParent, pType, null, pDescription);

  IF pAddress IS NOT NULL THEN
    jAddress := AddressStringToJsonb(pAddress);
    uAddress := CreateAddress(uDocument, GetType('post.address'), uCountry, encode(digest(uClient::text, 'md5'), 'hex'), jAddress->>'code', jAddress->>'index', jAddress->>'region', jAddress->>'district', jAddress->>'city', jAddress->>'settlement', jAddress->>'street', jAddress->>'house', jAddress->>'building', jAddress->>'structure', jAddress->>'apartment');

    IF uAddress IS NOT NULL THEN
      pAddress := GetAddressString(uAddress);
    END IF;
  END IF;

  INSERT INTO db.client (id, document, company, userid, code, phone, email, birthday, birthplace, series, number, issued, issued_date, issued_code, inn, pin, kpp, ogrn, bic, account, address, photo, metadata)
  VALUES (uDocument, uDocument, pCompany, pUserId, pCode, pPhone, pEmail, pBirthday, pBirthPlace, pSeries, pNumber, pIssued, pIssuedDate, pIssuedCode, pInn, pPin, pKpp, pOgrn, pBic, pAccount, pAddress, pPhoto, pMetadata)
  RETURNING id INTO uClient;

  FOR l IN SELECT id FROM db.locale
  LOOP
    PERFORM NewClientName(uClient, cn.name, cn.short, cn.first, cn.last, cn.middle, l.id);
  END LOOP;

  IF pNumber IS NOT NULL AND pSeries IS NOT NULL THEN
    PERFORM CreateIdentity(uClient, GetType('passport.identity'), uCountry, uClient, pSeries, pNumber, pIssuedCode, pIssued, pIssuedDate, pPhoto);
  END IF;

  IF pInn IS NOT NULL THEN
    PERFORM CreateIdentity(uClient, GetType('inn.identity'), uCountry, uClient, null, pInn);
  END IF;

  IF pPin IS NOT NULL THEN
    PERFORM CreateIdentity(uClient, GetType('pin.identity'), uCountry, uClient, null, pPin);
  END IF;

  IF pKpp IS NOT NULL THEN
    PERFORM CreateIdentity(uClient, GetType('kpp.identity'), uCountry, uClient, null, pKpp);
  END IF;

  IF pOgrn IS NOT NULL THEN
    IF GetTypeCode(pType) = 'individual.client' THEN
      PERFORM CreateIdentity(uClient, GetType('ogrnip.identity'), uCountry, uClient, null, pOgrn);
    ELSE
      PERFORM CreateIdentity(uClient, GetType('ogrn.identity'), uCountry, uClient, null, pOgrn);
    END IF;
  END IF;

  IF pBic IS NOT NULL THEN
    PERFORM SetIdentity(null, uClient, GetType('bic.identity'), uCountry, uClient, null, pBic);
  END IF;

  PERFORM SetObjectLink(uClient, uAddress, GetObjectTypeCode(uAddress), Now());

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uClient, uMethod);

  RETURN uClient;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- EditClient ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Edits card parameters
 * @param {uuid} pId - Client identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCompany - Company identifier
 * @param {uuid} pUserId - User account for the client
 * @param {text} pCode - Client code
 * @param {text} pName - Full company name / person full name
 * @param {text} pPhone - Phone number
 * @param {text} pEmail - Email address
 * @param {date} pBirthday - Opening date / date of birth
 * @param {text} pBirthPlace - Place of birth
 * @param {text} pSeries - Passport series
 * @param {text} pNumber - Passport number
 * @param {text} pIssued - Passport issued by
 * @param {date} pIssuedDate - Passport issue date
 * @param {text} pIssuedCode - Passport department code
 * @param {text} pInn - Tax identification number (INN)
 * @param {text} pPin - Individual insurance account number (SNILS)
 * @param {text} pKpp - Tax registration reason code (KPP)
 * @param {text} pOgrn - Primary state registration number (OGRN/IP)
 * @param {text} pBic - Bank identification code (BIK)
 * @param {text} pAccount - Settlement account number
 * @param {text} pAddress - Address identifier
 * @param {bytea} pPhoto - Photo URL
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Additional metadata
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditClient (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCompany      uuid default null,
  pUserId       uuid default null,
  pCode         text default null,
  pName         text default null,
  pPhone        text default null,
  pEmail        text default null,
  pBirthday     date default null,
  pBirthPlace   text default null,
  pSeries       text default null,
  pNumber       text default null,
  pIssued       text default null,
  pIssuedDate   date default null,
  pIssuedCode   text default null,
  pInn          text default null,
  pPin          text default null,
  pKpp          text default null,
  pOgrn         text default null,
  pBic          text default null,
  pAccount      text default null,
  pAddress      text default null,
  pPhoto        bytea default null,
  pDescription  text default null,
  pMetadata     jsonb default null
) RETURNS       void
AS $$
DECLARE
  uMethod       uuid;
  uCountry      uuid;
  uAddress      uuid;

  r             record;

  jName         jsonb;
  jAddress      jsonb;

  old           Client%rowtype;
  new           Client%rowtype;

  -- current
  cCompany      uuid;
  cUserId       uuid;
  cCode         text;
  cAddress      text;
BEGIN
  SELECT company, userid, code, address INTO cCompany, cUserId, cCode, cAddress FROM db.client WHERE id = pId;

  pCompany := coalesce(pCompany, cCompany);
  pUserId := coalesce(pUserId, cUserId, null_uuid());
  pCode := coalesce(pCode, cCode);
  pPhone := TrimPhone(NULLIF(trim(pPhone), ''));
  pAddress := CheckNull(coalesce(pAddress, cAddress, ''));
  uCountry := GetCountry('RU');

  IF pCode <> cCode THEN
    PERFORM FROM db.client WHERE code = pCode;
    IF FOUND THEN
      PERFORM ClientCodeExists(pCode);
    END IF;
  END IF;

  PERFORM FROM db.company WHERE id = pCompany;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('company', 'id', pCompany);
  END IF;

  IF pAddress IS NOT NULL AND pAddress IS DISTINCT FROM cAddress THEN
    jAddress := AddressStringToJsonb(pAddress);
    uAddress := GetAddress(encode(digest(pId::text, 'md5'), 'hex'));

    IF uAddress IS NULL THEN
      uAddress := CreateAddress(pId, GetType('post.address'), uCountry, encode(digest(pId::text, 'md5'), 'hex'), jAddress->>'code', jAddress->>'index', jAddress->>'region', jAddress->>'district', jAddress->>'city', jAddress->>'settlement', jAddress->>'street', jAddress->>'house', jAddress->>'building', jAddress->>'structure', jAddress->>'apartment');
    ELSE
      PERFORM EditAddress(uAddress, pId, GetType('post.address'), uCountry, encode(digest(pId::text, 'md5'), 'hex'), jAddress->>'code', jAddress->>'index', jAddress->>'region', jAddress->>'district', jAddress->>'city', jAddress->>'settlement', jAddress->>'street', jAddress->>'house', jAddress->>'building', jAddress->>'structure', jAddress->>'apartment');
    END IF;

    IF uAddress IS NOT NULL THEN
      pAddress := GetAddressString(uAddress);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, null, pDescription, pDescription, current_locale());

  SELECT * INTO old FROM Client WHERE id = pId;

  UPDATE db.client
     SET company = pCompany,
         userid = CheckNull(pUserId),
         code = pCode,
         phone = CheckNull(coalesce(pPhone, phone, '')),
         email = CheckNull(coalesce(pEmail, email, '')),
         birthday = CheckNull(coalesce(pBirthday, birthday, MINDATE())),
         birthplace = CheckNull(coalesce(pBirthPlace, birthplace, '')),
         series = CheckNull(coalesce(pSeries, series, '')),
         number = CheckNull(coalesce(pNumber, number, '')),
         issued = CheckNull(coalesce(pIssued, issued, '')),
         issued_date = CheckNull(coalesce(pIssuedDate, issued_date, MINDATE())),
         issued_code = CheckNull(coalesce(pIssuedCode, issued_code, '')),
         inn = CheckNull(coalesce(pInn, inn, '')),
         pin = CheckNull(coalesce(pPin, pin, '')),
         kpp = CheckNull(coalesce(pKpp, kpp, '')),
         ogrn = CheckNull(coalesce(pOgrn, ogrn, '')),
         bic = CheckNull(coalesce(pBic, bic, '')),
         account = CheckNull(coalesce(pAccount, account, '')),
         address = coalesce(pAddress, address),
         metadata = CheckNull(coalesce(pMetadata, metadata, jsonb_build_object()))
   WHERE id = pId;

  IF pName IS NOT NULL THEN
    jName := BuildClientName(GetObjectType(pId), pName);

    FOR r IN SELECT * FROM jsonb_to_record(jName) AS x(name text, short text, first text, last text, middle text)
    LOOP
      PERFORM EditClientName(pId, r.name, r.short, r.first, r.last, r.middle);
    END LOOP;
  END IF;

  IF pPhoto IS NOT NULL THEN
    UPDATE db.client
       SET photo = pPhoto
     WHERE id = pId;
  END IF;

  IF pSeries IS NOT NULL AND pNumber IS NOT NULL THEN
    PERFORM SetIdentity(null, pId, GetType('passport.identity'), uCountry, pId, pSeries, pNumber, pIssuedCode, pIssued, pIssuedDate, pPhoto);
  END IF;

  IF pInn IS NOT NULL THEN
    PERFORM SetIdentity(null, pId, GetType('inn.identity'), uCountry, pId, null, pInn);
  END IF;

  IF pPin IS NOT NULL THEN
    PERFORM SetIdentity(null, pId, GetType('pin.identity'), uCountry, pId, null, pPin);
  END IF;

  IF pKpp IS NOT NULL THEN
    PERFORM SetIdentity(null, pId, GetType('kpp.identity'), uCountry, pId, null, pKpp);
  END IF;

  IF pOgrn IS NOT NULL THEN
    IF GetObjectTypeCode(pId) = 'individual.client' THEN
      PERFORM SetIdentity(null, pId, GetType('ogrnip.identity'), uCountry, pId, null, pOgrn);
    ELSE
      PERFORM SetIdentity(null, pId, GetType('ogrn.identity'), uCountry, pId, null, pOgrn);
    END IF;
  END IF;

  IF pBic IS NOT NULL THEN
    PERFORM SetIdentity(null, pId, GetType('bic.identity'), uCountry, pId, null, pBic);
  END IF;

  SELECT * INTO new FROM Client WHERE id = pId;

  uMethod := GetMethod(GetObjectClass(pId), GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod, jsonb_build_object('old', row_to_json(old), 'new', row_to_json(new)));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- GetClient -------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the client identifier for the client
 * @param {text} pCode - Code
 * @return {uuid}
 * @since 1.0.0
 */
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

/**
 * @brief Returns the client code by identifier
 * @param {uuid} pClient - Client identifier
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetClientCode (
  pClient   uuid
) RETURNS   text
AS $$
  SELECT code FROM db.client WHERE id = pClient;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClientCompany ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the client by code
 * @param {uuid} pClient - Client identifier
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetClientCompany (
  pClient   uuid
) RETURNS   uuid
AS $$
  SELECT company FROM db.client WHERE id = pClient;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClientUserId -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the client by code
 * @param {uuid} pClient - Client identifier
 * @return {uuid}
 * @since 1.0.0
 */
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

/**
 * @brief Returns the client by code
 * @param {uuid} pUserId - User identifier
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetClientByUserId (
  pUserId   uuid
) RETURNS   uuid
AS $$
  SELECT id FROM db.client WHERE userid = pUserId
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- BuildClientName -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief BuildClientName
 * @param {uuid} pType - Type identifier
 * @param {text} pName - Name
 * @return {jsonb}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION BuildClientName (
  pType     uuid,
  pName     text
) RETURNS   jsonb
AS $$
DECLARE
  vTypeCode text;
  jName     jsonb;
BEGIN
  vTypeCode := GetTypeCode(pType);

  IF vTypeCode IN ('employee.client', 'person.client') THEN
    jName := jsonb_build_object('name'  , pName,
								'short' , concat(split_part(pName, ' ', 1), ' ' || SubStr(split_part(pName, ' ', 2), 1, 1) || '.', ' ' || SubStr(split_part(pName, ' ', 3), 1, 1) || '.'),
								'first' , split_part(pName, ' ', 1),
								'last'  , split_part(pName, ' ', 2),
								'middle', split_part(pName, ' ', 3)
             );
  ELSIF vTypeCode = 'individual.client' THEN
    pName := replace(pName, 'Индивидуальный предприниматель', 'ИП');
    pName := replace(pName, 'индивидуальный предприниматель', 'ИП');

    IF SubStr(pName, 1, 3) != 'ИП ' THEN
	  pName := 'ИП ' || pName;
	END IF;

    jName := jsonb_build_object('name'  , pName,
								'short' , concat(split_part(pName, ' ', 1), split_part(pName, ' ', 2), ' ' || SubStr(split_part(pName, ' ', 3), 1, 1) || '.', ' ' || SubStr(split_part(pName, ' ', 4), 1, 1) || '.'),
								'first' , split_part(pName, ' ', 2),
								'last'  , split_part(pName, ' ', 3),
								'middle', split_part(pName, ' ', 4)
             );
  ELSE
    jName := jsonb_build_object('name'  , pName,
								'short' , pName,
								'first' , null,
								'last'  , null,
								'middle', null
             );
  END IF;

  RETURN jName;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION current_client -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the current client identifier
 * @return {uuid} - Card record
 * @since 1.0.0
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

/**
 * @brief SendPushAll
 * @param {text} pTitle - Notification title
 * @param {text} pBody - Notification body
 * @return {integer}
 * @throws AccessDenied
 * @since 1.0.0
 */
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
