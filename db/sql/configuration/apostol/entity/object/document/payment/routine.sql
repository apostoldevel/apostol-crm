--------------------------------------------------------------------------------
-- CreatePayment ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new payment
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {numeric} pAmount - Amount
 * @param {text} pDescription - Description
 * @param {uuid} pCard - Card identifier
 * @param {uuid} pInvoice - Account identifier
 * @param {uuid} pOrder - Order identifier
 * @param {text} pCode - Code
 * @param {text} pPaymentId - Payment identifier
 * @return {uuid} - Id
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreatePayment (
  pParent       uuid,
  pType         uuid,
  pClient       uuid,
  pCurrency     uuid,
  pAmount       numeric,
  pDescription  text default null,
  pCard         uuid default null,
  pInvoice      uuid default null,
  pOrder        uuid default null,
  pCode         text default null,
  pPaymentId    text default null,
  pMetadata     jsonb default null
) RETURNS       uuid
AS $$
DECLARE
  uPayment      uuid;
  uDocument     uuid;

  uClass        uuid;
  uMethod       uuid;
BEGIN
  pCurrency := coalesce(pCurrency, DefaultCurrency());

  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'payment' THEN
    PERFORM IncorrectClassType();
  END IF;

  PERFORM FROM db.payment WHERE code = pCode;
  IF FOUND THEN
    PERFORM PaymentCodeExists(pCode);
  END IF;

  PERFORM FROM db.currency WHERE id = pCurrency;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('currency', 'id', pCurrency);
  END IF;

  PERFORM FROM db.client WHERE id = pClient;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('client', 'id', pClient);
  END IF;

  IF pCard IS NOT NULL THEN
    PERFORM FROM db.card WHERE id = pCard;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('card', 'id', pCard);
    END IF;
  END IF;

  IF GetTypeCode(pType) = 'invoice.payment' THEN
    PERFORM FROM db.invoice WHERE id = pInvoice;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('invoice', 'id', pInvoice);
    END IF;
  END IF;

  IF pOrder IS NOT NULL THEN
    PERFORM FROM db.order WHERE id = pOrder;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('order', 'id', pOrder);
    END IF;
  END IF;

  uDocument := CreateDocument(pParent, pType, pCode, pDescription);

  INSERT INTO db.payment (id, document, currency, client, card, invoice, "order", amount, code, payment_id, metadata)
  VALUES (uDocument, uDocument, pCurrency, pClient, pCard, pInvoice, pOrder, pAmount, pCode, pPaymentId, pMetadata)
  RETURNING id INTO uPayment;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uPayment, uMethod);

  RETURN uPayment;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditPayment -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Edits an existing payment
 * @param {uuid} pId - Object reference
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {numeric} pAmount - Amount
 * @param {text} pDescription - Description
 * @param {uuid} pCard - Card identifier
 * @param {uuid} pInvoice - Account identifier
 * @param {uuid} pOrder - Order identifier
 * @param {text} pCode - Code
 * @param {text} pPaymentId - Payment identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditPayment (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pClient       uuid default null,
  pCurrency     uuid default null,
  pAmount       numeric default null,
  pDescription  text default null,
  pCard         uuid default null,
  pInvoice      uuid default null,
  pOrder        uuid default null,
  pCode         text default null,
  pPaymentId    text default null,
  pMetadata     jsonb default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;

  -- current
  cCode         text;
BEGIN
  SELECT code INTO cCode FROM db.payment WHERE id = pId;

  pCode := coalesce(pCode, cCode);

  IF pCode <> cCode THEN
    PERFORM FROM db.payment WHERE code = pCode;
    IF FOUND THEN
      PERFORM PaymentCodeExists(pCode);
    END IF;
  END IF;

  IF pClient IS NOT NULL THEN
    PERFORM FROM db.client WHERE id = pClient;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('client', 'id', pClient);
    END IF;
  END IF;

  IF pCard IS NOT NULL THEN
    PERFORM FROM db.card WHERE id = pCard;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('card', 'id', pCard);
    END IF;
  END IF;

  IF pInvoice IS NOT NULL THEN
    PERFORM FROM db.invoice WHERE id = pInvoice;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('invoice', 'id', pInvoice);
    END IF;
  END IF;

  IF pOrder IS NOT NULL THEN
    PERFORM FROM db.order WHERE id = pOrder;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('order', 'id', pOrder);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pCode, pDescription);

  UPDATE db.payment
     SET currency = coalesce(pCurrency, currency),
         client = coalesce(pClient, client),
         card = CheckNull(coalesce(pCard, card, null_uuid())),
         invoice = CheckNull(coalesce(pInvoice, invoice, null_uuid())),
         "order" = CheckNull(coalesce(pOrder, "order", null_uuid())),
         amount = coalesce(pAmount, amount),
         code = coalesce(pCode, code),
         payment_id = CheckNull(coalesce(pPaymentId, payment_id, null_uuid())),
         metadata = CheckNull(coalesce(pMetadata, metadata, jsonb_build_object()))
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));

  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetPayment ------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the payment by code
 * @param {text} pCode - Code
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetPayment (
  pCode         text
) RETURNS       uuid
AS $$
  SELECT id FROM db.payment WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetPaymentCode --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the payment code by identifier
 * @param {uuid} pPayment - Payment
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetPaymentCode (
  pPayment      uuid
) RETURNS       text
AS $$
  SELECT code FROM db.payment WHERE id = pPayment;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetPaymentAmount ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the payment by code
 * @param {uuid} pPayment - Payment
 * @return {numeric}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetPaymentAmount (
  pPayment      uuid
) RETURNS       numeric
AS $$
  SELECT amount FROM db.payment WHERE id = pPayment;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CreateValidationPayment --------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new payment
 * @param {uuid} pCard - Card identifier
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateValidationPayment (
  pCard         uuid,
  pDescription  text DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  uClient       uuid;
  uCurrency     uuid;

  vPaySystem    text;
BEGIN
  SELECT client INTO uClient FROM db.card WHERE id = pCard;

  uCurrency := DefaultCurrency();
  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  RETURN CreatePayment(pCard, GetType('validation.' || vPaySystem), uClient, uCurrency, 1, pDescription, pCard);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CreateNoPaymentOrder -----------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new payment
 * @param {uuid} pCard - Card identifier
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateNoPaymentOrder (
  pCard         uuid,
  pDescription  text DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  uClient       uuid;
  uCurrency     uuid;

  vPaySystem    text;
BEGIN
  SELECT client INTO uClient FROM db.card WHERE id = pCard;

  uCurrency := DefaultCurrency();
  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  RETURN CreatePayment(pCard, GetType('card.' || vPaySystem), uClient, uCurrency, 0, pDescription, pCard);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CreatePaymentOrder -------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new payment
 * @param {uuid} pCard - Card identifier
 * @param {numeric} pAmount - Amount
 * @param {uuid} pInvoice - Invoice
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreatePaymentOrder (
  pCard         uuid,
  pAmount       numeric,
  pInvoice      uuid DEFAULT null,
  pDescription  text DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  uClient       uuid;
  uCurrency     uuid;

  vPaySystem    text;
BEGIN
  SELECT client INTO uClient FROM db.card WHERE id = pCard;

  uCurrency := DefaultCurrency();
  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  RETURN CreatePayment(pCard, GetType('card.' || vPaySystem), uClient, uCurrency, pAmount, pDescription, pCard, pInvoice);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CreditingPayment ---------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CreditingPayment
 * @param {uuid} pPayment - Payment
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreditingPayment (
  pPayment      uuid
) RETURNS       uuid
AS $$
DECLARE
  r             record;

  uOrder        uuid;
  uDebit        uuid;
  uCredit       uuid;

  vCode          text;
  vCurrency     text;
BEGIN
  SELECT client, currency, invoice, amount INTO r FROM db.payment WHERE id = pPayment;

  vCurrency := GetCurrencyCode(r.currency);
  vCode := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentCompany', 'Code');

  uDebit := GetClientAccount(GetClient(vCode), r.currency, '000');

  IF uDebit IS NULL THEN
    RAISE EXCEPTION 'ERR-40000: Debit account in currency "%" not found.', vCurrency;
  END IF;

  uCredit := GetClientAccount(r.client, r.currency, '100');

  IF uCredit IS NULL THEN
    RAISE EXCEPTION 'ERR-40000: Credit account in currency "%" not found.', vCurrency;
  END IF;

  uOrder := InternalPayment(pPayment, uDebit, uCredit, r.amount, GetObjectLabel(pPayment), GetDocumentDescription(pPayment));

  UPDATE db.payment SET "order" = uOrder WHERE id = pPayment;

  PERFORM DoDisable(uOrder);

  RETURN uOrder;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION ZeroPayment --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief ZeroPayment
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION ZeroPayment (
  pClient       uuid,
  pCurrency     uuid,
  pLabel        text DEFAULT null,
  pDescription  text DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  uOrder        uuid;
  uDebit        uuid;
  uCredit       uuid;

  nAmount       numeric;

  vCode          text;
  vCurrency     text;
BEGIN
  vCurrency := GetCurrencyCode(pCurrency);
  vCode := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentCompany', 'Code');

  uDebit := GetClientAccount(pClient, pCurrency, '000');

  IF uDebit IS NULL THEN
    RAISE EXCEPTION 'ERR-40000: Debit account in currency "%" not found.', vCurrency;
  END IF;

  uCredit := GetClientAccount(GetClient(vCode), pCurrency, '000');

  IF uCredit IS NULL THEN
    RAISE EXCEPTION 'ERR-40000: Credit account in currency "%" not found.', vCurrency;
  END IF;

  nAmount := coalesce(GetBalance(uDebit), 0);

  IF nAmount > 0 THEN
    uOrder := InternalPayment(pClient, uDebit, uCredit, GetBalance(uDebit), pLabel, pDescription);
    PERFORM DoDisable(uOrder);
  END IF;

  RETURN uOrder;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetPaymentReservationSum -------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the payment by code
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCard - Card identifier
 * @return {numeric}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetPaymentReservationSum (
  pClient       uuid,
  pCard         uuid
) RETURNS       numeric
AS $$
DECLARE
  uState        uuid;
  uCurrency     uuid;

  nSum          numeric;

  vPaySystem    text;
BEGIN
  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  uCurrency := DefaultCurrency();
  uState := GetState(GetClass(vPaySystem), 'waiting_for_capture');

  SELECT Sum(amount) INTO nSum
    FROM db.payment t INNER JOIN db.object o ON o.id = t.document
   WHERE t.client = pClient
     AND t.card = pCard
     AND t.currency = uCurrency
     AND o.state = uState;

  RETURN nSum;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetPaymentPaidSum --------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the payment by code
 * @param {uuid} pInvoice - Invoice
 * @return {numeric}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetPaymentPaidSum (
  pInvoice      uuid
) RETURNS       numeric
AS $$
DECLARE
  uState        uuid;
  uCurrency     uuid;

  nSum          numeric;

  vPaySystem    text;
BEGIN
  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  uCurrency := DefaultCurrency();
  uState := GetState(GetClass(vPaySystem), 'succeeded');

  SELECT Sum(amount) INTO nSum
    FROM db.payment t INNER JOIN db.object o ON o.id = t.document
   WHERE t.invoice = pInvoice
     AND t.currency = uCurrency
     AND o.state = uState;

  RETURN nSum;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION ConfirmPaymentReservation ------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief ConfirmPaymentReservation
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCard - Card identifier
 * @param {uuid} pInvoice - Invoice
 * @param {numeric} pAmount - Amount
 * @param {text} pDescription - Description
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION ConfirmPaymentReservation (
  pClient       uuid,
  pCard         uuid,
  pInvoice      uuid,
  pAmount       numeric,
  pDescription  text DEFAULT null
) RETURNS       void
AS $$
DECLARE
  r             record;

  uState        uuid;
  uCurrency     uuid;

  vPaySystem    text;
BEGIN
  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  uCurrency := DefaultCurrency();
  uState := GetState(GetClass(vPaySystem), 'waiting_for_capture');

  FOR r IN
    SELECT t.id, t.amount
      FROM db.payment t INNER JOIN db.object o ON o.id = t.document
     WHERE t.client = pClient
       AND t.card = pCard
       AND t.currency = uCurrency
       AND o.state = uState
     ORDER BY t.amount
  LOOP
    IF r.amount > pAmount THEN
      UPDATE db.payment SET invoice = coalesce(pInvoice, invoice), amount = pAmount WHERE id = r.id;
      pAmount := 0;
    ELSE
      UPDATE db.payment SET invoice = coalesce(pInvoice, invoice) WHERE id = r.id;
      pAmount := pAmount - r.amount;
    END IF;

    PERFORM EditDocumentText(r.id, pDescription, current_locale());

    PERFORM DoAction(r.id, 'confirm');

    EXIT WHEN pAmount = 0;
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CancelPaymentReservation -------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CancelPaymentReservation
 * @param {uuid} pClient - Client identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CancelPaymentReservation (
  pClient       uuid
) RETURNS       void
AS $$
DECLARE
  r             record;

  uState        uuid;
  uCurrency     uuid;

  vPaySystem    text;
BEGIN
  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  uCurrency := DefaultCurrency();
  uState := GetState(GetClass(vPaySystem), 'waiting_for_capture');

  FOR r IN
    SELECT t.id
      FROM db.payment t INNER JOIN db.object o ON o.id = t.document
     WHERE t.client = pClient
       AND t.currency = uCurrency
       AND t.invoice IS NULL
       AND o.state = uState
  LOOP
    PERFORM DoAction(r.id, 'cancel');
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION UpdatePaymentReservationData ---------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief UpdatePaymentReservationData
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCard - Card identifier
 * @param {jsonb} pMetaData - MetaData
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION UpdatePaymentReservationData (
  pClient       uuid,
  pCard         uuid,
  pMetaData     jsonb
) RETURNS       void
AS $$
DECLARE
  r             record;

  uState        uuid;
  uCurrency     uuid;

  vPaySystem    text;
BEGIN
  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  uCurrency := DefaultCurrency();
  uState := GetState(GetClass(vPaySystem), 'waiting_for_capture');

  FOR r IN
    SELECT t.id
      FROM db.payment t INNER JOIN db.object o ON o.id = t.document
     WHERE t.client = pClient
       AND t.card = pCard
       AND t.currency = uCurrency
       AND o.state = uState
  LOOP
    UPDATE db.payment SET metadata = pMetaData WHERE id = r.id;
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CheckPaymentReservation --------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief CheckPaymentReservation
 * @param {uuid} pConnector - Connector
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CheckPaymentReservation (
  pConnector    uuid
) RETURNS       void
AS $$
DECLARE
  r             record;
  m             record;
  s             record;

  uState        uuid;
  uCurrency     uuid;

  vPaySystem    text;
  vMessage      text;
  vContext      text;
BEGIN
  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  uCurrency := DefaultCurrency();
  uState := GetState(GetClass(vPaySystem), 'waiting_for_capture');

  FOR r IN
    SELECT t.id, t.client, t.metadata
      FROM db.payment t INNER JOIN db.object o ON o.id = t.document
     WHERE t.currency = uCurrency
       AND t.invoice IS NULL
       AND o.state = uState
  LOOP
    IF r.metadata IS NOT NULL THEN
      SELECT * INTO m FROM jsonb_to_record(r.metadata) AS x(remote_start_transaction jsonb);
      IF m.remote_start_transaction IS NOT NULL THEN
        SELECT * INTO s FROM jsonb_to_record(m.remote_start_transaction) AS x(connector uuid);
        IF s.connector = pConnector THEN
          PERFORM FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid WHERE t.client = r.client AND t.connector = pConnector;
          IF NOT FOUND THEN
            BEGIN
              PERFORM DoAction(r.id, 'cancel');
            EXCEPTION
            WHEN others THEN
              GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
              PERFORM WriteDiagnostics(vMessage, vContext);
            END;
          END IF;
        END IF;
      END IF;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
