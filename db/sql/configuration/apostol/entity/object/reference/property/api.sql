--------------------------------------------------------------------------------
-- PROPERTY --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.property ----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief API view for property records.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.property
AS
  SELECT * FROM ObjectProperty;

GRANT SELECT ON api.property TO administrator;

--------------------------------------------------------------------------------
-- api.add_property ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new property.
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @return {uuid} - New property identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_property (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateProperty(pParent, coalesce(pType, GetType('string.property')), pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_property ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing property.
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_property (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uProperty     uuid;
BEGIN
  SELECT t.id INTO uProperty FROM db.property t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('свойство', 'id', pId);
  END IF;

  PERFORM EditProperty(uProperty, pParent, pType, pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_property ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a property (upsert).
 * @return {SETOF api.property} - Updated property record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_property (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null
) RETURNS       SETOF api.property
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_property(pParent, pType, pCode, pName, pDescription);
  ELSE
    PERFORM api.update_property(pId, pParent, pType, pCode, pName, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.property WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_property ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a property by identifier.
 * @param {uuid} pId - Identifier
 * @return {api.property} - Property record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_property (
  pId        uuid
) RETURNS    SETOF api.property
AS $$
  SELECT * FROM api.property WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_property -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a list of propertys.
 * @param {jsonb} pSearch - Search conditions: '[{"condition": "AND|OR", "field": "<field>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<value>"}, ...]'
 * @param {jsonb} pFilter - Filter: '{"<field>": "<value>"}'
 * @param {integer} pLimit - Row limit
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort by fields array
 * @return {SETOF api.property} - Property records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_property (
  pSearch    jsonb default null,
  pFilter    jsonb default null,
  pLimit    integer default null,
  pOffSet    integer default null,
  pOrderBy    jsonb default null
) RETURNS    SETOF api.property
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'property', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
