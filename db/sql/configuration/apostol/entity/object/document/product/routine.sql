--------------------------------------------------------------------------------
-- CreateProduct ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new product
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDefaultPrice - DefaultPrice
 * @param {text} pTaxCode - TaxCode
 * @param {text} pURL - URL
 * @param {jsonb} pMetaData - MetaData
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @throws IncorrectClassType
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateProduct (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDefaultPrice text DEFAULT null,
  pTaxCode      text DEFAULT null,
  pURL          text DEFAULT null,
  pMetaData     jsonb default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
DECLARE
  uDocument     uuid;
  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'product' THEN
    PERFORM IncorrectClassType();
  END IF;

  uDocument := CreateDocument(pParent, pType, coalesce(pLabel, pName), pDescription);

  INSERT INTO db.product (id, document, code, name, default_price, tax_code, url, metadata)
  VALUES (uDocument, uDocument, pCode, pName, pDefaultPrice, pTaxCode, pURL, pMetaData);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uDocument, uMethod);

  RETURN uDocument;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditProduct -----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Edits an existing product
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDefaultPrice - DefaultPrice
 * @param {text} pTaxCode - TaxCode
 * @param {text} pURL - URL
 * @param {jsonb} pMetaData - MetaData
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditProduct (
  pId           uuid,
  pParent       uuid DEFAULT null,
  pType         uuid DEFAULT null,
  pCode         text DEFAULT null,
  pName         text DEFAULT null,
  pDefaultPrice text DEFAULT null,
  pTaxCode      text DEFAULT null,
  pURL          text DEFAULT null,
  pMetaData     jsonb default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;
BEGIN
  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription, pDescription, current_locale());

  UPDATE db.product
     SET code = coalesce(pCode, code),
         name = coalesce(pName, name),
         default_price = CheckNull(coalesce(pDefaultPrice, default_price, '')),
         tax_code = CheckNull(coalesce(pTaxCode, tax_code, '')),
         url = CheckNull(coalesce(pURL, url, '')),
         metadata = CheckNull(coalesce(pMetaData, metadata, '{}'::jsonb))
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));

  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetProduct ------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the product by code
 * @param {text} pCode - Code
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetProduct (
  pCode     text
) RETURNS   uuid
AS $$
  SELECT id FROM db.product WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetProductCode --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the product code by identifier
 * @param {uuid} pId - Record identifier
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetProductCode (
  pId       uuid
) RETURNS   text
AS $$
  SELECT code FROM db.product WHERE id = pId;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetProductPrice -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the product by code
 * @param {uuid} pId - Record identifier
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetProductPrice (
  pId       uuid
) RETURNS   text
AS $$
  SELECT default_price FROM db.product WHERE id = pId;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
