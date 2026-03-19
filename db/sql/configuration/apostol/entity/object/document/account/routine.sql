--------------------------------------------------------------------------------
-- CreateAccount ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new account
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCategory - Category identifier
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateAccount (
  pParent       uuid,
  pType         uuid,
  pCurrency     uuid,
  pClient       uuid,
  pCategory     uuid,
  pCode         text,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
DECLARE
  uAccount      uuid;
  uDocument     uuid;

  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetClassCode(uClass) <> 'account' THEN
    PERFORM IncorrectClassType();
  END IF;

  pCurrency := coalesce(pCurrency, DefaultCurrency());

  PERFORM FROM db.currency WHERE id = pCurrency;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('currency', 'id', pCurrency);
  END IF;

  PERFORM FROM db.account WHERE currency = pCurrency AND code = pCode;
  IF FOUND THEN
    PERFORM AccountCodeExists(pCode);
  END IF;

  PERFORM FROM db.client WHERE id = pClient;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('client', 'id', pClient);
  END IF;

  IF pCategory IS NOT NULL THEN
    PERFORM FROM db.category WHERE id = pCategory;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('category', 'id', pCategory);
    END IF;
  END IF;

  uDocument := CreateDocument(pParent, pType, coalesce(pLabel, pCode), pDescription);

  INSERT INTO db.account (id, document, currency, client, category, code)
  VALUES (uDocument, uDocument, pCurrency, pClient, pCategory, pCode)
  RETURNING id INTO uAccount;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uAccount, uMethod);

  RETURN uAccount;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditAccount -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Edits an existing account
 * @param {uuid} pId - Identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCategory - Category identifier
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditAccount (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCurrency     uuid default null,
  pClient       uuid default null,
  pCategory     uuid default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;

  -- current
  cCompany      uuid;
  cCurrency     uuid;
  cClient       uuid;
  cCode         text;
BEGIN
  SELECT company, currency, client, code INTO cCompany, cCurrency, cClient, cCode FROM db.account WHERE id = pId;

  pCurrency := coalesce(pCurrency, cCurrency);
  pClient := coalesce(pClient, cClient);
  pCode := coalesce(pCode, cCode);

  PERFORM FROM db.currency WHERE id = pCurrency;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('currency', 'id', pCurrency);
  END IF;

  PERFORM FROM db.client WHERE id = pClient;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('client', 'id', pClient);
  END IF;

  IF pCategory IS NOT NULL THEN
    PERFORM FROM db.category WHERE id = pCategory;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('category', 'id', pCategory);
    END IF;
  END IF;

  IF pCode <> cCode THEN
    PERFORM FROM db.account WHERE currency = pCurrency AND code = pCode;
    IF FOUND THEN
      PERFORM AccountCodeExists(pCode);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.account
     SET currency = pCurrency,
         client = pClient,
         category = coalesce(pCategory, category),
         code = pCode
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));

  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetAccount ------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the account by code
 * @param {text} pCode - Code
 * @param {uuid} pCurrency - Currency identifier
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetAccount (
  pCode     text,
  pCurrency uuid DEFAULT GetCurrency(coalesce(RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Currency'), 'RUB'))
) RETURNS   uuid
AS $$
  SELECT id FROM db.account WHERE currency = pCurrency AND code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetAccountCode --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the account code by identifier
 * @param {uuid} pAccount - Account identifier
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetAccountCode (
  pAccount  uuid
) RETURNS   text
AS $$
  SELECT code FROM db.account WHERE id = pAccount;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GenAccountCode --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Generates an account code
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {text} pPrefix - Account code prefix
 * @param {boolean} pNew - Generate unique code if true
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GenAccountCode (
  pClient   uuid,
  pCurrency uuid DEFAULT null,
  pPrefix   text DEFAULT null,
  pNew      boolean DEFAULT null
) RETURNS   text
AS $$
DECLARE
  nCode     int;
  nCurrency int;

  vCode     text;
  vAccount  text;
BEGIN
  pCurrency := coalesce(pCurrency, DefaultCurrency());

  IF GetObjectTypeCode(pClient) = 'company.client' THEN
    vCode := GetClientCode(pClient);
  ELSE
    vCode := SubStr(encode(digest(pClient::text, 'sha1'), 'hex'), 29, 12);
  END IF;

  SELECT digital INTO nCurrency FROM db.currency WHERE id = pCurrency;

  nCode := 0;
  LOOP
	nCode := nCode + 1;
	vAccount := format('%s.%s.%s.%s', pPrefix, LPAD(IntToStr(nCurrency), 3, '0'), vCode, LPAD(IntToStr(nCode), 4, '0'));

	EXIT WHEN NOT coalesce(pNew, false);
	EXIT WHEN GetAccount(vAccount) IS NULL;
  END LOOP;

  RETURN vAccount;
END
$$ LANGUAGE plpgsql STABLE
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- GetClientAccount ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the client account identifier by generated code
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {text} pPrefix - Account code prefix
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetClientAccount (
  pClient   uuid,
  pCurrency uuid DEFAULT null,
  pPrefix   text DEFAULT null
) RETURNS   uuid
AS $$
BEGIN
  RETURN GetAccount(GenAccountCode(pClient, pCurrency, pPrefix));
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetAccountClient ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the client identifier for the account
 * @param {uuid} pId - Record identifier
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetAccountClient (
  pId       uuid
) RETURNS   uuid
AS $$
  SELECT client FROM db.account WHERE id = pId;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetAccountJson --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns account data as JSON for the given client
 * @param {uuid} pClient - Client identifier
 * @return {json}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetAccountJson (
  pClient       uuid
) RETURNS       json
AS $$
DECLARE
  arResult      json[];
  rec           record;
BEGIN
  FOR rec IN
    SELECT * FROM Account WHERE client = pClient
  LOOP
    arResult := array_append(arResult, row_to_json(rec));
  END LOOP;

  RETURN array_to_json(arResult);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetBalanceJson --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns account data as JSONB for the given client
 * @param {uuid} pClient - Client identifier
 * @return {jsonb}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetBalanceJsonb (
  pClient       uuid
) RETURNS       jsonb
AS $$
DECLARE
  arResult      jsonb;
  rec           record;
BEGIN
  arResult := jsonb_build_object();

  FOR rec IN
    SELECT t.code, coalesce(b.amount, 0) AS amount
      FROM db.account t INNER JOIN db.object           o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
                        INNER JOIN db.currency         c ON c.id = t.currency
                        INNER JOIN db.reference       cr ON cr.id = c.reference
                         LEFT JOIN db.balance          b ON b.account = t.id AND b.type = 1 AND validFromDate <= Now() AND validToDate > Now()
     WHERE t.client = pClient
  LOOP
    arResult := arResult || jsonb_build_object(rec.code, rec.amount);
  END LOOP;

  RETURN arResult;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
