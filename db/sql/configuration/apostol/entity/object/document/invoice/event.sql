--------------------------------------------------------------------------------
-- INVOICE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventInvoiceCreate ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the invoice creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventInvoiceCreate (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Invoice created.', pObject);

  IF GetObjectTypeCode(pObject) = 'top-up.invoice' THEN
    PERFORM DoEnable(pObject);
  END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceOpen ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the invoice open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventInvoiceOpen (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Invoice opened.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceEdit ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the invoice edit event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventInvoiceEdit (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Invoice modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceSave ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the invoice save event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventInvoiceSave (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Invoice saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceEnable ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the invoice enable event
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventInvoiceEnable (
  pObject       uuid default context_object(),
  pParams       jsonb default context_params()
) RETURNS       void
AS $$
DECLARE
  r             record;
  i             record;

  uType         uuid;
  uCard         uuid;
  uParent       uuid;
  uPayment      uuid;
  uAccount      uuid;

  vTypeCode     text;
  vPaySystem    text;
  vDescription  text;

  uCardList     uuid[];
  jHashList     jsonb;

  nIndex        integer;

  nAmount       numeric;
  nPaidSum      numeric;
  nReserveSum   numeric;

  clear_hash    boolean DEFAULT true;

  dtCreated     timestamptz;
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Invoice submitted for payment.', pObject);

  SELECT code, client, currency, amount INTO i FROM db.invoice WHERE id = pObject;
  SELECT parent, pdate INTO uParent, dtCreated FROM db.object WHERE id = pObject;

  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');
  uType := GetType('payment.' || vPaySystem);

  vTypeCode := GetObjectTypeCode(pObject);

  IF vTypeCode = 'payment.invoice' THEN
    uAccount := GetClientAccount(i.client, i.currency, '100');
    nAmount := coalesce(GetBalance(uAccount), 0.00);

    IF nAmount >= i.amount THEN
      PERFORM CancelPaymentReservation(i.client);
      PERFORM DoAction(pObject, 'disable');
      RETURN;
    END IF;

    vDescription := format('Оплата услуг по счёту № %s от %s.', i.code, DateToStr(dtCreated, 'DD.MM.YYYY'));
  ELSIF vTypeCode = 'top-up.invoice' THEN
    vDescription := format('Пополнение счёта. Счёт № %s от %s.', i.code, DateToStr(dtCreated, 'DD.MM.YYYY'));

    uPayment := CreatePayment(pObject, uType, i.client, i.currency, i.amount, vDescription, pInvoice => pObject, pMetadata => pParams);

    --PERFORM DoAction(uPayment, 'pay', pParams);
    RETURN;
  ELSE
    PERFORM UnsupportedInvoiceType();
  END IF;

  IF pParams IS NOT NULL THEN
    clear_hash := coalesce((pParams->'clear_hash')::bool, clear_hash);
  END IF;

  IF clear_hash THEN
    PERFORM SetObjectDataJSON(pObject, 'hash_list', null);
  END IF;

  uType := GetType('credit.card');

  FOR r IN SELECT c.id FROM db.card c INNER JOIN db.object o ON c.document = o.id WHERE c.client = i.client AND o.type = uType AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid AND c.binding IS NOT NULL ORDER BY c.sequence
  LOOP
    uCardList := array_append(uCardList, r.id);
  END LOOP;

  IF uCardList IS NULL THEN
    PERFORM SetObjectDataJSON(pObject, 'params', '{"auto_payment": false}');
    PERFORM EditDocument(pObject, pDescription => format('Оплата невозможна: Список привязанных карт пуст. Проверка отложена до %s.', Now() + interval '1 day'));
    PERFORM DoAction(pObject, 'fail');

    RETURN;
  END IF;

  jHashList := coalesce(GetObjectDataJSON(pObject, 'hash_list')::jsonb, '[]'::jsonb);

  nIndex := 1;
  uCard := uCardList[nIndex];

  WHILE uCard IS NOT NULL AND jHashList ? uCard::text
  LOOP
    nIndex := nIndex + 1;
    uCard := uCardList[nIndex];
  END LOOP;

  IF uCard IS NULL THEN
    PERFORM SetObjectDataJSON(pObject, 'params', '{"auto_payment": false}');
    PERFORM EditDocument(pObject, pDescription => format('Автоплатеж по данному счету отключен до %s.', Now() + interval '1 day'));
    PERFORM DoAction(pObject, 'fail');
  ELSE
    PERFORM SetObjectDataJSON(pObject, 'params', '{"auto_payment": true}');

    jHashList := jHashList || jsonb_build_array(uCard);
    PERFORM SetObjectDataJSON(pObject, 'hash_list', jHashList::json);

    nPaidSum := 0;
    nReserveSum := 0;

    IF vTypeCode = 'payment.invoice' THEN
      IF nAmount > 0 THEN
        PERFORM ServicePayment(pObject, i.client, i.currency, nAmount, GetObjectLabel(pObject), vDescription);
        i.amount := i.amount - nAmount;
      END IF;

      nPaidSum := coalesce(GetPaymentPaidSum(pObject), 0);
      nReserveSum := coalesce(GetPaymentReservationSum(i.client, uCard), 0);
    END IF;

    IF i.amount > (nPaidSum + nReserveSum) THEN
      IF nReserveSum > 0 THEN
        PERFORM ConfirmPaymentReservation(i.client, uCard, pObject, nReserveSum, vDescription);
      END IF;

      uPayment := CreatePayment(pObject, uType, i.client, i.currency, i.amount - (nPaidSum + nReserveSum), vDescription, uCard, pObject);
    ELSE
      IF nReserveSum > 0 THEN
        PERFORM ConfirmPaymentReservation(i.client, uCard, pObject, i.amount - nPaidSum, vDescription);
      END IF;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- EventInvoiceDisable ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the invoice disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventInvoiceDisable (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  r             record;

  nAmount       numeric;
BEGIN
  IF GetObjectTypeCode(pObject) = 'payment.invoice' THEN
    SELECT client, currency, amount INTO r FROM db.invoice WHERE id = pObject;

    SELECT Sum(amount) INTO nAmount
      FROM db."order" t INNER JOIN db.object o ON t.document = o.id
     WHERE o.parent = pObject
       AND o.state_type = '00000000-0000-4000-b001-000000000003'::uuid;

    nAmount := coalesce(nAmount, 0);

    IF r.amount - nAmount > 0 THEN
      PERFORM ServicePayment(pObject, r.client, r.currency, r.amount - nAmount, GetObjectLabel(pObject), GetDocumentDescription(pObject));
    END IF;
  END IF;

  PERFORM EditDocumentText(pObject, '', current_locale());

  PERFORM WriteToEventLog('M', 1000, 'disable', 'Invoice paid.', pObject);
END;
$$ LANGUAGE plpgsql
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- EventInvoiceCancel ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the invoice cancel event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventInvoiceCancel (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  r             record;
BEGIN
  FOR r IN
    SELECT t.id
      FROM db.order t INNER JOIN db.object o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
     WHERE o.parent = pObject
  LOOP
    PERFORM ExecuteObjectAction(r.id, context_action());
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'cancel', 'Invoice cancelled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceFail ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the invoice fail event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventInvoiceFail (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'fail', 'Operation execution failure.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceClose -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the invoice close event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventInvoiceClose (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'close', 'Invoice disabled.', pObject);
END;
$$ LANGUAGE plpgsql
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- EventInvoiceDelete ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the invoice delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventInvoiceDelete (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  IF IsEnabled(pObject) THEN
    PERFORM EditDocumentText(pObject, '', current_locale());
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'delete', 'Invoice deleted.', pObject);
END;
$$ LANGUAGE plpgsql
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- EventInvoiceRestore ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the invoice restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventInvoiceRestore (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Invoice restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceDrop ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the invoice drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventInvoiceDrop (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  r             record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.invoice WHERE id = pObject;

  PERFORM WriteToEventLog('M', 2000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Invoice dropped.');
END;
$$ LANGUAGE plpgsql;
