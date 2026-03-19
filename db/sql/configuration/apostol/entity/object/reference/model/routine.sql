--------------------------------------------------------------------------------
-- CreateModel -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new model.
 * @return {uuid} - New model identifier
 * @throws IncorrectClassType - If type does not belong to 'model' class
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateModel (
  pParent       uuid,
  pType         uuid,
  pVendor       uuid,
  pCategory        uuid,
  pCode         text,
  pName         text,
  pDescription    text default null
) RETURNS       uuid
AS $$
DECLARE
  uReference    uuid;
  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetClassCode(uClass) <> 'model' THEN
    PERFORM IncorrectClassType();
  END IF;

  uReference := CreateReference(pParent, pType, pCode, pName, pDescription);

  INSERT INTO db.model (id, reference, vendor, category)
  VALUES (uReference, uReference, pVendor, pCategory);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uReference, uMethod);

  RETURN uReference;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditModel -------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing model.
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditModel (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pVendor       uuid default null,
  pCategory        uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription    text default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;
BEGIN
  PERFORM EditReference(pId, pParent, pType, pCode, pName, pDescription);

  UPDATE db.model
     SET vendor = coalesce(pVendor, vendor),
         category = CheckNull(coalesce(pCategory, category, null_uuid()))
   WHERE id = pId;

  SELECT class INTO uClass FROM db.object WHERE id = pId;

  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetModel -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a model identifier by code.
 * @param {text} pCode - Model code
 * @return {uuid} - Model identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetModel (
  pCode        text
) RETURNS     uuid
AS $$
BEGIN
  RETURN GetReference(pCode, 'model');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetModelVendor -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the vendor identifier for a model.
 * @param {uuid} pId - Model identifier
 * @return {uuid} - Vendor identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetModelVendor (
  pId       uuid
) RETURNS     uuid
AS $$
  SELECT vendor FROM db.model WHERE id = pId;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetModelCategory ---------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the category identifier for a model.
 * @param {uuid} pId - Model identifier
 * @return {uuid} - Category identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetModelCategory (
  pId       uuid
) RETURNS     uuid
AS $$
  SELECT category FROM db.model WHERE id = pId;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SetModelProperty ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Sets a property value for a model (upsert).
 * @param {uuid} pModel - Model identifier
 * @param {uuid} pProperty - Property identifier
 * @param {uuid} pMeasure - Measure identifier
 * @param {variant} pValue - Property value (variant type)
 * @param {text} pFormat - Display format string
 * @param {integer} pSequence - Display order sequence
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SetModelProperty (
  pModel        uuid,
  pProperty        uuid,
  pMeasure        uuid,
  pValue        variant,
  pFormat        text,
  pSequence        integer DEFAULT null
) RETURNS        void
AS $$
DECLARE
  r                record;
BEGIN
  IF pSequence IS NULL THEN
      SELECT max(sequence) + 1 INTO pSequence FROM db.model_property WHERE model = pModel;
  END IF;

  SELECT * INTO r FROM db.model_property WHERE model = pModel AND property = pProperty;

  pMeasure := CheckNull(coalesce(pMeasure, r.measure, null_uuid()));

  INSERT INTO db.model_property (model, property, measure, value, format, sequence)
  VALUES (pModel, pProperty, pMeasure, pValue, pFormat, coalesce(pSequence, 1))
    ON CONFLICT (model, property) DO UPDATE SET measure = pMeasure, value = coalesce(pValue, r.value), format = coalesce(pFormat, r.format), sequence = coalesce(pSequence, r.sequence);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- DeleteModelProperty ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Deletes model property(s).
 * @param {uuid} pModel - Model identifier
 * @param {uuid} pProperty - Property identifier (null to delete all)
 * @return {boolean} - True if rows were deleted
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DeleteModelProperty (
  pModel        uuid,
  pProperty        uuid DEFAULT null
) RETURNS        boolean
AS $$
BEGIN
  IF pProperty IS NOT NULL THEN
    DELETE FROM db.model_property WHERE model = pModel AND property = pProperty;
  ELSE
    DELETE FROM db.model_property WHERE model = pModel;
  END IF;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetModelPropertyJson --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns all properties of a model as JSON array.
 * @param {uuid} pModel - Model identifier
 * @return {json} - JSON array of model property records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetModelPropertyJson (
  pModel    uuid
) RETURNS    json
AS $$
DECLARE
  r            record;
  arResult    json[];
BEGIN
  FOR r IN
    SELECT *
      FROM ModelPropertyJson
     WHERE modelId = pModel
     ORDER BY sequence
  LOOP
    arResult := array_append(arResult, row_to_json(r));
  END LOOP;

  RETURN array_to_json(arResult);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetModelPropertyJsonb -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns all properties of a model as JSONB array.
 * @param {uuid} pObject - Model identifier
 * @return {jsonb} - JSONB array of model property records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetModelPropertyJsonb (
  pObject    uuid
) RETURNS    jsonb
AS $$
BEGIN
  RETURN GetModelPropertyJson(pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
