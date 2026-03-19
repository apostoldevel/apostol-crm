--------------------------------------------------------------------------------
-- COMPANY ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.company -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.company
AS
  SELECT * FROM ObjectCompany;

GRANT SELECT ON api.company TO administrator;

--------------------------------------------------------------------------------
-- api.add_company -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Adds a new company
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pRoot - Root
 * @param {uuid} pNode - Node
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @param {integer} pSequence - Sort order
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_company (
  pParent           uuid,
  pType             uuid,
  pRoot             uuid,
  pNode             uuid,
  pCode             text,
  pName             text,
  pDescription	    text DEFAULT null,
  pSequence         integer default null
) RETURNS           uuid
AS $$
BEGIN
  RETURN CreateCompany(pParent, coalesce(pType, GetType('main.company')), pRoot, pNode, pCode, pName, pDescription, pSequence);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_company ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Updates an existing company
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pRoot - Root
 * @param {uuid} pNode - Node
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @param {integer} pSequence - Sort order
 * @return {void}
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_company (
  pId               uuid,
  pParent           uuid DEFAULT null,
  pType             uuid DEFAULT null,
  pRoot             uuid DEFAULT null,
  pNode             uuid DEFAULT null,
  pCode             text DEFAULT null,
  pName             text DEFAULT null,
  pDescription	    text DEFAULT null,
  pSequence         integer default null
) RETURNS           void
AS $$
BEGIN
  PERFORM FROM db.company WHERE id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('company', 'id', pId);
  END IF;

  PERFORM EditCompany(pId, pParent, pType, pRoot, pNode, pCode, pName, pDescription, pSequence);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_company -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a company (upsert)
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pRoot - Root
 * @param {uuid} pNode - Node
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @param {integer} pSequence - Sort order
 * @return {SETOF api.company}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_company (
  pId               uuid,
  pParent           uuid DEFAULT null,
  pType             uuid DEFAULT null,
  pRoot             uuid DEFAULT null,
  pNode             uuid DEFAULT null,
  pCode             text DEFAULT null,
  pName             text DEFAULT null,
  pDescription	    text DEFAULT null,
  pSequence         integer default null
) RETURNS           SETOF api.company
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_company(pParent, pType, pRoot, pNode, pCode, pName, pDescription, pSequence);
  ELSE
    PERFORM api.update_company(pId, pParent, pType, pRoot, pNode, pCode, pName, pDescription, pSequence);
  END IF;

  RETURN QUERY SELECT * FROM api.company WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_company -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a company by identifier
 * @param {uuid} pId - Record identifier
 * @return {SETOF api.company}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_company (
  pId        uuid
) RETURNS    SETOF api.company
AS $$
  SELECT * FROM api.company WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_company -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the count of company records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_company (
  pSearch    jsonb default null,
  pFilter    jsonb default null
) RETURNS    SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('id', current_area());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'company', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_company ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a filtered/sorted list of company records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @param {jsonb} pFields - Fields
 * @return {SETOF api.company}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_company (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null,
  pFields   jsonb default null
) RETURNS   SETOF api.company
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('id', current_area());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'company', pSearch, pFilter, pLimit, pOffSet, pOrderBy, pFields);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
