--------------------------------------------------------------------------------
-- CreateCategory --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new category.
 * @return {uuid} - New category identifier
 * @throws IncorrectClassType - If type does not belong to 'category' class
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateCategory (
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

  IF GetClassCode(uClass) <> 'category' THEN
    PERFORM IncorrectClassType();
  END IF;

  uReference := CreateReference(pParent, pType, pCode, pName, pDescription);

  INSERT INTO db.category (id, reference)
  VALUES (uReference, uReference);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uReference, uMethod);

  RETURN uReference;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditCategory ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing category.
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditCategory (
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
-- SetCategory -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates or updates a category (upsert by code).
 * @param {uuid} pId - Category identifier (null to lookup by code)
 * @param {uuid} pParent - Parent object identifier
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Category code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @return {uuid} - Category identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SetCategory (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  IF pId IS NULL AND pCode IS NOT NULL THEN
    pId := GetCategory(pCode);
  END IF;

  IF pId IS NULL THEN
    pId := CreateCategory(pParent, coalesce(pType, GetType('item.category')), pCode, pName, pDescription);
  ELSE
    PERFORM EditCategory(pId, pParent, pType, pCode, pName, pDescription);
  END IF;

  RETURN pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetCategory --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a category identifier by code.
 * @param {text} pCode - Category code
 * @return {uuid} - Category identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCategory (
  pCode     text
) RETURNS   uuid
AS $$
BEGIN
  RETURN GetReference(pCode, 'category');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetCategoryCode ----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a category code by identifier.
 * @param {uuid} pId - Category identifier
 * @return {text} - Category code
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCategoryCode (
  pId       uuid
) RETURNS   text
AS $$
BEGIN
  RETURN GetReferenceCode(pId);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
