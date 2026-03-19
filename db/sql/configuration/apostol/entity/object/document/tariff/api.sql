--------------------------------------------------------------------------------
-- TARIFF ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.tariff ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.tariff
AS
  SELECT * FROM ObjectTariff;

GRANT SELECT ON api.tariff TO administrator;

--------------------------------------------------------------------------------
-- api.tariff_scheme -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.tariff_scheme
AS
  SELECT * FROM TariffScheme;

GRANT SELECT ON api.tariff_scheme TO administrator;

--------------------------------------------------------------------------------
-- api.add_tariff --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Adds a new tariff
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pProduct - Product
 * @param {uuid} pService - Service
 * @param {uuid} pCurrency - Currency identifier
 * @param {text} pCode - Code
 * @param {text} pTag - Tag
 * @param {numeric} pPrice - Price
 * @param {numeric} pCommission - Commission
 * @param {numeric} pTax - Tax
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_tariff (
  pParent           uuid,
  pType             uuid,
  pProduct          uuid,
  pService          uuid,
  pCurrency         uuid,
  pCode             text,
  pTag              text,
  pPrice            numeric,
  pCommission       numeric,
  pTax              numeric,
  pLabel            text,
  pDescription      text default null
) RETURNS           uuid
AS $$
BEGIN
  RETURN CreateTariff(pParent, coalesce(pType, GetType('custom.tariff')), pProduct, pService, pCurrency, pCode, pTag, pPrice, pCommission, pTax, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_tariff -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Updates an existing tariff
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pProduct - Product
 * @param {uuid} pService - Service
 * @param {uuid} pCurrency - Currency identifier
 * @param {text} pCode - Code
 * @param {text} pTag - Tag
 * @param {numeric} pPrice - Price
 * @param {numeric} pCommission - Commission
 * @param {numeric} pTax - Tax
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {void}
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_tariff (
  pId               uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pProduct          uuid default null,
  pService          uuid default null,
  pCurrency         uuid default null,
  pCode             text default null,
  pTag              text default null,
  pPrice            numeric default null,
  pCommission       numeric default null,
  pTax              numeric default null,
  pLabel            text default null,
  pDescription      text default null
) RETURNS           void
AS $$
BEGIN
  pId := coalesce(pId, GetTariff(pCode));

  PERFORM FROM db.tariff t WHERE t.id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('tariff', 'id', pId);
  END IF;

  PERFORM EditTariff(pId, pParent, pType, pProduct, pService, pCurrency, pCode, pTag, pPrice, pCommission, pTax, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_tariff --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a tariff (upsert)
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pProduct - Product
 * @param {uuid} pService - Service
 * @param {uuid} pCurrency - Currency identifier
 * @param {text} pCode - Code
 * @param {text} pTag - Tag
 * @param {numeric} pPrice - Price
 * @param {numeric} pCommission - Commission
 * @param {numeric} pTax - Tax
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {SETOF api.tariff}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_tariff (
  pId               uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pProduct          uuid default null,
  pService          uuid default null,
  pCurrency         uuid default null,
  pCode             text default null,
  pTag              text default null,
  pPrice            numeric default null,
  pCommission       numeric default null,
  pTax              numeric default null,
  pLabel            text default null,
  pDescription      text default null
) RETURNS           SETOF api.tariff
AS $$
BEGIN
  pId := coalesce(pId, GetTariff(pCode));

  IF pId IS NULL THEN
    pId := api.add_tariff(pParent, pType, pProduct, pService, pCurrency, pCode, pTag, pPrice, pCommission, pTax, pLabel, pDescription);
  ELSE
    PERFORM api.update_tariff(pId, pParent, pType, pProduct, pService, pCurrency, pCode, pTag, pPrice, pCommission, pTax, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.tariff WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_tariff --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a tariff by identifier
 * @param {uuid} pId - Record identifier
 * @return {api.tariff}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_tariff (
  pId       uuid
) RETURNS   api.tariff
AS $$
  SELECT * FROM api.tariff WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_tariff -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a filtered/sorted list of tariff records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.tariff}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_tariff (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.tariff
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'tariff', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_tariff_scheme -------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a tariff by identifier
 * @param {uuid} pService - Service
 * @param {uuid} pCurrency - Currency identifier
 * @param {text} pTag - Tag
 * @return {SETOF api.tariff_scheme}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_tariff_scheme (
  pService   uuid,
  pCurrency  uuid,
  pTag       text DEFAULT 'default'
) RETURNS    SETOF api.tariff_scheme
AS $$
  SELECT *
    FROM api.tariff_scheme
   WHERE service = pService
     AND currency = pCurrency
     AND tag = pTag
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_tariff_scheme ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a filtered/sorted list of tariff records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.tariff_scheme}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_tariff_scheme (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.tariff_scheme
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'tariff_scheme', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
