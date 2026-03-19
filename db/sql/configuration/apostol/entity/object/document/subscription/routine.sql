--------------------------------------------------------------------------------
-- SUBSCRIPTION ----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CreateSubscription ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new subscription
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pPrice - Price
 * @param {uuid} pClient - Client identifier
 * @param {text} pCustomer - Customer
 * @param {text} pCode - Code
 * @param {timestamptz} pPeriodStart - PeriodStart
 * @param {timestamptz} pPeriodEnd - PeriodEnd
 * @param {jsonb} pMetaData - MetaData
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @throws IncorrectClassType
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateSubscription (
  pParent       uuid,
  pType         uuid,
  pPrice        uuid,
  pClient       uuid,
  pCustomer     text,
  pCode         text,
  pPeriodStart  timestamptz,
  pPeriodEnd    timestamptz,
  pMetaData     jsonb,
  pLabel        text,
  pDescription  text default null
) RETURNS       uuid
AS $$
DECLARE
  uDocument     uuid;

  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'subscription' THEN
    PERFORM IncorrectClassType();
  END IF;

  PERFORM FROM db.price WHERE id = pPrice;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('price', 'id', pPrice);
  END IF;

  uDocument := CreateDocument(pParent, pType, coalesce(pLabel, pCode), pDescription);

  INSERT INTO db.subscription (id, document, price, client, customer, code, period_start, period_end, metadata)
  VALUES (uDocument, uDocument, pPrice, pClient, pCustomer, pCode, pPeriodStart, pPeriodEnd, pMetaData);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uDocument, uMethod);

  RETURN uDocument;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditSubscription ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Edits an existing subscription
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pPrice - Price
 * @param {uuid} pClient - Client identifier
 * @param {text} pCustomer - Customer
 * @param {text} pCode - Code
 * @param {timestamptz} pPeriodStart - PeriodStart
 * @param {timestamptz} pPeriodEnd - PeriodEnd
 * @param {jsonb} pMetaData - MetaData
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {void}
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditSubscription (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pPrice        uuid default null,
  pClient       uuid default null,
  pCustomer     text default null,
  pCode         text default null,
  pPeriodStart  timestamptz default null,
  pPeriodEnd    timestamptz default null,
  pMetaData     jsonb default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;
BEGIN
  IF NULLIF(pClient, null_uuid()) IS NOT NULL THEN
    PERFORM FROM db.client WHERE id = pClient;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('client', 'id', pClient);
    END IF;
  END IF;

  IF pPrice IS NOT NULL THEN
    PERFORM FROM db.price WHERE id = pPrice;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('price', 'id', pPrice);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription, pDescription, current_locale());

  UPDATE db.subscription
     SET price = coalesce(pPrice, price),
         client = CheckNull(coalesce(pClient, client, null_uuid())),
         customer = coalesce(pCustomer, customer),
         code = coalesce(pCode, code),
         period_start = coalesce(pPeriodStart, period_start),
         period_end = coalesce(pPeriodEnd, period_end),
         metadata = coalesce(pMetaData, metadata)
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));

  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetSubscription -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the subscription by code
 * @param {text} pCode - Code
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetSubscription (
  pCode     text
) RETURNS   uuid
AS $$
  SELECT id FROM db.subscription WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetSubscriptionProductName --------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the subscription by code
 * @param {uuid} pSubscription - Subscription
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetSubscriptionProductName (
  pSubscription uuid
) RETURNS       text
AS $$
DECLARE
  uProduct      uuid;
  uPrice        uuid;

  vName         text;
BEGIN
  SELECT price INTO uPrice FROM db.subscription WHERE id = pSubscription;

  IF FOUND THEN
    SELECT product INTO uProduct FROM db.price WHERE id = uPrice;
    SELECT name INTO vName FROM db.product WHERE id = uProduct;
  END IF;

  RETURN vName;
END
  $$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- Replenishment ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Replenishment
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pCategory - Category identifier
 * @param {uuid} pClient - Client identifier
 * @param {numeric} pAmount - Amount
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION Replenishment (
  pParent       uuid,
  pCategory     uuid,
  pClient       uuid,
  pAmount       numeric
) RETURNS       void
AS $$
DECLARE
  uDebit        uuid;
  uCredit       uuid;

  uCurrency     uuid;

  uActive       uuid;
  uPassive      uuid;

  nBalance      numeric;

  vCategory     text;
BEGIN
  uActive := GetType('active.account');
  uPassive := GetType('passive.account');

  vCategory := GetCategoryCode(pCategory);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SubscriptionPaid ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief SubscriptionPaid
 * @param {uuid} pId - Record identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SubscriptionPaid (
  pId           uuid
) RETURNS       void
AS $$
DECLARE
  r             record;
  d             record;

  uProduct      uuid;

  nWords        numeric;
  nText         numeric;
  nMedia        numeric;
  nMonths       numeric;

  jData         jsonb;

  vName         text;
BEGIN
  SELECT price, client INTO r FROM db.subscription WHERE id = pId;

  IF FOUND AND r.client IS NOT NULL THEN
    SELECT product, metadata INTO uProduct, jData FROM db.price WHERE id = r.price;
    SELECT name INTO vName FROM db.product WHERE id = uProduct;

    SELECT * INTO d FROM jsonb_to_record(jData->'recurring') AS x(interval text);

    IF d.interval = 'year' THEN
      nMonths := 12;
	ELSE
      nMonths := 1;
	END IF;

    IF vName = 'Basic' THEN
      nWords := 40000 * nMonths;
      nText := 100 * nMonths;
      nMedia := 100 * nMonths;
    ELSIF vName = 'Standard' THEN
      nWords := 100000 * nMonths;
      nText := 999 * nMonths;
      nMedia := 400 * nMonths;
    ELSIF vName = 'Pro' THEN
      nWords := 1000000 * nMonths;
      nText := 999999 * nMonths;
      nMedia := 2000 * nMonths;
    ELSE
      nWords := 1000;
      nText := 5;
      nMedia := 3;
    END IF;

    PERFORM Replenishment(pId, GetCategory('chat.category'), r.client, nWords);
    PERFORM Replenishment(pId, GetCategory('text.category'), r.client, nText);
    PERFORM Replenishment(pId, GetCategory('media.category'), r.client, nMedia);

    UPDATE db.subscription SET current = true WHERE id = pId;
  END IF;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SubscriptionCancel ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief SubscriptionCanceled
 * @param {uuid} pId - Record identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SubscriptionCanceled (
  pId           uuid
) RETURNS       void
AS $$
DECLARE
  r             record;
  uClient       uuid;
BEGIN
  SELECT client INTO uClient FROM db.subscription WHERE id = pId;

  -- Cancel active transactions (those that fell out of generation cycles)
  FOR r IN
    SELECT t.id
      FROM db.transaction t INNER JOIN db.object o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
     WHERE t.client = uClient
  LOOP
    PERFORM ExecuteObjectAction(r.id, GetAction('cancel'));
  END LOOP;

  PERFORM Replenishment(pId, GetCategory('chat.category'), uClient, 0);
  PERFORM Replenishment(pId, GetCategory('text.category'), uClient, 0);
  PERFORM Replenishment(pId, GetCategory('media.category'), uClient, 0);

  UPDATE db.subscription SET current = false WHERE id = pId;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SubscriptionSwitch ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief SubscriptionSwitch
 * @param {uuid} pOld - Old
 * @param {uuid} pNew - Generate unique code if true
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SubscriptionSwitch (
  pOld          uuid,
  pNew          uuid
) RETURNS       void
AS $$
BEGIN
  PERFORM SubscriptionCanceled(pOld);
  PERFORM SubscriptionPaid(pNew);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCurrentSubscription ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the subscription by code
 * @param {uuid} pClient - Client identifier
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCurrentSubscription (
  pClient       uuid
) RETURNS       uuid
AS $$
  SELECT s.id
    FROM db.subscription s INNER JOIN db.object o ON s.document = o.id AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
   WHERE s.client = pClient
     AND s.current
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetSubscriptionJson ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns subscription data as JSON for the given client
 * @param {uuid} pClient - Client identifier
 * @return {json}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetSubscriptionJson (
  pClient       uuid
) RETURNS       json
AS $$
DECLARE
  arResult      json[];
  rec           record;
BEGIN
  FOR rec IN
    SELECT * FROM Subscription WHERE client = pClient AND statetype = '00000000-0000-4000-b001-000000000002'::uuid
  LOOP
    arResult := array_append(arResult, row_to_json(rec));
  END LOOP;

  RETURN array_to_json(arResult);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
