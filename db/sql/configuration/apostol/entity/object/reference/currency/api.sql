--------------------------------------------------------------------------------
-- CURRENCY --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.currency ----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief API view for currency records.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.currency
AS
  SELECT * FROM ObjectCurrency;

GRANT SELECT ON api.currency TO administrator;

--------------------------------------------------------------------------------
-- api.add_currency ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new currency.
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @param {integer} pDigital - Numeric (digital) code
 * @param {integer} pDecimal - Number of decimal places
 * @return {uuid} - New currency identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_currency (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription  text default null,
  pDigital      integer default null,
  pDecimal      integer default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateCurrency(pParent, coalesce(pType, GetType('iso.currency')), pCode, pName, pDescription, pDigital, pDecimal);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_currency ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing currency.
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @param {integer} pDigital - Numeric (digital) code
 * @param {integer} pDecimal - Number of decimal places
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_currency (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null,
  pDigital      integer default null,
  pDecimal      integer default null
) RETURNS       void
AS $$
DECLARE
  uCurrency     uuid;
BEGIN
  SELECT t.id INTO uCurrency FROM db.currency t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('currency', 'id', pId);
  END IF;

  PERFORM EditCurrency(uCurrency, pParent, pType, pCode, pName, pDescription, pDigital, pDecimal);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_currency ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a currency (upsert).
 * @return {SETOF api.currency} - Updated currency record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_currency (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null,
  pDigital      integer default null,
  pDecimal      integer default null
) RETURNS       SETOF api.currency
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_currency(pParent, pType, pCode, pName, pDescription, pDigital, pDecimal);
  ELSE
    PERFORM api.update_currency(pId, pParent, pType, pCode, pName, pDescription, pDigital, pDecimal);
  END IF;

  RETURN QUERY SELECT * FROM api.currency WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_currency ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a currency by identifier.
 * @param {uuid} pId - Identifier
 * @return {api.currency} - Currency record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_currency (
  pId        uuid
) RETURNS    SETOF api.currency
AS $$
  SELECT * FROM api.currency WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_currency -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a list of currencys.
 * @param {jsonb} pSearch - Search conditions: '[{"condition": "AND|OR", "field": "<field>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<value>"}, ...]'
 * @param {jsonb} pFilter - Filter: '{"<field>": "<value>"}'
 * @param {integer} pLimit - Row limit
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort by fields array
 * @return {SETOF api.currency} - Currency records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_currency (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.currency
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'currency', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_currency_id ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns currency identifier by code.
 * @param {text} pCode - Currency code
 * @return {uuid} - Currency identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_currency_id (
  pCode     text
) RETURNS   uuid
AS $$
BEGIN
  RETURN GetCurrency(pCode);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
