--------------------------------------------------------------------------------
-- COUNTRY ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.country -----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief API view for country records.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.country
AS
  SELECT * FROM ObjectCountry;

GRANT SELECT ON api.country TO administrator;

--------------------------------------------------------------------------------
-- api.add_country -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new country.
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @param {text} pAlpha2 - ISO alpha-2 code
 * @param {text} pAlpha3 - ISO alpha-3 code
 * @param {integer} pDigital - Numeric (digital) code
 * @param {text} pFlag - Country flag emoji/icon
 * @return {uuid} - New country identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_country (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription  text default null,
  pAlpha2       text default null,
  pAlpha3       text default null,
  pDigital      integer default null,
  pFlag         text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateCountry(pParent, coalesce(pType, GetType('iso.country')), pCode, pName, pDescription, pAlpha2, pAlpha3, pDigital, pFlag);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_country ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing country.
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @param {text} pAlpha2 - ISO alpha-2 code
 * @param {text} pAlpha3 - ISO alpha-3 code
 * @param {integer} pDigital - Numeric (digital) code
 * @param {text} pFlag - Country flag emoji/icon
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_country (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null,
  pAlpha2       text default null,
  pAlpha3       text default null,
  pDigital      integer default null,
  pFlag         text default null
) RETURNS       void
AS $$
DECLARE
  uCountry      uuid;
BEGIN
  SELECT t.id INTO uCountry FROM db.country t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('country', 'id', pId);
  END IF;

  PERFORM EditCountry(uCountry, pParent, pType, pCode, pName, pDescription, pAlpha2, pAlpha3, pDigital, pFlag);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_country -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a country (upsert).
 * @return {SETOF api.country} - Updated country record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_country (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null,
  pAlpha2       text default null,
  pAlpha3       text default null,
  pDigital      integer default null,
  pFlag         text default null
) RETURNS       SETOF api.country
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_country(pParent, pType, pCode, pName, pDescription, pAlpha2, pAlpha3, pDigital, pFlag);
  ELSE
    PERFORM api.update_country(pId, pParent, pType, pCode, pName, pDescription, pAlpha2, pAlpha3, pDigital, pFlag);
  END IF;

  RETURN QUERY SELECT * FROM api.country WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_country -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a country by identifier.
 * @param {uuid} pId - Identifier
 * @return {api.country} - Country record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_country (
  pId        uuid
) RETURNS    SETOF api.country
AS $$
  SELECT * FROM api.country WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_country ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a list of countrys.
 * @param {jsonb} pSearch - Search conditions: '[{"condition": "AND|OR", "field": "<field>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<value>"}, ...]'
 * @param {jsonb} pFilter - Filter: '{"<field>": "<value>"}'
 * @param {integer} pLimit - Row limit
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort by fields array
 * @return {SETOF api.country} - Country records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_country (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.country
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'country', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_country_id ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns country identifier by code.
 * @param {text} pCode - Currency code
 * @return {uuid} - Country identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_country_id (
  pCode     text
) RETURNS   uuid
AS $$
BEGIN
  RETURN GetCountry(pCode);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
