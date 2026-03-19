--------------------------------------------------------------------------------
-- CLIENT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.client ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.client
AS
  SELECT * FROM ObjectClient WHERE class = GetClass('client');

GRANT SELECT ON api.client TO administrator;

--------------------------------------------------------------------------------
-- api.add_client --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Adds a new client
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCompany - Company identifier
 * @param {uuid} pUserId - User account for the client
 * @param {text} pCode - Client code
 * @param {text} pName - Full company name / person full name
 * @param {text} pPhone - Phone number
 * @param {text} pEmail - Email address
 * @param {text} pInn - Tax identification number (INN)
 * @param {text} pPin - Individual insurance account number (SNILS)
 * @param {text} pKpp - Tax registration reason code (KPP)
 * @param {text} pOgrn - Primary state registration number (OGRN/IP)
 * @param {text} pBic - Bank identification code (BIK)
 * @param {text} pAccount - Settlement account number
 * @param {text} pAddress - Address identifier
 * @param {text} pPhoto - Photo URL
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Additional metadata
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_client (
  pParent       uuid,
  pType         uuid,
  pCompany      uuid,
  pUserId       uuid,
  pCode         text,
  pName         text,
  pPhone        text default null,
  pEmail        text default null,
  pInn          text default null,
  pPin          text default null,
  pKpp          text default null,
  pOgrn         text default null,
  pBic          text default null,
  pAccount      text default null,
  pAddress      text default null,
  pPhoto        text default null,
  pDescription  text default null,
  pMetadata     jsonb default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateClient(pParent, coalesce(pType, GetType('company.client')), pCompany, pUserId, pCode, pName, pPhone, pEmail, null, null, null, null, null, null, null, pInn, pPin, pKpp, pOgrn, pBic, pAccount, pAddress, decode(pPhoto, 'base64'), pDescription, pMetadata);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_client -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing client
 * @param {uuid} pId - Client identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCompany - Company identifier
 * @param {uuid} pUserId - User account for the client
 * @param {text} pCode - Client code
 * @param {text} pName - Full company name / person full name
 * @param {text} pPhone - Phone number
 * @param {text} pEmail - Email address
 * @param {text} pInn - Tax identification number (INN)
 * @param {text} pPin - Individual insurance account number (SNILS)
 * @param {text} pKpp - Tax registration reason code (KPP)
 * @param {text} pOgrn - Primary state registration number (OGRN/IP)
 * @param {text} pBic - Bank identification code (BIK)
 * @param {text} pAccount - Settlement account number
 * @param {text} pAddress - Address identifier
 * @param {text} pPhoto - Photo URL
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Additional metadata
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_client (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCompany      uuid default null,
  pUserId       uuid default null,
  pCode         text default null,
  pName         text default null,
  pPhone        text default null,
  pEmail        text default null,
  pInn          text default null,
  pPin          text default null,
  pKpp          text default null,
  pOgrn         text default null,
  pBic          text default null,
  pAccount      text default null,
  pAddress      text default null,
  pPhoto        text default null,
  pDescription  text default null,
  pMetadata     jsonb default null
) RETURNS       void
AS $$
BEGIN
  PERFORM FROM db.client c WHERE c.id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('client', 'id', pId);
  END IF;

  PERFORM EditClient(pId, pParent, pType, pCompany, pUserId, pCode, pName, pPhone, pEmail, null, null, null, null, null, null, null, pInn, pPin, pKpp, pOgrn, pBic, pAccount, pAddress, decode(pPhoto, 'base64'), pDescription, pMetadata);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_client --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a client (upsert)
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCompany - Company
 * @param {uuid} pUserId - User identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pPhone - Phone number
 * @param {text} pEmail - Email address
 * @param {text} pInn - Inn
 * @param {text} pPin - Pin
 * @param {text} pKpp - Kpp
 * @param {text} pOgrn - Ogrn
 * @param {text} pBic - Bic
 * @param {text} pAccount - Account identifier
 * @param {text} pAddress - Recipient address
 * @param {text} pPhoto - Photo
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Metadata
 * @return {SETOF api.client}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_client (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCompany      uuid default null,
  pUserId       uuid default null,
  pCode         text default null,
  pName         text default null,
  pPhone        text default null,
  pEmail        text default null,
  pInn          text default null,
  pPin          text default null,
  pKpp          text default null,
  pOgrn         text default null,
  pBic          text default null,
  pAccount      text default null,
  pAddress      text default null,
  pPhoto        text default null,
  pDescription  text default null,
  pMetadata     jsonb default null
) RETURNS       SETOF api.client
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_client(pParent, pType, pCompany, pUserId, pCode, pName, pPhone, pEmail, pInn, pPin, pKpp, pOgrn, pBic, pAccount, pAddress, pPhoto, pDescription, pMetadata);
  ELSE
    PERFORM api.update_client(pId, pParent, pType, pCompany, pUserId, pCode, pName, pPhone, pEmail, pInn, pPin, pKpp, pOgrn, pBic, pAccount, pAddress, pPhoto, pDescription, pMetadata);
  END IF;

  RETURN QUERY SELECT * FROM api.client WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_client --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a client by identifier
 * @param {uuid} pId - Identifier
 * @return {api.client} - Card record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_client (
  pId        uuid
) RETURNS    SETOF api.client
AS $$
  SELECT * FROM api.client WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_client ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of client records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_client (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('id', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'client', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_client -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a filtered/sorted list of client records
 * @param {jsonb} pSearch - Search conditions array
 * @param {jsonb} pFilter - Filter object
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.client} - List of cards
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_client (
  pSearch	jsonb DEFAULT null,
  pFilter	jsonb DEFAULT null,
  pLimit	integer DEFAULT null,
  pOffSet	integer DEFAULT null,
  pOrderBy	jsonb DEFAULT null
) RETURNS	SETOF api.client
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('id', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'client', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.close_client ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief api.close_client
 * @param {uuid} pId - Record identifier
 * @return {bool}
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.close_client (
  pId           uuid
) RETURNS       bool
AS $$
DECLARE
  uUserId       uuid;
  vSession      text;
  vOAuthClient  text;
  vOAuthSecret  text;
BEGIN
  SELECT userId INTO uUserId FROM db.client c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('клиент', 'id', pId);
  END IF;

  PERFORM SessionOut(uUserId, true, 'Close client.');

  SELECT a.code, a.secret INTO vOAuthClient, vOAuthSecret FROM oauth2.audience a WHERE a.code = current_database();

  IF FOUND THEN
    vSession := SignIn(CreateSystemOAuth2(), vOAuthClient, vOAuthSecret);

    PERFORM SubstituteUser(GetUser('admin'), vOAuthSecret);

    IF IsActive(pId) THEN
      SELECT DoDisable(pId);
    END IF;

    IF IsDisabled(pId) THEN
      SELECT DoDelete(pId);
    END IF;

    IF IsDeleted(pId) THEN
      SELECT DoDrop(pId);
    END IF;

    PERFORM SessionOut(vSession, false);
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_client_balance ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the client balance at a given date
 * @param {uuid} pId - Record identifier
 * @return {jsonb}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_client_balance (
  pId           uuid
) RETURNS       jsonb
AS $$
DECLARE
  r             record;
  uUserId       uuid;
  balance       jsonb;
BEGIN
  SELECT userid INTO uUserId FROM db.client WHERE id = pId;
  IF NOT FOUND THEN
    PERFORM NotFound();
  END IF;

  IF uUserId != current_userid() THEN
    IF NOT IsUserRole(GetGroup('administrator')) THEN
      PERFORM AccessDenied();
    END IF;
  END IF;

  balance := jsonb_build_array();

  FOR r IN SELECT a.id, a.code, a.balance, a.currencycode FROM account a WHERE a.client = pId
  LOOP
    balance := balance || jsonb_build_object('account', r.id, 'code', r.code, 'balance', r.balance, 'currency', r.currencycode);
  END LOOP;

  RETURN balance;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
