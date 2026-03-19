--------------------------------------------------------------------------------
-- CreateTariff ----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new tariff
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
 * @throws IncorrectClassType
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateTariff (
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
DECLARE
  uDocument         uuid;
  uClass            uuid;
  uMethod           uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'tariff' THEN
    PERFORM IncorrectClassType();
  END IF;

  PERFORM FROM db.product WHERE id = pProduct;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('product', 'id', pProduct);
  END IF;

  PERFORM FROM db.service WHERE id = pService;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('service', 'id', pService);
  END IF;

  pCurrency := coalesce(pCurrency, DefaultCurrency());

  PERFORM FROM db.currency WHERE id = pCurrency;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('currency', 'id', pCurrency);
  END IF;

  uDocument := CreateDocument(pParent, pType, pLabel, pDescription);

  INSERT INTO db.tariff (id, document, product, service, currency, code, tag, price, commission, tax)
  VALUES (uDocument, uDocument, pProduct, pService, pCurrency, pCode, pTag, pPrice, pCommission, pTax);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uDocument, uMethod);

  RETURN uDocument;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditTariff ------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Edits an existing tariff
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
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditTariff (
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
DECLARE
  uClass            uuid;
  uMethod           uuid;
BEGIN
  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.tariff
     SET product = coalesce(pProduct, product),
         service = coalesce(pService, service),
         currency = coalesce(pCurrency, currency),
         code = coalesce(pCode, code),
         tag = CheckNull(coalesce(pTag, tag, '')),
         price = coalesce(pPrice, price),
         commission = coalesce(pCommission, commission),
         tax = coalesce(pTax, tax)
   WHERE id = pId;

  SELECT class INTO uClass FROM db.object WHERE id = pId;

  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetTariff ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the tariff by code
 * @param {text} pCode - Code
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetTariff (
  pCode     text
) RETURNS   uuid
AS $$
  SELECT id FROM db.tariff WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION SetTariffScheme ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief SetTariffScheme
 * @param {uuid} pService - Service
 * @param {uuid} pCurrency - Currency identifier
 * @param {text} pTag - Tag
 * @param {numeric} pPrice - Price
 * @param {numeric} pCommission - Commission
 * @param {numeric} pTax - Tax
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SetTariffScheme (
  pService      uuid,
  pCurrency     uuid,
  pTag          text,
  pPrice        numeric,
  pCommission   numeric,
  pTax          numeric
) RETURNS       void
AS $$
BEGIN
  INSERT INTO db.tariff_scheme (service, currency, tag, price, commission, tax)
  VALUES (pService, pCurrency, pTag, pPrice, pCommission, pTax)
  ON CONFLICT (service, currency, tag) DO UPDATE SET price = pPrice, commission = pCommission, tax = pTax;
END;
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetTariffScheme ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the tariff by code
 * @param {uuid} pId - Record identifier
 * @return {numeric}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetTariffScheme (
  pId       uuid
) RETURNS   numeric
AS $$
  SELECT price FROM db.tariff WHERE id = pId;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetServiceTariffId -------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the tariff by code
 * @param {uuid} pProduct - Product
 * @param {uuid} pService - Service
 * @param {uuid} pCurrency - Currency identifier
 * @param {text} pTag - Tag
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetServiceTariffId (
  pProduct      uuid,
  pService      uuid,
  pCurrency     uuid,
  pTag          text DEFAULT 'default'
) RETURNS       uuid
AS $$
DECLARE
  uId           uuid;
BEGIN
  SELECT t.id INTO uId
    FROM db.tariff t INNER JOIN db.object o ON t.document = o.id AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
   WHERE t.product = pProduct
     AND t.service = pService
     AND t.currency = pCurrency
     AND t.tag = pTag;

  RETURN uId;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetServicePrice ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the tariff by code
 * @param {uuid} pProduct - Product
 * @param {uuid} pService - Service
 * @param {uuid} pCurrency - Currency identifier
 * @param {text} pTag - Tag
 * @return {numeric}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetServicePrice (
  pProduct  uuid,
  pService  uuid,
  pCurrency uuid,
  pTag      text DEFAULT 'default'
) RETURNS   numeric
AS $$
  SELECT t.price / s.value
    FROM db.tariff t INNER JOIN db.object  o ON t.document = o.id AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
                     INNER JOIN db.service s ON t.service = s.id
   WHERE t.product = pProduct
     AND t.service = pService
     AND t.currency = pCurrency
     AND t.tag = pTag;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
