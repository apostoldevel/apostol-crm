--------------------------------------------------------------------------------
-- CUSTOMER --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.customer ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.customer
AS
  SELECT * FROM ObjectClient WHERE class = GetClass('customer');

GRANT SELECT ON api.customer TO administrator;

--------------------------------------------------------------------------------
-- api.add_customer ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Adds a new customer
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
 * @param {text} pPhoto - Photo URL
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Additional metadata
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_customer (
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
  pPhoto        text default null,
  pDescription  text default null,
  pMetadata     jsonb default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateClient(pParent, coalesce(pType, GetType('organization.customer')), pCompany, pUserId, pCode, pName, pPhone, pEmail, pBirthday, pBirthPlace, pSeries, pNumber, pIssued, pIssuedDate, pIssuedCode, pInn, pPin, pKpp, pOgrn, pBic, pAccount, pAddress, decode(pPhoto, 'base64'), pDescription, pMetadata);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_customer ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing customer
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
 * @param {text} pPhoto - Photo URL
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Additional metadata
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_customer (
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

  PERFORM EditClient(pId, pParent, pType, pCompany, pUserId, pCode, pName, pPhone, pEmail, pBirthday, pBirthPlace, pSeries, pNumber, pIssued, pIssuedDate, pIssuedCode, pInn, pPin, pKpp, pOgrn, pBic, pAccount, pAddress, decode(pPhoto, 'base64'), pDescription, pMetadata);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_customer ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a customer (upsert)
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCompany - Company
 * @param {uuid} pUserId - User identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pPhone - Phone number
 * @param {text} pEmail - Email address
 * @param {date} pBirthday - Birthday
 * @param {text} pBirthPlace - BirthPlace
 * @param {text} pSeries - Series
 * @param {text} pNumber - Number
 * @param {text} pIssued - Issued
 * @param {date} pIssuedDate - IssuedDate
 * @param {text} pIssuedCode - IssuedCode
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
 * @return {SETOF api.customer}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_customer (
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
  pPhoto        text default null,
  pDescription  text default null,
  pMetadata     jsonb default null
) RETURNS       SETOF api.customer
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_customer(pParent, pType, pCompany, pUserId, pCode, pName, pPhone, pEmail, pBirthday, pBirthPlace, pSeries, pNumber, pIssued, pIssuedDate, pIssuedCode, pInn, pPin, pKpp, pOgrn, pBic, pAccount, pAddress, pPhoto, pDescription, pMetadata);
  ELSE
    PERFORM api.update_customer(pId, pParent, pType, pCompany, pUserId, pCode, pName, pPhone, pEmail, pBirthday, pBirthPlace, pSeries, pNumber, pIssued, pIssuedDate, pIssuedCode, pInn, pPin, pKpp, pOgrn, pBic, pAccount, pAddress, pPhoto, pDescription, pMetadata);
  END IF;

  RETURN QUERY SELECT * FROM api.customer WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_customer ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a customer by identifier
 * @param {uuid} pId - Identifier
 * @return {api.customer} - Card record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_customer (
  pId        uuid
) RETURNS    SETOF api.customer
AS $$
  SELECT * FROM api.customer WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_customer ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of customer records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_customer (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('id', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'customer', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_customer -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a filtered/sorted list of customer records
 * @param {jsonb} pSearch - Search conditions array
 * @param {jsonb} pFilter - Filter object
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.customer} - List of cards
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_customer (
  pSearch	jsonb DEFAULT null,
  pFilter	jsonb DEFAULT null,
  pLimit	integer DEFAULT null,
  pOffSet	integer DEFAULT null,
  pOrderBy	jsonb DEFAULT null
) RETURNS	SETOF api.customer
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('id', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'customer', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
