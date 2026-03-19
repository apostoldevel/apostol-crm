--------------------------------------------------------------------------------
-- FUNCTION YK_Error -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief YK_Error
 * @param {uuid} pObject - Object identifier
 * @param {int} pCode - Code
 * @param {text} pEvent - Event
 * @param {text} pText - Text content
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION YK_Error (
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
-- FUNCTION YK_Fetch -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief YK_Fetch
 * @param {text} pResource - Resource
 * @param {text} pMethod - Method
 * @param {text} pCommand - Command
 * @param {jsonb} pPayload - JSON request payload
 * @param {jsonb} pData - Additional data
 * @param {text} pMessage - Message text
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION YK_Fetch (
  pResource     text,
  pMethod       text,
  pCommand      text,
  pPayload      jsonb,
  pData         jsonb DEFAULT null,
  pMessage      text DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  headers       jsonb;

  uKey          uuid;

  vAPI          text;
  vShopId       text;
  vShopKey      text;
  vUserAgent    text;

  content       bytea;
BEGIN
  uKey := gen_random_uuid();

  vAPI := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Service\YooKassa\API', 'URL');
  vShopId := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Service\YooKassa\Shop', 'Id');
  vShopKey := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Service\YooKassa\Shop', 'Key');
  vUserAgent := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Name');

  pData := coalesce(pData, jsonb_build_object()) || jsonb_build_object('session', current_session(), 'user_id', current_userid(), 'idempotence_key', uKey);

  headers := jsonb_build_object('User-Agent', coalesce(vUserAgent, 'OCPP CSS'), 'Accept', 'application/json', 'Content-Type', 'application/json');
  headers := headers || jsonb_build_object('Authorization', 'Basic ' || encode(convert_to(vShopId || ':' || vShopKey, 'utf8'), 'base64'));
  headers := headers || jsonb_build_object('Idempotence-Key', uKey);

  IF SubStr(vShopKey, 1, 4) = 'test' THEN
    pPayload := pPayload || jsonb_build_object('test', true);
  END IF;

  content := convert_to(jsonb_pretty(pPayload), 'utf8');

  RETURN http.fetch(vAPI || pResource, pMethod, headers, content, 'api.yookassa_done', 'api.yookassa_fail', 'yookassa', vShopId, pCommand, pMessage, 'curl', pData);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION YK_CreateBindingPayment --------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief YK_CreateBindingPayment
 * @param {uuid} pCard - Card identifier
 * @param {text} pPAN - PAN
 * @param {date} pExpiry - Expiry date
 * @param {text} pHolderName - HolderName
 * @param {text} pCVC - CVC
 * @param {text} pLabel - Label
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION YK_CreateBindingPayment (
  pCard         uuid,
  pPAN          text,
  pExpiry       date,
  pHolderName   text,
  pCVC          text DEFAULT null,
  pLabel        text DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  uPayment      uuid;

  method        jsonb;
BEGIN
  uPayment := CreateValidationPayment(pCard, coalesce(pLabel, 'Card validation.'));

  method := jsonb_build_object('type', 'bank_card', 'card', jsonb_build_object('number', pPAN, 'cardholder', pHolderName, 'expiry_month', DateToStr(pExpiry, 'MM'), 'expiry_year', DateToStr(pExpiry, 'YYYY'), 'csc', pCVC));

  RETURN YK_CreatePayment(uPayment, null, false, true, method);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION YK_CreatePayment ---------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief YK_CreatePayment
 * @param {uuid} pPayment - Payment
 * @param {text} pReturnUrl - ReturnUrl
 * @param {boolean} pCapture - Capture
 * @param {boolean} pRefund - Refund
 * @param {jsonb} pMethod - Method
 * @param {jsonb} pMetadata - Metadata
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION YK_CreatePayment (
  pPayment      uuid,
  pReturnUrl    text DEFAULT null,
  pCapture      boolean DEFAULT null,
  pRefund       boolean DEFAULT null,
  pMethod       jsonb DEFAULT null,
  pMetadata     jsonb DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  r             record;
  p             record;
  c             record;

  vCode         text;
  vHost         text;
  vSMTP         text;
  vDomain       text;
  vBinding      text;
  vCurrency     text;
  vInvoiceType  text;
  vDescription  text;

  payload       jsonb;
  receipt       jsonb;
  customer      jsonb;
BEGIN
  SELECT id, client, card, invoice, currency, code, amount INTO p FROM db.payment WHERE id = pPayment;
  SELECT id, currency, code, amount, 1 AS quantity, description INTO r FROM Price WHERE id = GetObjectParent(p.invoice);
  SELECT email, phone INTO c FROM db.client WHERE id = p.client;

  vHost := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Host');
  vCode := GetObjectTypeCode(pPayment);

  IF coalesce(nullif(r.amount, 0.00), p.amount) != p.amount THEN
    PERFORM IncorrectPaymentData();
  END IF;

  IF coalesce(r.currency, p.currency) != p.currency THEN
    PERFORM IncorrectPaymentData();
  END IF;

  vCurrency := GetCurrencyCode(p.currency);
  vDescription := coalesce(r.description, GetDocumentDescription(pPayment));

  IF vCode IN ('reserve.yookassa', 'validation.yookassa') THEN
    pCapture := false;
  END IF;

  payload := jsonb_build_object('amount', jsonb_build_object('value', to_char(p.amount, 'FM999999999990.00'), 'currency', vCurrency));
  payload := payload || jsonb_build_object('capture', coalesce(pCapture, true), 'refundable', coalesce(pRefund, true), 'description', vDescription);
  payload := payload || jsonb_build_object('metadata', jsonb_build_object('payment', pPayment));

  receipt := jsonb_build_object('tax_system_code', 2, 'items', jsonb_build_array(jsonb_build_object('description', vDescription, 'amount', jsonb_build_object('value', to_char(p.amount, 'FM999999999990.00'), 'currency', vCurrency), 'vat_code', 1, 'quantity', coalesce(r.quantity, 1), 'payment_subject', 'service', 'payment_mode', 'full_payment')));

  IF c.email IS NOT NULL THEN
	customer := coalesce(customer, jsonb_build_object()) || jsonb_build_object('email', c.email);
  ELSE
	vSMTP := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'SMTP');
	vDomain := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Domain');

	customer := coalesce(customer, jsonb_build_object()) || jsonb_build_object('email', format('support@%s', coalesce(vSMTP, vDomain)));
  END IF;

  IF c.phone IS NOT NULL THEN
	customer := coalesce(customer, jsonb_build_object()) || jsonb_build_object('phone', c.phone);
  END IF;

  IF customer IS NOT NULL THEN
	receipt := receipt || jsonb_build_object('customer', customer);
  END IF;

  payload := payload || jsonb_build_object('receipt', receipt);

  IF vCode = 'validation.yookassa' THEN
    payload := payload || jsonb_build_object('save_payment_method', true);
    payload := payload || jsonb_build_object('payment_method_data', pMethod);
    payload := payload || jsonb_build_object('confirmation', jsonb_build_object('type', 'redirect', 'enforce', false, 'locale', 'ru_RU', 'return_url', coalesce(pReturnUrl, vHost || '/api/v1/yookassa/' || p.code)));
  ELSE
    vInvoiceType := GetObjectTypeCode(p.invoice);

    IF vInvoiceType = 'payment.invoice' THEN
      SELECT binding INTO vBinding FROM db.card WHERE id = p.card;

      IF vBinding IS NULL THEN
	    RAISE EXCEPTION 'ERR-40000: The card % is not binding to a bank.', GetCardCode(p.card);
	  END IF;

      payload := payload || jsonb_build_object('payment_method_id', vBinding);
    ELSIF vInvoiceType = 'top-up.invoice' THEN
      payload := payload || jsonb_build_object('confirmation', jsonb_build_object('type', 'redirect', 'enforce', false, 'locale', 'ru_RU', 'return_url', coalesce(pReturnUrl, format('%s/payment/%s', vHost, p.id))));
    ELSE
      PERFORM UnsupportedInvoiceType();
    END IF;
  END IF;

  pMetadata := coalesce(pMetadata, jsonb_build_object()) || jsonb_build_object('client', p.client, 'card', p.card, 'payment', pPayment);

  RETURN YK_Fetch('/v3/payments', 'POST', '/payment/create', payload, pMetadata);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION YK_Capture ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief YK_Capture
 * @param {uuid} pPayment - Payment
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION YK_Capture (
  pPayment      uuid
) RETURNS       uuid
AS $$
DECLARE
  r             record;

  payload       jsonb;
BEGIN
  SELECT client, card, currency, amount, payment_id INTO r FROM db.payment WHERE id = pPayment;

  IF r.payment_id IS NULL THEN
    PERFORM WriteToEventLog('W', 2000, 'YK_Capture', 'Payment Id cannot be empty.', pPayment);
    RETURN null;
  END IF;

  payload := jsonb_build_object('amount', jsonb_build_object('value', to_char(r.amount, 'FM999999999990.00'), 'currency', GetCurrencyCode(r.currency)));

  RETURN YK_Fetch(format('/v3/payments/%s/capture', r.payment_id), 'POST', '/payment/capture', payload, jsonb_build_object('client', r.client, 'card', r.card, 'payment', pPayment));
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION YK_Cancel ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief YK_Cancel
 * @param {uuid} pPayment - Payment
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION YK_Cancel (
  pPayment      uuid
) RETURNS       uuid
AS $$
DECLARE
  uCard         uuid;
  uClient       uuid;
  uPaymentId    uuid;

  payload       jsonb;
BEGIN
  SELECT client, card, payment_id INTO uClient, uCard, uPaymentId FROM db.payment WHERE id = pPayment;

  IF uPaymentId IS NULL THEN
    PERFORM WriteToEventLog('W', 2000, 'YK_Cancel', 'Payment Id cannot be empty.', pPayment);
    RETURN null;
  END IF;

  payload := jsonb_build_object();

  RETURN YK_Fetch(format('/v3/payments/%s/cancel', uPaymentId), 'POST', '/payment/cancel', payload, jsonb_build_object('client', uClient, 'card', uCard, 'payment', pPayment));
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION YK_Refund ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief YK_Refund
 * @param {uuid} pPayment - Payment
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION YK_Refund (
  pPayment      uuid
) RETURNS       uuid
AS $$
DECLARE
  uCard         uuid;
  uClient       uuid;
  uPaymentId    uuid;
  uCurrency     uuid;

  nAmount       numeric;

  payload       jsonb;
BEGIN
  SELECT client, card, payment_id, currency, amount INTO uClient, uCard, uPaymentId, uCurrency, nAmount FROM db.payment WHERE id = pPayment;

  IF uPaymentId IS NULL THEN
    PERFORM WriteToEventLog('W', 2000, 'YK_Refund', 'Payment Id cannot be empty.', pPayment);
    RETURN null;
  END IF;

  payload := jsonb_build_object('amount', jsonb_build_object('value', to_char(nAmount, 'FM999999999990.00'), 'currency', GetCurrencyCode(uCurrency)));
  payload := payload || jsonb_build_object('payment_id', uPaymentId);

  RETURN YK_Fetch(format('/v3/refunds', uPaymentId), 'POST', '/payment/refund', payload, jsonb_build_object('client', uClient, 'card', uCard, 'payment', pPayment));
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION YK_Payment ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief YK_Payment
 * @param {uuid} pPayment - Payment
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION YK_Payment (
  pPayment      uuid
) RETURNS       uuid
AS $$
DECLARE
  uCard         uuid;
  uClient       uuid;
  uPaymentId    uuid;

  payload       jsonb;
BEGIN
  SELECT client, card, payment_id INTO uClient, uCard, uPaymentId FROM db.payment WHERE id = pPayment;

  IF uPaymentId IS NULL THEN
    PERFORM WriteToEventLog('W', 2000, 'YK_Payment', 'Payment Id cannot be empty.', pPayment);
    RETURN null;
  END IF;

  RETURN YK_Fetch(format('/v3/payments/%s', uPaymentId), 'GET', '/payment', payload, jsonb_build_object('client', uClient, 'card', uCard, 'payment', pPayment));
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
