--------------------------------------------------------------------------------
-- SERVICE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.service -----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief API view for service records.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.service
AS
  SELECT * FROM ObjectService;

GRANT SELECT ON api.service TO administrator;

--------------------------------------------------------------------------------
-- api.add_service -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new service.
 * @param {uuid} pParent - Parent object reference | null
 * @param {uuid} pType - Type code
 * @param {uuid} pCategory - Category identifier
 * @param {uuid} pMeasure - Measure identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {integer} pValue - Value
 * @param {text} pDescription - Description
 * @return {uuid} - New service identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_service (
  pParent           uuid,
  pType             uuid,
  pCategory         uuid,
  pMeasure          uuid,
  pCode             text,
  pName             text,
  pValue            integer,
  pDescription      text DEFAULT null
) RETURNS           uuid
AS $$
BEGIN
  RETURN CreateService(pParent, coalesce(pType, GetType('rent.service')), pCategory, pMeasure, pCode, pName, pValue, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_service ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing service.
 * @param {uuid} pParent - Parent object reference | null
 * @param {text} pType - Type code
 * @param {text} pCategory - Category identifier
 * @param {text} pMeasure - Measure identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {integer} pValue - Value
 * @param {text} pDescription - Description
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_service (
  pId               uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pCategory         uuid default null,
  pMeasure          uuid default null,
  pCode             text default null,
  pName             text default null,
  pValue            integer default null,
  pDescription      text default null
) RETURNS           void
AS $$
BEGIN
  PERFORM FROM db.service t WHERE t.id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('service', 'id', pId);
  END IF;

  PERFORM EditService(pId, pParent, pType, pCategory, pMeasure, pCode, pName, pValue, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_service -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a service (upsert).
 * @return {SETOF api.service} - Updated service record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_service (
  pId               uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pCategory         uuid default null,
  pMeasure          uuid default null,
  pCode             text default null,
  pName             text default null,
  pValue            integer default null,
  pDescription      text default null
) RETURNS           SETOF api.service
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_service(pParent, pType, pCategory, pMeasure, pCode, pName, pValue, pDescription);
  ELSE
    PERFORM api.update_service(pId, pParent, pType, pCategory, pMeasure, pCode, pName, pValue, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.service WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_service -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a service by identifier.
 * @param {uuid} pId - Identifier
 * @return {api.service} - Service record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_service (
  pId        uuid
) RETURNS    SETOF api.service
AS $$
  SELECT * FROM api.service WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_service ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a list of services.
 * @param {jsonb} pSearch - Search conditions: '[{"condition": "AND|OR", "field": "<field>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<value>"}, ...]'
 * @param {jsonb} pFilter - Filter: '{"<field>": "<value>"}'
 * @param {integer} pLimit - Row limit
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort by fields array
 * @return {SETOF api.service} - Service records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_service (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.service
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'service', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
