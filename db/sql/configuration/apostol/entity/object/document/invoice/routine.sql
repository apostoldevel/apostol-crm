--------------------------------------------------------------------------------
-- CreateInvoice ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new invoice
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pDevice - Device
 * @param {text} pCode - Code
 * @param {numeric} pAmount - Amount
 * @param {text} pPDF - PDF
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @throws IncorrectClassType
 * @throws InvoiceCodeExists
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateInvoice (
  pParent       uuid,
  pType         uuid,
  pCurrency     uuid,
  pClient       uuid,
  pDevice       uuid,
  pCode         text,
  pAmount       numeric,
  pPDF          text default null,
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

  IF GetEntityCode(uClass) <> 'invoice' THEN
    PERFORM IncorrectClassType();
  END IF;

  PERFORM FROM db.invoice WHERE code = pCode;
  IF FOUND THEN
    PERFORM InvoiceCodeExists(pCode);
  END IF;

  pCurrency := coalesce(pCurrency, DefaultCurrency());

  PERFORM FROM db.currency WHERE id = pCurrency;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('currency', 'id', pCurrency);
  END IF;

  PERFORM FROM db.client WHERE id = pClient;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('client', 'id', pClient);
  END IF;

  IF pDevice IS NOT NULL THEN
    PERFORM FROM db.device WHERE id = pDevice;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('device', 'id', pDevice);
    END IF;
  END IF;

  uDocument := CreateDocument(pParent, pType, pLabel, pDescription);

  INSERT INTO db.invoice (id, document, currency, client, device, code, amount, pdf)
  VALUES (uDocument, uDocument, pCurrency, pClient, pDevice, pCode, pAmount, pPDF);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uDocument, uMethod);

  RETURN uDocument;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditInvoice -----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Edits an existing invoice
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pDevice - Device
 * @param {text} pCode - Code
 * @param {numeric} pAmount - Amount
 * @param {text} pPDF - PDF
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {void}
 * @throws InvoiceCodeExists
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditInvoice (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCurrency     uuid default null,
  pClient       uuid default null,
  pDevice       uuid default null,
  pCode         text default null,
  pAmount       numeric default null,
  pPDF          text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;

  -- current
  cCode         text;
BEGIN
  SELECT code INTO cCode FROM db.invoice WHERE id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('invoice', 'id', pId);
  END IF;

  pCode := coalesce(pCode, cCode);

  IF pCode <> cCode THEN
    PERFORM FROM db.invoice WHERE code = pCode;
    IF FOUND THEN
      PERFORM InvoiceCodeExists(pCode);
    END IF;
  END IF;

  IF pCurrency IS NOT NULL THEN
    PERFORM FROM db.currency WHERE id = pCurrency;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('currency', 'id', pCurrency);
    END IF;
  END IF;

  IF pClient IS NOT NULL THEN
    PERFORM FROM db.client WHERE id = pClient;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('client', 'id', pClient);
    END IF;
  END IF;

  IF pDevice IS NOT NULL THEN
    PERFORM FROM db.device WHERE id = pDevice;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('device', 'id', pDevice);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.invoice
     SET currency = coalesce(pCurrency, currency),
         client = coalesce(pClient, client),
         device = CheckNull(coalesce(pDevice, device, null_uuid())),
         code = pCode,
         amount = coalesce(pAmount, amount),
         pdf = coalesce(pPDF, pdf)
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));

  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetInvoice ------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the invoice by code
 * @param {text} pCode - Code
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetInvoice (
  pCode     text
) RETURNS   uuid
AS $$
  SELECT id FROM db.invoice WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetInvoiceCode --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the invoice code by identifier
 * @param {uuid} pInvoice - Invoice
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetInvoiceCode (
  pInvoice  uuid
) RETURNS   text
AS $$
  SELECT code FROM db.invoice WHERE id = pInvoice;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetInvoiceAmount ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the invoice by code
 * @param {uuid} pInvoice - Invoice
 * @return {numeric}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetInvoiceAmount (
  pInvoice  uuid
) RETURNS   numeric
AS $$
  SELECT amount FROM db.invoice WHERE id = pInvoice;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- BuildInvoice ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new invoice
 * @param {uuid} pDevice - Device identifier
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION BuildInvoice (
  pDevice       uuid
) RETURNS       uuid
AS $$
DECLARE
  r             record;
  x             record;
  e             record;

  uInvoice      uuid;

  vMessage      text;
  vContext      text;
BEGIN
  SELECT t.id, t.identifier, ot.label INTO e
    FROM db.device t LEFT JOIN db.object_text  ot ON ot.object = t.document AND ot.locale = current_locale()
   WHERE t.id = pDevice;

  FOR r IN
    SELECT t.client, f.currency, Sum(t.amount) AS amount
      FROM db.transaction t INNER JOIN db.object            o ON t.document = o.id AND o.state_type = '00000000-0000-4000-b001-000000000003'::uuid
                            INNER JOIN db.tariff            f ON t.tariff = f.id
     WHERE t.device = pDevice
       AND t.invoice IS NULL
     GROUP BY t.client, f.currency
    HAVING Sum(t.amount) >= 1
  LOOP
    uInvoice := CreateInvoice(pDevice, GetType('payment.invoice'), r.currency, r.client, pDevice, null, r.amount);

    FOR x IN
      SELECT t.id
        FROM Transaction t INNER JOIN db.object       o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000003'::uuid
                           INNER JOIN db.tariff       f ON t.tariff = f.id
                            LEFT JOIN db.object_text ot ON ot.object = o.id AND ot.locale = current_locale()
       WHERE t.device = pDevice
         AND t.client = r.client
         AND f.currency = r.currency
         AND t.invoice IS NULL
    LOOP
      UPDATE db.transaction SET invoice = uInvoice WHERE id = x.id;
    END LOOP;

    IF IsCreated(uInvoice) THEN
      PERFORM DoEnable(uInvoice);
      PERFORM SendPush(uInvoice, 'Счёт на оплату', format('Сформирован счёт на сумму %s рублей.', r.amount), GetClientUserId(r.client));
    END IF;
  END LOOP;

  RETURN uInvoice;
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
  PERFORM WriteDiagnostics(vMessage, vContext);

  RETURN null;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
