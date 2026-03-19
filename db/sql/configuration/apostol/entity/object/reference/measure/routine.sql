--------------------------------------------------------------------------------
-- CreateMeasure ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new measure.
 * @return {uuid} - New measure identifier
 * @throws IncorrectClassType - If type does not belong to 'measure' class
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateMeasure (
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

  IF GetClassCode(uClass) <> 'measure' THEN
    PERFORM IncorrectClassType();
  END IF;

  uReference := CreateReference(pParent, pType, pCode, pName, pDescription);

  INSERT INTO db.measure (id, reference)
  VALUES (uReference, uReference);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uReference, uMethod);

  RETURN uReference;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditMeasure -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing measure.
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditMeasure (
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
-- FUNCTION GetMeasure ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a measure identifier by code.
 * @param {text} pCode - Measure code
 * @return {uuid} - Measure identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetMeasure (
  pCode     text
) RETURNS   uuid
AS $$
BEGIN
  RETURN GetReference(pCode, 'measure');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
