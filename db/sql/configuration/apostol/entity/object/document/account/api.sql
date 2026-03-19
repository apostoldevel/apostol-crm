--------------------------------------------------------------------------------
-- ACCOUNT ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.account -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.account
AS
  SELECT * FROM ObjectAccount;

GRANT SELECT ON api.account TO administrator;

--------------------------------------------------------------------------------
-- api.add_account -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Adds a new account
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
CREATE OR REPLACE FUNCTION api.add_account (
  pParent       uuid,
  pType         uuid,
  pCurrency     uuid,
  pClient       uuid,
  pCategory     uuid default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateAccount(pParent, coalesce(pType, GetType('passive.account')), pCurrency, pClient, pCategory, pCode, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_account ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing account
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
CREATE OR REPLACE FUNCTION api.update_account (
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
BEGIN
  PERFORM FROM db.account WHERE id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('account', 'id', pId);
  END IF;

  PERFORM EditAccount(pId, pParent, pType, pCurrency, pClient, pCategory, pCode, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_account -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates an account (upsert)
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCategory - Category identifier
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {SETOF api.account}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_account (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCurrency     uuid default null,
  pClient       uuid default null,
  pCategory     uuid default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       SETOF api.account
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_account(pParent, pType, pCurrency, pClient, pCategory, pCode, pLabel, pDescription);
  ELSE
    PERFORM api.update_account(pId, pParent, pType, pCurrency, pClient, pCategory, pCode, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.account WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_account -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns an account by identifier
 * @param {uuid} pId - Identifier
 * @return {api.account}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_account (
  pId       uuid
) RETURNS   SETOF api.account
AS $$
  SELECT * FROM api.account WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_account -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of account records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_account (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'account', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_account ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a filtered/sorted list of account records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.account}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_account (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.account
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'account', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_account_id ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the account identifier by code
 * @param {text} pCode - Code
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_account_id (
  pCode     text
) RETURNS   uuid
AS $$
BEGIN
  RETURN GetAccount(pCode);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_account_balance -----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the account balance at a given date
 * @param {uuid} pId - Record identifier
 * @param {timestamptz} pDateFrom - Start date
 * @return {numeric}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_account_balance (
  pId       uuid,
  pDateFrom timestamptz DEFAULT oper_date()
) RETURNS   numeric
AS $$
BEGIN
  IF NOT CheckObjectAccess(pId, B'100') THEN
    PERFORM AccessDenied();
  END IF;

  RETURN GetBalance(pId, pDateFrom);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
