--------------------------------------------------------------------------------
-- CUSTOMER --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.employee ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.employee
AS
  SELECT * FROM ObjectClient WHERE class = GetClass('employee');

GRANT SELECT ON api.employee TO administrator;

--------------------------------------------------------------------------------
-- api.add_employee ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Adds a new employee
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCompany - Company identifier
 * @param {uuid} pUserId - User account for the employee
 * @param {text} pCode - Employee code
 * @param {text} pName - Full company name / person full name
 * @param {text} pPhone - Phone number
 * @param {text} pEmail - Email address
 * @param {date} pBirthday - Opening date / date of birth
 * @param {text} pPhoto - Photo URL
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Additional metadata
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_employee (
  pParent       uuid,
  pType         uuid,
  pCompany      uuid,
  pUserId       uuid,
  pCode         text,
  pName         text,
  pPhone        text default null,
  pEmail        text default null,
  pBirthday     date default null,
  pPhoto        text default null,
  pDescription  text default null,
  pMetadata     jsonb default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateClient(pParent, coalesce(pType, GetType('support.employee')), pCompany, pUserId, pCode, pName, pPhone, pEmail, pBirthday, null, null, null, null, null, null, null, null, null, null, null, null, null, decode(pPhoto, 'base64'), pDescription, pMetadata);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_employee ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing employee
 * @param {uuid} pId - Employee identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCompany - Company identifier
 * @param {uuid} pUserId - User account for the employee
 * @param {text} pCode - Employee code
 * @param {text} pName - Full company name / person full name
 * @param {text} pPhone - Phone number
 * @param {text} pEmail - Email address
 * @param {date} pBirthday - Opening date / date of birth
 * @param {text} pPhoto - Photo URL
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Additional metadata
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_employee (
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

  PERFORM EditClient(pId, pParent, pType, pCompany, pUserId, pCode, pName, pPhone, pEmail, pBirthday, null, null, null, null, null, null, null, null, null, null, null, null, null, decode(pPhoto, 'base64'), pDescription, pMetadata);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_employee ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates an employee (upsert)
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
 * @param {text} pPhoto - Photo
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Metadata
 * @return {SETOF api.employee}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_employee (
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
  pPhoto        text default null,
  pDescription  text default null,
  pMetadata     jsonb default null
) RETURNS       SETOF api.employee
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_employee(pParent, pType, pCompany, pUserId, pCode, pName, pPhone, pEmail, pBirthday, pPhoto, pDescription, pMetadata);
  ELSE
    PERFORM api.update_employee(pId, pParent, pType, pCompany, pUserId, pCode, pName, pPhone, pEmail, pBirthday, pPhoto, pDescription, pMetadata);
  END IF;

  RETURN QUERY SELECT * FROM api.employee WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_employee ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns an employee by identifier
 * @param {uuid} pId - Identifier
 * @return {api.employee} - Employee record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_employee (
  pId        uuid
) RETURNS    SETOF api.employee
AS $$
  SELECT * FROM api.employee WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_employee ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of employee records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_employee (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('id', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'employee', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_employee -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a filtered/sorted list of employee records
 * @param {jsonb} pSearch - Search conditions array
 * @param {jsonb} pFilter - Filter object
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.employee} - List of employee records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_employee (
  pSearch	jsonb DEFAULT null,
  pFilter	jsonb DEFAULT null,
  pLimit	integer DEFAULT null,
  pOffSet	integer DEFAULT null,
  pOrderBy	jsonb DEFAULT null
) RETURNS	SETOF api.employee
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('id', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'employee', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
