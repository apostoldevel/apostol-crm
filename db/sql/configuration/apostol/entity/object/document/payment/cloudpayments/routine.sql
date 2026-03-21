--------------------------------------------------------------------------------
-- CreateCloudPaymentContent ---------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new CloudPayments payment
 * @param {uuid} pInvoice - Invoice
 * @return {jsonb}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateCloudPaymentContent (
  pInvoice      uuid
) RETURNS       jsonb
AS $$
DECLARE
  r             record;

  uUserId       uuid;
  uClient       uuid;
  uServices     uuid[];

  inn           text;
  ts            text;

  receipt       jsonb;
  items         jsonb;

  nAmount       numeric;

  vEmail        text;
  vPhone        text;

  bVerPhone     bool;
  bVerEmail     bool;
BEGIN
  SELECT client, amount INTO uClient, nAmount FROM db.invoice WHERE id = pInvoice;

  uUserId := GetClientUserId(uClient);

  SELECT email, phone, email_verified, phone_verified INTO vEmail, vPhone, bVerEmail, bVerPhone
    FROM db.user u INNER JOIN db.profile p ON u.id = p.userid
   WHERE id = uUserId;

  uServices := ARRAY[GetService('suspended.service'), GetService('waiting.service')];

  inn := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Service\CloudKassir', 'Inn', uUserId);
  ts := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Service\CloudKassir', 'TaxationSystem', uUserId);

  items := jsonb_build_array();

  FOR r IN
    SELECT t.volume, t.amount, t.price, mt.name AS measurename, coalesce(ot.label, st.name) AS label
      FROM Transaction t INNER JOIN db.object           o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000003'::uuid
                         INNER JOIN db.service          e ON e.id = t.service
                          LEFT JOIN db.reference_text  st ON st.reference = e.id AND st.locale = '00000000-0000-4001-a000-000000000002'::uuid
                          LEFT JOIN db.reference_text  mt ON mt.reference = e.measure AND mt.locale = '00000000-0000-4001-a000-000000000002'::uuid
                          LEFT JOIN db.object_text     ot ON ot.object = o.id AND ot.locale = '00000000-0000-4001-a000-000000000002'::uuid
     WHERE t.invoice = pInvoice
       AND t.service NOT IN (SELECT unnest(uServices))
       AND t.amount > 0
  LOOP
    r.volume := trunc(r.amount / r.price, 2);
    items := items || jsonb_build_object('label', r.label, 'price', r.price, 'quantity', r.volume, 'amount', r.amount, 'vat', 20, 'method', 4, 'object', 4, 'measurementUnit', r.measurename);
  END LOOP;

  FOR r IN
    SELECT Sum(t.volume) AS volume, Sum(t.amount) AS amount, trunc(Avg(t.price), 2) AS price, mt.name AS measurename, 'Ожидание' AS label
      FROM Transaction t INNER JOIN db.object           o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000003'::uuid
                         INNER JOIN db.service          e ON e.id = t.service
                          LEFT JOIN db.reference_text  mt ON mt.reference = e.measure AND mt.locale = '00000000-0000-4001-a000-000000000002'::uuid
                          LEFT JOIN db.object_text     ot ON ot.object = o.id AND ot.locale = '00000000-0000-4001-a000-000000000002'::uuid
     WHERE t.invoice = pInvoice
       AND t.service IN (SELECT unnest(uServices))
       AND t.amount > 0
     GROUP BY t.tariff, mt.name
  LOOP
    r.volume := trunc(r.amount / r.price, 2);
    items := items || jsonb_build_object('label', r.label, 'price', r.price, 'quantity', r.volume, 'amount', r.amount, 'vat', 20, 'method', 4, 'object', 4, 'measurementUnit', r.measurename);
  END LOOP;

  receipt := jsonb_build_object('Items', items, 'TaxationSystem', ts, 'Amounts', jsonb_build_object('electronic', nAmount));
  receipt := receipt || jsonb_build_object('email', vEmail);

  IF bVerPhone THEN
    receipt := receipt || jsonb_build_object('phone', vPhone);
  END IF;

  RETURN jsonb_build_object('Inn', inn, 'InvoiceId', pInvoice, 'Type', 'Income', 'CustomerReceipt', receipt);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SendCloudPayment ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief SendCloudPayment
 * @param {uuid} pInvoice - Invoice
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SendCloudPayment (
  pInvoice      uuid
) RETURNS       uuid
AS $$
DECLARE
  profile       text;
  address       text;
  subject       text;

  content       jsonb;

  vMessage      text;
  vContext      text;

  errorCode     integer;
  errorMessage  text;
BEGIN
  profile := 'cloudpayments';
  address := '/kkt/receipt';
  subject := 'receipt';
  content := CreateCloudPaymentContent(pInvoice);

  RETURN SendMessage(pInvoice, GetAgent('cloudkassir.agent'), profile, address, subject, content::text);
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetErrorMessage(vMessage);

  SELECT * INTO errorCode, errorMessage FROM ParseMessage(vMessage);

  PERFORM WriteToEventLog('E', errorCode, errorMessage);
  PERFORM WriteToEventLog('D', errorCode, vContext);

  RETURN null;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SendCloudPaymentTest --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief SendCloudPaymentTest
 * @param {uuid} pInvoice - Invoice
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SendCloudPaymentTest (
  pInvoice      uuid
) RETURNS       uuid
AS $$
DECLARE
  profile       text;
  address       text;
  subject       text;

  vMessage      text;
  vContext      text;

  errorCode     integer;
  errorMessage  text;
BEGIN
  profile := 'cloudpayments';
  address := 'test';
  subject := 'test';

  RETURN SendMessage(pInvoice, GetAgent('cloudkassir.agent'), profile, address, subject, null);
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetErrorMessage(vMessage);

  SELECT * INTO errorCode, errorMessage FROM ParseMessage(vMessage);

  PERFORM WriteToEventLog('E', errorCode, errorMessage);
  PERFORM WriteToEventLog('D', errorCode, vContext);

  RETURN null;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CP_Error -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CP_Error
 * @param {uuid} pObject - Object identifier
 * @param {int} pCode - Code
 * @param {text} pEvent - Event
 * @param {text} pText - Text content
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CP_Error (
  pObject       uuid,
  pCode         int,
  pEvent        text,
  pText         text
) RETURNS       void
AS $$
BEGIN
  PERFORM SetObjectLabel(pObject, pText);
  PERFORM WriteToEventLog('E', pCode, pEvent, pText, pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CP_Fetch -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CP_Fetch
 * @param {text} pResource - Resource
 * @param {text} pMethod - Method
 * @param {jsonb} pPayload - JSON request payload
 * @param {jsonb} pData - Additional data
 * @param {text} pMessage - Message text
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CP_Fetch (
  pResource     text,
  pMethod       text,
  pPayload      jsonb,
  pData         jsonb DEFAULT null,
  pMessage      text DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  headers       jsonb;

  uKey          uuid;

  vAPI          text;
  vPublicId     text;
  vSecret       text;
  vUserAgent    text;

  content       bytea;
BEGIN
  uKey := gen_random_uuid();

  vAPI := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Service\CloudPayments\API', 'URL');
  vPublicId := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Service\CloudPayments', 'PublicId');
  vSecret := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Service\CloudPayments', 'Secret');
  vUserAgent := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Name');

  pData := coalesce(pData, jsonb_build_object()) || jsonb_build_object('session', current_session(), 'user_id', current_userid(), 'idempotence_key', uKey);

  headers := jsonb_build_object('User-Agent', coalesce(vUserAgent, 'OCPP CSS'), 'Accept', 'application/json', 'Content-Type', 'application/json');
  headers := headers || jsonb_build_object('Authorization', 'Basic ' || replace(encode(convert_to(vPublicId || ':' || vSecret, 'utf8'), 'base64'), E'\n', ''));
  headers := headers || jsonb_build_object('X-Request-ID', uKey);

  content := convert_to(jsonb_pretty(pPayload), 'utf8');

  RETURN http.fetch(vAPI || pResource, pMethod, headers, content, 'api.cloudpayments_done', 'api.cloudpayments_fail', 'cloudpayments', vPublicId, pResource, pMessage, 'curl', pData);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CP_BindCard --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CP_BindCard
 * @param {uuid} pCard - Card identifier
 * @param {text} pCardData - CardData
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CP_BindCard (
  pCard         uuid,
  pCardData     text
) RETURNS       void
AS $$
DECLARE
  uArent        uuid;
  uClient       uuid;
  vCode         text;
BEGIN
  SELECT code, client INTO vCode, uClient FROM db.card WHERE id = pCard;

  uArent := GetAgent('cloudpayments.agent');

  PERFORM ClearCardData(pCard, uArent);
  PERFORM SetCardData(pCard, uArent, pEncrypted => pCardData);

  PERFORM SetObjectData(pCard, 'text', 'Version', null);
  PERFORM EditDocument(pCard, pLabel => '', pDescription => '');

  PERFORM CreateOrder(pCard, GetType('validation.cloudpayments'), DefaultCurrency(), uClient, pCard, null, 1, null, null, null, 'Card validation.');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CP_Payment ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CP_Payment
 * @param {uuid} pPayment - Payment
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CP_Payment (
  pPayment      uuid
) RETURNS       uuid
AS $$
DECLARE
  r             record;

  uCard         uuid;
  uUserId       uuid;
  uClient       uuid;
  uInvoice      uuid;
  uCurrency     uuid;

  nAmount       numeric;

  vName         text;
  vPhone        text;
  vEmail        text;
  vHost         text;
  vHostIP       text;
  vPayType      text;
  vCardData     text;

  bVerPhone		bool;
  bVerEmail		bool;

  payload       jsonb;
  data          jsonb;
BEGIN
  SELECT client, card, invoice, currency, amount INTO uClient, uCard, uInvoice, uCurrency, nAmount FROM db.payment WHERE id = pPayment;
  SELECT name INTO vName FROM db.card WHERE id = uCard;
  SELECT encrypted INTO vCardData FROM db.card_data WHERE card = uCard AND agent = GetAgent('cloudpayments.agent');

  IF GetObjectTypeCode(pPayment) = 'validation.cloudpayments' THEN
    vPayType := '/auth';
  ELSE
    vPayType := '/charge';
  END IF;

  vHost := coalesce(RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Host'), 'https://example.com');
  vHostIP := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Service\CloudPayments', 'HostIP');

  uUserId := GetClientUserId(uClient);

  SELECT email, phone, email_verified, phone_verified INTO vEmail, vPhone, bVerEmail, bVerPhone
	FROM db.user u INNER JOIN db.profile p ON u.id = p.userid
   WHERE id = uUserId;

  payload := jsonb_build_object();
  data := jsonb_build_object('client', uClient, 'card', uCard, 'order', pPayment);

  IF vPhone IS NOT NULL THEN
    SELECT * INTO r FROM GetClientNameRec(uClient);
    payload := payload || jsonb_build_object('Payer', jsonb_build_object('FirstName', r.first, 'LastName', r.last, 'MiddleName', r.middle, 'Phone', '+' || vPhone));
  END IF;

  IF vEmail IS NOT NULL THEN
    payload := payload || jsonb_build_object('Email', vEmail);
  END IF;

  payload := payload || jsonb_build_object('Amount', nAmount, 'IpAddress', vHostIP, 'CardCryptogramPacket', vCardData, 'Currency', GetCurrencyCode(uCurrency), 'AccountId', uClient, 'Description', GetDocumentDescription(pPayment), 'Name', vName, 'PaymentUrl', vHost, 'CultureName', 'ru-RU', 'JsonData', data);

  IF uInvoice IS NOT NULL THEN
    payload := payload || jsonb_build_object('InvoiceId', uInvoice);
  END IF;

  RETURN CP_Fetch('/payments/cards' || vPayType, 'POST', payload, data);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CP_Charge ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CP_Charge
 * @param {uuid} pPayment - Payment
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CP_Charge (
  pPayment      uuid
) RETURNS       uuid
AS $$
DECLARE
  r             record;

  uCard         uuid;
  uUserId       uuid;
  uClient       uuid;
  uInvoice      uuid;
  uCurrency     uuid;

  nAmount       numeric;

  vPhone        text;
  vEmail        text;
  vHost         text;
  vHostIP       text;
  vPayType      text;
  vBinding      text;

  bVerPhone		bool;
  bVerEmail		bool;

  payload       jsonb;
  data          jsonb;
BEGIN
  SELECT client, card, invoice, currency, amount INTO uClient, uCard, uInvoice, uCurrency, nAmount FROM db.payment WHERE id = pPayment;
  SELECT binding INTO vBinding FROM db.card_data WHERE card = uCard AND agent = GetAgent('cloudpayments.agent');

  IF GetObjectTypeCode(pPayment) = 'validation.cloudpayments' THEN
    vPayType := '/auth';
  ELSE
    vPayType := '/charge';
  END IF;

  vHost := coalesce(RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Host'), 'https://example.com');
  vHostIP := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Service\CloudPayments', 'HostIP');

  uUserId := GetClientUserId(uClient);

  SELECT email, phone, email_verified, phone_verified INTO vEmail, vPhone, bVerEmail, bVerPhone
	FROM db.user u INNER JOIN db.profile p ON u.id = p.userid
   WHERE id = uUserId;

  payload := jsonb_build_object();
  data := jsonb_build_object('client', uClient, 'card', uCard, 'order', pPayment);

  IF vPhone IS NOT NULL AND bVerPhone THEN
    SELECT * INTO r FROM GetClientNameRec(uClient);
    payload := payload || jsonb_build_object('Payer', jsonb_build_object('FirstName', r.first, 'LastName', r.last, 'MiddleName', r.middle, 'Phone', '+' || vPhone));
  END IF;

  IF vEmail IS NOT NULL AND bVerEmail THEN
    payload := payload || jsonb_build_object('Email', vEmail);
  END IF;

  payload := payload || jsonb_build_object('Amount', nAmount, 'Currency', GetCurrencyCode(uCurrency), 'IpAddress', vHostIP, 'AccountId', uClient, 'Description', GetDocumentDescription(pPayment), 'Token', vBinding, 'TrInitiatorCode', 0, 'PaymentScheduled', 0, 'JsonData', data);

  IF uInvoice IS NOT NULL THEN
    payload := payload || jsonb_build_object('InvoiceId', uInvoice);
  END IF;

  RETURN CP_Fetch('/payments/tokens' || vPayType, 'POST', payload, data);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CP_Confirm ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CP_Confirm
 * @param {uuid} pPayment - Payment
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CP_Confirm (
  pPayment      uuid
) RETURNS       uuid
AS $$
DECLARE
  uCard         uuid;
  uClient       uuid;

  vPaymentId    text;

  nAmount       numeric;

  payload       jsonb;
  data          jsonb;
BEGIN
  SELECT client, card, payment_id, amount INTO uClient, uCard, vPaymentId, nAmount FROM db.payment WHERE id = pPayment;

  IF vPaymentId IS NULL THEN
    PERFORM WriteToEventLog('W', 2000, 'CP_Confirm', 'Payment Id cannot be empty.', pPayment);
    RETURN null;
  END IF;

  data := jsonb_build_object('client', uClient, 'card', uCard, 'order', pPayment);
  payload := jsonb_build_object('TransactionId', vPaymentId, 'Amount', to_char(nAmount, 'FM999999999990.00'), 'JsonData', data);

  RETURN CP_Fetch('/payments/confirm', 'POST', payload, data);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CP_Cancel ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CP_Cancel
 * @param {uuid} pPayment - Payment
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CP_Cancel (
  pPayment      uuid
) RETURNS       uuid
AS $$
DECLARE
  uCard         uuid;
  uClient       uuid;

  vPaymentId    text;

  nAmount       numeric;

  payload       jsonb;
  data          jsonb;
BEGIN
  SELECT client, card, payment_id, amount INTO uClient, uCard, vPaymentId, nAmount FROM db.payment WHERE id = pPayment;

  IF vPaymentId IS NULL THEN
    PERFORM WriteToEventLog('W', 2000, 'CP_Cancel', 'Payment Id cannot be empty.', pPayment);
    RETURN null;
  END IF;

  data := jsonb_build_object('client', uClient, 'card', uCard, 'order', pPayment);
  payload := jsonb_build_object('TransactionId', vPaymentId);

  RETURN CP_Fetch('/payments/void', 'POST', payload, data);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CP_Refund ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CP_Refund
 * @param {uuid} pPayment - Payment
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CP_Refund (
  pPayment      uuid
) RETURNS       uuid
AS $$
DECLARE
  uCard         uuid;
  uClient       uuid;

  vPaymentId    text;

  nAmount       numeric;

  payload       jsonb;
  data          jsonb;
BEGIN
  SELECT client, card, payment_id, amount INTO uClient, uCard, vPaymentId, nAmount FROM db.payment WHERE id = pPayment;

  IF vPaymentId IS NULL THEN
    PERFORM WriteToEventLog('W', 2000, 'CP_Refund', 'Payment Id cannot be empty.', pPayment);
    RETURN null;
  END IF;

  data := jsonb_build_object('client', uClient, 'card', uCard, 'order', pPayment);
  payload := jsonb_build_object('TransactionId', vPaymentId, 'Amount', to_char(nAmount, 'FM999999999990.00'), 'JsonData', data);

  RETURN CP_Fetch('/payments/refund', 'POST', payload, data);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CP_Get -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CP_Get
 * @param {uuid} pPayment - Payment
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CP_Get (
  pPayment      uuid
) RETURNS       uuid
AS $$
DECLARE
  uCard         uuid;
  uClient       uuid;

  vPaymentId    text;

  nAmount       numeric;

  payload       jsonb;
  data          jsonb;
BEGIN
  SELECT client, card, payment_id, amount INTO uClient, uCard, vPaymentId, nAmount FROM db.payment WHERE id = pPayment;

  IF vPaymentId IS NULL THEN
    PERFORM WriteToEventLog('W', 2000, 'CP_Get', 'Payment Id cannot be empty.', pPayment);
    RETURN null;
  END IF;

  data := jsonb_build_object('client', uClient, 'card', uCard, 'order', pPayment);
  payload := jsonb_build_object('TransactionId', vPaymentId);

  RETURN CP_Fetch('/payments/get', 'POST', payload, data);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CP_Kkt -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CP_Kkt
 * @param {uuid} pInvoice - Invoice
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CP_Kkt (
  pInvoice      uuid
) RETURNS       uuid
AS $$
DECLARE
  payload       jsonb;
  data          jsonb;
BEGIN
  data := jsonb_build_object('invoice', pInvoice);
  payload := CreateCloudPaymentContent(pInvoice);

  RETURN CP_Fetch('/kkt/receipt', 'POST', payload, data);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
