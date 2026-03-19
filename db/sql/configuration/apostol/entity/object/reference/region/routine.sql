--------------------------------------------------------------------------------
-- REGION ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CreateRegion ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new region.
 * @return {uuid} - New region identifier
 * @throws IncorrectClassType - If type does not belong to 'region' class
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateRegion (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription  text default null
) RETURNS       uuid
AS $$
DECLARE
  uReference    uuid;
  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetClassCode(uClass) <> 'region' THEN
    PERFORM IncorrectClassType();
  END IF;

  uReference := CreateReference(pParent, pType, pCode, pName, pDescription);

  INSERT INTO db.region (id, reference)
  VALUES (uReference, uReference);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uReference, uMethod);

  RETURN uReference;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditRegion ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing region.
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditRegion (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;
BEGIN
  PERFORM EditReference(pId, pParent, pType, pCode, pName, pDescription, current_locale());

  SELECT class INTO uClass FROM db.object WHERE id = pId;

  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetRegion ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a region identifier by code.
 * @param {text} pCode - Region code
 * @return {uuid} - Region identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetRegion (
  pCode     text
) RETURNS   uuid
AS $$
BEGIN
  RETURN GetReference(pCode, 'region');
END;
$$ LANGUAGE plpgsql
   STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
