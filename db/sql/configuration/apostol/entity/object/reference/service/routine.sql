--------------------------------------------------------------------------------
-- CreateService ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new service.
 * @return {uuid} - New service identifier
 * @throws IncorrectClassType - If type does not belong to 'service' class
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateService (
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
DECLARE
  uReference        uuid;
  uClass            uuid;
  uMethod           uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetClassCode(uClass) <> 'service' THEN
    PERFORM IncorrectClassType();
  END IF;

  uReference := CreateReference(pParent, pType, pCode, pName, pDescription);

  INSERT INTO db.service (id, reference, category, measure, value)
  VALUES (uReference, uReference, pCategory, pMeasure, pValue);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uReference, uMethod);

  RETURN uReference;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditService -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing service.
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditService (
  pId               uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pCategory         uuid default null,
  pMeasure          uuid default null,
  pCode             text default null,
  pName             text default null,
  pValue            integer default null,
  pDescription      text DEFAULT null
) RETURNS           void
AS $$
DECLARE
  uClass            uuid;
  uMethod           uuid;
BEGIN
  PERFORM EditReference(pId, pParent, pType, pCode, pName, pDescription, current_locale());

  UPDATE db.service
     SET category = coalesce(pCategory, category),
         measure = coalesce(pMeasure, measure),
         value = coalesce(pValue, value)
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetService ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a service identifier by code.
 * @param {text} pCode - Service code
 * @return {uuid} - Service identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetService (
  pCode     text
) RETURNS   uuid
AS $$
BEGIN
  RETURN GetReference(pCode, 'service');
END;
$$ LANGUAGE plpgsql
   STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetServiceCode -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a service code by identifier.
 * @param {uuid} pId - Service identifier
 * @return {text} - Service code
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetServiceCode (
  pId       uuid
) RETURNS   text
AS $$
BEGIN
  RETURN GetReferenceCode(pId);
END;
$$ LANGUAGE plpgsql
   STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetServiceValue ----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the value of a service.
 * @param {uuid} pId - Service identifier
 * @return {numeric} - Service value
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetServiceValue (
  pId       uuid
) RETURNS   numeric
AS $$
  SELECT value FROM db.service WHERE id = pId
$$ LANGUAGE SQL
   STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetServiceCategory -------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the category identifier for a service.
 * @param {uuid} pId - Service identifier
 * @return {uuid} - Category identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetServiceCategory (
  pId       uuid
) RETURNS   uuid
AS $$
  SELECT category FROM db.service WHERE id = pId
$$ LANGUAGE SQL
   STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
