--------------------------------------------------------------------------------
-- CreatePrice -----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new price
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
 * @throws IncorrectClassType
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreatePrice (
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
DECLARE
  uDocument     uuid;

  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'price' THEN
    PERFORM IncorrectClassType();
  END IF;

  PERFORM FROM db.currency WHERE id = pCurrency;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('currency', 'id', pCurrency);
  END IF;

  PERFORM FROM db.product WHERE id = pProduct;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('product', 'id', pProduct);
  END IF;

  uDocument := CreateDocument(pParent, pType, coalesce(pLabel, pCode), pDescription);

  INSERT INTO db.price (id, document, currency, product, code, amount, payment_link, metadata)
  VALUES (uDocument, uDocument, pCurrency, pProduct, pCode, pAmount, pPaymentLink, pMetaData);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uDocument, uMethod);

  RETURN uDocument;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditPrice -------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Edits an existing price
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
CREATE OR REPLACE FUNCTION EditPrice (
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
DECLARE
  uId           uuid;
  uClass        uuid;
  uMethod       uuid;
BEGIN
  IF pCurrency IS NOT NULL THEN
    SELECT id INTO uId FROM db.currency WHERE id = pCurrency;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('currency', 'id', pCurrency);
    END IF;
  END IF;

  IF pProduct IS NOT NULL THEN
    SELECT id INTO uId FROM db.product WHERE id = pProduct;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('product', 'id', pProduct);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription, pDescription, current_locale());

  UPDATE db.price
     SET currency = coalesce(pCurrency, currency),
         product = coalesce(pProduct, product),
         code = coalesce(pCode, code),
         amount = coalesce(pAmount, amount),
         payment_link = CheckNull(coalesce(pPaymentLink, payment_link, '')),
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
-- GetPrice --------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the price by code
 * @param {text} pCode - Code
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetPrice (
  pCode     text
) RETURNS   uuid
AS $$
  SELECT id FROM db.price WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
