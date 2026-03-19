--------------------------------------------------------------------------------
-- PRODUCT ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.product -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.product
AS
  SELECT * FROM ObjectProduct;

GRANT SELECT ON api.product TO administrator;

--------------------------------------------------------------------------------
-- api.add_product -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Adds a new product
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
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_product (
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
BEGIN
  RETURN CreateProduct(pParent, coalesce(pType, GetType('service.product')), pCode, pName, pDefaultPrice, pTaxCode, pURL, pMetaData, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_product ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Updates an existing product
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
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_product (
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
BEGIN
  pId := coalesce(pId, GetProduct(pCode));

  PERFORM FROM db.product WHERE id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('product', 'id', pId);
  END IF;

  PERFORM EditProduct(pId, pParent, pType, pCode, pName, pDefaultPrice, pTaxCode, pURL, pMetaData, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_product -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a product (upsert)
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
 * @return {SETOF api.product}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_product (
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
) RETURNS       SETOF api.product
AS $$
BEGIN
  pId := coalesce(pId, GetProduct(pCode));

  IF pId IS NULL THEN
    pId := api.add_product(pParent, pType, pCode, pName, pDefaultPrice, pTaxCode, pURL, pMetaData, pLabel, pDescription);
  ELSE
    PERFORM api.update_product(pId, pParent, pType, pCode, pName, pDefaultPrice, pTaxCode, pURL, pMetaData, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.product WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_product -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a product by identifier
 * @param {uuid} pId - Record identifier
 * @return {SETOF api.product}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_product (
  pId        uuid
) RETURNS    SETOF api.product
AS $$
  SELECT * FROM api.product WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_product -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the count of product records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_product (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'product', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_product ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a filtered/sorted list of product records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.product}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_product (
  pSearch    jsonb DEFAULT null,
  pFilter    jsonb DEFAULT null,
  pLimit    integer DEFAULT null,
  pOffSet    integer DEFAULT null,
  pOrderBy    jsonb DEFAULT null
) RETURNS    SETOF api.product
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'product', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
