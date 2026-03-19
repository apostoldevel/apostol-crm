--------------------------------------------------------------------------------
-- CreateTransaction -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new transaction
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pService - Service
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pOrder - Order
 * @param {uuid} pDevice - Device
 * @param {uuid} pTariff - Tariff
 * @param {uuid} pSubscription - Subscription
 * @param {uuid} pInvoice - Invoice
 * @param {bigint} pTransactionId - TransactionId
 * @param {numeric} pPrice - Price
 * @param {numeric} pVolume - Volume
 * @param {numeric} pAmount - Amount
 * @param {numeric} pCommission - Commission
 * @param {numeric} pTax - Tax
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @throws IncorrectClassType
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateTransaction (
  pParent           uuid,
  pType             uuid,
  pClient           uuid,
  pService          uuid,
  pCurrency         uuid,
  pOrder            uuid,
  pDevice           uuid,
  pTariff           uuid,
  pSubscription     uuid,
  pInvoice          uuid,
  pTransactionId    bigint,
  pPrice            numeric,
  pVolume           numeric,
  pAmount           numeric,
  pCommission       numeric DEFAULT null,
  pTax              numeric DEFAULT null,
  pCode             text DEFAULT null,
  pLabel            text DEFAULT null,
  pDescription      text DEFAULT null
) RETURNS           uuid
AS $$
DECLARE
  uDocument         uuid;
  uTransaction      uuid;

  uClass            uuid;
  uMethod           uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetClassCode(uClass) <> 'transaction' THEN
    PERFORM IncorrectClassType();
  END IF;

  pCurrency := coalesce(pCurrency, GetCurrency('RUB'));

  PERFORM FROM db.client WHERE id = pClient;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('client', 'id', pClient);
  END IF;

  PERFORM FROM db.service WHERE id = pService;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('service', 'id', pService);
  END IF;

  PERFORM FROM db.currency WHERE id = pCurrency;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('currency', 'id', pCurrency);
  END IF;

  IF pDevice IS NOT NULL THEN
    PERFORM FROM db.device WHERE id = pDevice;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('device', 'id', pDevice);
    END IF;
  END IF;

  IF pTariff IS NOT NULL THEN
    PERFORM FROM db.tariff WHERE id = pTariff;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('tariff', 'id', pTariff);
    END IF;
  END IF;

  IF pSubscription IS NOT NULL THEN
    PERFORM FROM db.subscription WHERE id = pSubscription;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('subscription', 'id', pSubscription);
    END IF;
  END IF;

  IF pInvoice IS NOT NULL THEN
    PERFORM FROM db.invoice WHERE id = pInvoice;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('invoice', 'id', pInvoice);
    END IF;
  END IF;

  uDocument := CreateDocument(pParent, pType, pLabel, pDescription);

  INSERT INTO db.transaction (id, document, client, service, currency, "order", device, tariff, subscription, invoice, transactionid, code, price, volume, amount, commission, tax)
  VALUES (uDocument, uDocument, pClient, pService, pCurrency, pOrder, pDevice, pTariff, pSubscription, pInvoice, pTransactionId, pCode, pPrice, pVolume, pAmount, coalesce(pCommission, 0), coalesce(pTax, 0))
  RETURNING id INTO uTransaction;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uTransaction, uMethod);

  RETURN uTransaction;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditTransaction -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Edits an existing transaction
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pService - Service
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pOrder - Order
 * @param {uuid} pDevice - Device
 * @param {uuid} pTariff - Tariff
 * @param {uuid} pSubscription - Subscription
 * @param {uuid} pInvoice - Invoice
 * @param {bigint} pTransactionId - TransactionId
 * @param {numeric} pPrice - Price
 * @param {numeric} pVolume - Volume
 * @param {numeric} pAmount - Amount
 * @param {numeric} pCommission - Commission
 * @param {numeric} pTax - Tax
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {void}
 * @throws ObjectNotFound
 * @throws TransactionCodeExists
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditTransaction (
  pId               uuid,
  pParent           uuid DEFAULT null,
  pType             uuid DEFAULT null,
  pClient           uuid DEFAULT null,
  pService          uuid DEFAULT null,
  pCurrency         uuid DEFAULT null,
  pOrder            uuid DEFAULT null,
  pDevice           uuid DEFAULT null,
  pTariff           uuid DEFAULT null,
  pSubscription     uuid DEFAULT null,
  pInvoice          uuid DEFAULT null,
  pTransactionId    bigint DEFAULT null,
  pPrice            numeric DEFAULT null,
  pVolume           numeric DEFAULT null,
  pAmount           numeric DEFAULT null,
  pCommission       numeric DEFAULT null,
  pTax              numeric DEFAULT null,
  pCode             text DEFAULT null,
  pLabel            text DEFAULT null,
  pDescription      text DEFAULT null
) RETURNS           void
AS $$
DECLARE
  uClass            uuid;
  uMethod           uuid;

  -- current
  cCode         text;
BEGIN
  SELECT code INTO cCode FROM db.transaction WHERE id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('transaction', 'id', pId);
  END IF;

  pCode := coalesce(pCode, cCode);

  IF pCode <> cCode THEN
    PERFORM FROM db.transaction WHERE code = pCode;
    IF FOUND THEN
      PERFORM TransactionCodeExists(pCode);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.transaction
     SET client = coalesce(pClient, client),
         service = coalesce(pService, service),
         currency = coalesce(pCurrency, currency),
         "order" = CheckNull(coalesce(pOrder, "order", null_uuid())),
         device = CheckNull(coalesce(pDevice, device, null_uuid())),
         tariff = CheckNull(coalesce(pTariff, tariff, null_uuid())),
         subscription = CheckNull(coalesce(pSubscription, subscription, null_uuid())),
         invoice = CheckNull(coalesce(pInvoice, invoice, null_uuid())),
         transactionid = CheckNull(coalesce(pTransactionId, transactionid, 0)),
         price = coalesce(pPrice, price),
         volume = coalesce(pVolume, volume),
         amount = coalesce(pAmount, amount),
         commission = coalesce(pCommission, commission),
         tax = coalesce(pTax, tax),
         code = coalesce(pCode, code)
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));

  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetTransaction --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the transaction by code
 * @param {text} pCode - Code
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetTransaction (
  pCode         text
) RETURNS       uuid
AS $$
  SELECT id FROM db.transaction WHERE code = pCode
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetTransaction --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the transaction by code
 * @param {integer} pTransactionId - TransactionId
 * @param {uuid} pService - Service
 * @param {uuid} pStateType - StateType
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetTransaction (
  pTransactionId    integer,
  pService          uuid,
  pStateType        uuid
) RETURNS           uuid
AS $$
  SELECT t.id
    FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.state_type = pStateType
   WHERE transactionid = pTransactionId
     AND service = pService
     AND invoice IS NULL
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetTransactionSum -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the transaction by code
 * @param {integer} pTransactionId - TransactionId
 * @param {uuid} pService - Service
 * @param {uuid} pStateType - StateType
 * @return {numeric}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetTransactionSum (
  pTransactionId    integer,
  pService          uuid,
  pStateType        uuid
) RETURNS           numeric
AS $$
  SELECT Sum(t.amount)
    FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.state_type = pStateType
   WHERE transactionid = pTransactionId
     AND service = pService
     AND invoice IS NULL
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetTransactionVolume --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the transaction by code
 * @param {integer} pTransactionId - TransactionId
 * @param {uuid} pService - Service
 * @param {uuid} pStateType - StateType
 * @return {numeric}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetTransactionVolume (
  pTransactionId    integer,
  pService          uuid,
  pStateType        uuid
) RETURNS           numeric
AS $$
  SELECT Sum(t.volume)
    FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.state_type = pStateType
   WHERE transactionid = pTransactionId
     AND service = pService
     AND invoice IS NULL
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateServiceTransaction ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new transaction
 * @param {bigint} pTransactionId - TransactionId
 * @param {uuid} pService - Service
 * @param {uuid} pDevice - Device
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {numeric} pVolume - Volume
 * @param {text} pTag - Tag
 * @return {uuid}
 * @throws TariffNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateServiceTransaction (
  pTransactionId    bigint,
  pService          uuid,
  pDevice           uuid,
  pClient           uuid,
  pCurrency         uuid,
  pVolume           numeric,
  pTag              text DEFAULT null
) RETURNS           uuid
AS $$
DECLARE
  r                 record;
  s                 record;

  uType             uuid;
  uPrice            uuid;
  uTariff           uuid;
  uProduct          uuid;
  uTransaction      uuid;
  uSubscription     uuid;

  nTax              numeric;
  nAmount           numeric;
  nCommission       numeric;

  vCategory         text;
BEGIN
  SELECT category, value INTO s FROM db.service WHERE id = pService;

  pVolume := round(pVolume / coalesce(nullif(s.value, 0), 1), 4);

  vCategory := GetCategoryCode(s.category);

  uType := GetType(replace(vCategory, 'category', 'transaction'));
  IF uType IS NULL THEN
    RAISE EXCEPTION 'ERR-40000: Invalid type value for transaction.';
  END IF;

  uSubscription := GetCurrentSubscription(pClient);

  IF uSubscription IS NOT NULL THEN
    SELECT s.price INTO uPrice FROM db.subscription s WHERE s.id = uSubscription;
    SELECT p.product INTO uProduct FROM db.price p WHERE p.id = uPrice;
  ELSE
    SELECT p.id INTO uProduct FROM db.product p WHERE p.name = RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject\Default', 'Product');
  END IF;

  IF uProduct IS NULL THEN
    RAISE EXCEPTION 'ERR-40000: The product is not found.';
  END IF;

  uTariff := GetServiceTariffId(uProduct, pService, pCurrency);

  IF uTariff IS NULL THEN
    PERFORM TariffNotFound(GetReferenceName(pService), GetReferenceName(pCurrency), pTag);
  END IF;

  SELECT price, commission, tax INTO r FROM db.tariff WHERE id = uTariff;

  nAmount := round(r.price * pVolume, 2);
  nCommission := 0;
  nTax := 0;

  IF coalesce(r.commission, 0) > 0 THEN
    nCommission := round(nAmount * r.commission / 100, 2);
  END IF;

  IF coalesce(r.tax, 0) > 0 THEN
    nTax := round(nAmount * r.tax / 100, 2);
  END IF;

  nAmount := nAmount + nCommission + nTax;

  SELECT t.id INTO uTransaction
    FROM db.transaction t INNER JOIN db.object o ON t.document = o.id
   WHERE t.transactionid = pTransactionId
     AND t.service = pService
     AND t.tariff = uTariff
     AND t.invoice IS NULL
   ORDER BY o.pdate DESC;

  IF NOT FOUND THEN
    uTransaction := CreateTransaction(pDevice, uType, pClient, pService, pCurrency, null, pDevice, uTariff, uSubscription, null, pTransactionId, r.price, pVolume, nAmount, nCommission, nTax);
  ELSE
    PERFORM EditTransaction(uTransaction, pDevice, uType, pClient, pService, pCurrency, null, pDevice, uTariff, uSubscription, null, pTransactionId, r.price, pVolume, nAmount, nCommission, nTax);
  END IF;

  RETURN uTransaction;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateTransactions ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new transaction
 * @param {bigint} pTransactionId - TransactionId
 * @return {void}
 * @throws DeviceNotAssociated
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateTransactions (
  pTransactionId    bigint
) RETURNS           void
AS $$
DECLARE
  r                 record;
  e                 record;

  uArea             uuid;
  uSaveArea         uuid;

  uClient           uuid;
  uTransaction      uuid;

  nVolume           numeric;

  vMessage          text;
  vContext          text;
BEGIN
  uSaveArea := current_area();

  SELECT device, station, volume,
         CASE WHEN datestop = MAXDATE() THEN Now() ELSE datestop END - datestart AS duration
    INTO r
    FROM db.station_transaction WHERE id = pTransactionId;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ERR-40000: Transaction not found: %.', pTransactionId;
  END IF;

  SELECT client INTO uClient FROM db.device WHERE id = r.device;

  IF uClient IS NULL THEN
    PERFORM DeviceNotAssociated(GetDeviceIdentifier(r.device));
  END IF;

  --

  SELECT area INTO uArea FROM db.document WHERE id = r.device;

  PERFORM SetSessionArea(uArea);

  --

  FOR e IN
    SELECT s.id, rr.code
      FROM db.service s INNER JOIN db.object          o ON s.reference = o.id AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
                        INNER JOIN db.reference      rr ON s.reference = rr.id
     WHERE rr.code IN ('time.service', 'volume.service')
  LOOP
    IF e.code = 'time.service' THEN
      nVolume := trunc(extract(EPOCH FROM r.duration));
    END IF;

    IF e.code = 'volume.service' THEN
      nVolume := r.volume;
    END IF;

    uTransaction := CreateServiceTransaction(pTransactionId, e.id, r.device, uClient, DefaultCurrency(), nVolume);
  END LOOP;

  PERFORM pg_notify('transaction', json_build_object('client', uClient, 'device', r.device)::text);

  PERFORM SetSessionArea(uSaveArea);
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
  PERFORM WriteDiagnostics(vMessage, vContext);
  PERFORM SetSessionArea(uSaveArea);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CloseTransactions -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CloseTransactions
 * @param {uuid} pDevice - Device
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CloseTransactions (
  pDevice   uuid
) RETURNS   void
AS $$
BEGIN
  PERFORM DoDisable(t.id)
     FROM db.transaction t INNER JOIN db.object o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
                           INNER JOIN db.device g ON t.device = g.id
    WHERE t.device = pDevice;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CancelTransactions ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CancelTransactions
 * @param {uuid} pDevice - Device
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CancelTransactions (
  pDevice   uuid
) RETURNS   void
AS $$
BEGIN
  PERFORM DoCancel(t.id)
     FROM db.transaction t INNER JOIN db.object o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
    WHERE t.device = pDevice;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetTransactionsAmount -------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the transaction by code
 * @param {uuid} pOrder - Order
 * @param {uuid} pService - Service
 * @return {numeric}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetTransactionsAmount (
  pOrder    uuid,
  pService  uuid
) RETURNS   numeric
AS $$
  SELECT sum(t.amount)
    FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.state_type = '00000000-0000-4000-b001-000000000003'::uuid
   WHERE t."order" = pOrder
     AND t.service = pService;
$$ LANGUAGE sql
   STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
