--------------------------------------------------------------------------------
-- PRICE -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.price -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.price
AS
  SELECT * FROM ObjectPrice;

GRANT SELECT ON api.price TO administrator;

--------------------------------------------------------------------------------
-- api.add_price ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Adds a new price
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pProduct - Product
 * @param {text} pCode - Code
 * @param {numeric} pAmount - Amount
 * @param {text} pPaymentLink - PaymentLink
 * @param {jsonb} pMetaData - MetaData
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_price (
  pParent       uuid,
  pType         uuid,
  pCurrency     uuid,
  pProduct      uuid,
  pCode         text,
  pAmount       numeric,
  pPaymentLink  text default null,
  pMetaData     jsonb default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreatePrice(pParent, coalesce(pType, GetType('one_time.price')), pCurrency, pProduct, pCode, pAmount, pPaymentLink, pMetaData, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_price ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Updates an existing price
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pProduct - Product
 * @param {text} pCode - Code
 * @param {numeric} pAmount - Amount
 * @param {text} pPaymentLink - PaymentLink
 * @param {jsonb} pMetaData - MetaData
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {void}
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_price (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCurrency     uuid default null,
  pProduct      uuid default null,
  pCode         text default null,
  pAmount       numeric default null,
  pPaymentLink  text default null,
  pMetaData     jsonb default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
BEGIN
  pId := coalesce(pId, GetPrice(pCode));

  PERFORM FROM db.price c WHERE c.id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('price', 'id', pId);
  END IF;

  PERFORM EditPrice(pId, pParent, pType, pCurrency, pProduct, pCode, pAmount, pPaymentLink, pMetaData, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_price ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a price (upsert)
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pProduct - Product
 * @param {text} pCode - Code
 * @param {numeric} pAmount - Amount
 * @param {text} pPaymentLink - PaymentLink
 * @param {jsonb} pMetaData - MetaData
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {SETOF api.price}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_price (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCurrency     uuid default null,
  pProduct      uuid default null,
  pCode         text default null,
  pAmount       numeric default null,
  pPaymentLink  text default null,
  pMetaData     jsonb default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       SETOF api.price
AS $$
BEGIN
  pId := coalesce(pId, GetPrice(pCode));

  IF pId IS NULL THEN
    pId := api.add_price(pParent, pType, pCurrency, pProduct, pCode, pAmount, pPaymentLink, pMetaData, pLabel, pDescription);
  ELSE
    PERFORM api.update_price(pId, pParent, pType, pCurrency, pProduct, pCode, pAmount, pPaymentLink, pMetaData, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.price WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_price ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a price by identifier
 * @param {uuid} pId - Record identifier
 * @return {SETOF api.price}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_price (
  pId        uuid
) RETURNS    SETOF api.price
AS $$
  SELECT * FROM api.price WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_price -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the count of price records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_price (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'price', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_price --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a filtered/sorted list of price records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.price}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_price (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.price
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'price', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
