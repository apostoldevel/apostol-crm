--------------------------------------------------------------------------------
-- MEASURE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.measure -----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief API view for measure records.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.measure
AS
  SELECT * FROM ObjectMeasure;

GRANT SELECT ON api.measure TO administrator;

--------------------------------------------------------------------------------
-- api.add_measure -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new measure.
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @return {uuid} - New measure identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_measure (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateMeasure(pParent, coalesce(pType, GetType('time.measure')), pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_measure ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing measure.
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_measure (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uMeasure      uuid;
BEGIN
  SELECT t.id INTO uMeasure FROM db.measure t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('measure', 'id', pId);
  END IF;

  PERFORM EditMeasure(uMeasure, pParent, pType, pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_measure -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a measure (upsert).
 * @return {SETOF api.measure} - Updated measure record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_measure (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null
) RETURNS       SETOF api.measure
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_measure(pParent, pType, pCode, pName, pDescription);
  ELSE
    PERFORM api.update_measure(pId, pParent, pType, pCode, pName, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.measure WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_measure -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a measure by identifier.
 * @param {uuid} pId - Identifier
 * @return {api.measure} - Measure record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_measure (
  pId        uuid
) RETURNS    SETOF api.measure
AS $$
  SELECT * FROM api.measure WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_measure ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a list of measures.
 * @param {jsonb} pSearch - Search conditions: '[{"condition": "AND|OR", "field": "<field>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<value>"}, ...]'
 * @param {jsonb} pFilter - Filter: '{"<field>": "<value>"}'
 * @param {integer} pLimit - Row limit
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort by fields array
 * @return {SETOF api.measure} - Measure records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_measure (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.measure
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'measure', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
