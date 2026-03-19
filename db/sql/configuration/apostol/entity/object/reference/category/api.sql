--------------------------------------------------------------------------------
-- CATEGORY --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.category ----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief API view for category records.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.category
AS
  SELECT * FROM ObjectCategory;

GRANT SELECT ON api.category TO administrator;

--------------------------------------------------------------------------------
-- api.add_category ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new category.
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @return {uuid} - New category identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_category (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateCategory(pParent, coalesce(pType, GetType('service.category')), pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_category ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing category.
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_category (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uCategory     uuid;
BEGIN
  SELECT t.id INTO uCategory FROM db.category t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('category', 'id', pId);
  END IF;

  PERFORM EditCategory(uCategory, pParent, pType, pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_category ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a category (upsert).
 * @return {SETOF api.category} - Updated category record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_category (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null
) RETURNS       SETOF api.category
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_category(pParent, pType, pCode, pName, pDescription);
  ELSE
    PERFORM api.update_category(pId, pParent, pType, pCode, pName, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.category WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_category ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a category by identifier.
 * @param {uuid} pId - Identifier
 * @return {api.category} - Category record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_category (
  pId        uuid
) RETURNS    SETOF api.category
AS $$
  SELECT * FROM api.category WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_category -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a list of categorys.
 * @param {jsonb} pSearch - Search conditions: '[{"condition": "AND|OR", "field": "<field>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<value>"}, ...]'
 * @param {jsonb} pFilter - Filter: '{"<field>": "<value>"}'
 * @param {integer} pLimit - Row limit
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort by fields array
 * @return {SETOF api.category} - Category records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_category (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.category
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'category', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_category_id ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns category identifier by code.
 * @param {text} pCode - Category code
 * @return {uuid} - Category identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_category_id (
  pCode     text
) RETURNS   uuid
AS $$
BEGIN
  RETURN GetCategory(pCode);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
