--------------------------------------------------------------------------------
-- PAYMENT ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.payment -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.payment
AS
  SELECT * FROM ObjectPayment;

GRANT SELECT ON api.payment TO administrator;

--------------------------------------------------------------------------------
-- api.add_payment -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Adds a new payment
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {numeric} pAmount - Amount
 * @param {text} pDescription - Description
 * @param {uuid} pCard - Card identifier
 * @param {uuid} pInvoice - Account identifier
 * @param {uuid} pPayment - Order identifier
 * @param {text} pCode - Code
 * @param {text} pPaymentId - Payment identifier
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_payment (
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
  vPaySystem    text;
BEGIN
  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  RETURN CreatePayment(pParent, coalesce(pType, GetType('payment.' || vPaySystem)), pClient, pCurrency, pAmount, pDescription, pCard, pInvoice, pOrder, pCode, pPaymentId, pMetadata);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_payment ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing payment
 * @param {uuid} pId - Payment identifier
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
CREATE OR REPLACE FUNCTION api.update_payment (
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
BEGIN
  pId := coalesce(pId, GetPayment(pCode));

  PERFORM FROM db.payment WHERE id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('payment', 'id', pId);
  END IF;

  PERFORM EditPayment(pId, pParent, pType, pClient, pCurrency, pAmount, pDescription, pCard, pInvoice, pOrder, pCode, pPaymentId, pMetadata);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_payment -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a payment (upsert)
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {numeric} pAmount - Amount
 * @param {text} pDescription - Description
 * @param {uuid} pCard - Card identifier
 * @param {uuid} pInvoice - Invoice
 * @param {uuid} pOrder - Order
 * @param {text} pCode - Code
 * @param {text} pPaymentId - PaymentId
 * @param {jsonb} pMetadata - Metadata
 * @return {SETOF api.payment}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_payment (
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
) RETURNS       SETOF api.payment
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_payment(pParent, pType, pClient, pCurrency, pAmount, pDescription, pCard, pInvoice, pOrder, pCode, pPaymentId, pMetadata);
  ELSE
    PERFORM api.update_payment(pId, pParent, pType, pClient, pCurrency, pAmount, pDescription, pCard, pInvoice, pOrder, pCode, pPaymentId, pMetadata);
  END IF;

  RETURN QUERY SELECT * FROM api.payment WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_payment -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a payment by identifier
 * @param {uuid} pId - Identifier
 * @return {api.payment} - Payment record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_payment (
  pId        uuid
) RETURNS    SETOF api.payment
AS $$
  SELECT * FROM api.payment WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_payment -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of payment records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_payment (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'payment', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_payment ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a filtered/sorted list of payment records
 * @param {jsonb} pSearch - Search conditions array
 * @param {jsonb} pFilter - Filter object
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.payment} - List of payment records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_payment (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.payment
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'payment', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.check_payment -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Checks payments for processing
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.check_payment (
  pOffTime      interval DEFAULT '2 min'
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
       AND t.metadata IS NOT NULL
       AND o.pdate < Now() - pOffTime
  LOOP
	SELECT * INTO m FROM jsonb_to_record(r.metadata) AS x(remote_start_transaction jsonb);

	IF m.remote_start_transaction IS NOT NULL THEN
	  SELECT * INTO s FROM jsonb_to_record(m.remote_start_transaction) AS x(connector uuid);

	  PERFORM FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid WHERE t.client = r.client AND t.connector = s.connector;

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
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
