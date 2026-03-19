--------------------------------------------------------------------------------
-- TRANSACTION -----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.transaction -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.transaction
AS
  SELECT * FROM ObjectTransaction;

GRANT SELECT ON api.transaction TO administrator;

--------------------------------------------------------------------------------
-- api.add_transaction ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Adds a new transaction
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
 * @param {numeric} pCost - Cost
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_transaction (
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
  pCost             numeric DEFAULT null,
  pCode             text DEFAULT null,
  pLabel            text DEFAULT null,
  pDescription      text DEFAULT null
) RETURNS           uuid
AS $$
BEGIN
  RETURN CreateTransaction(pParent, coalesce(pType, GetType('service.transaction')), pClient, pService, pCurrency, pOrder, pDevice, pTariff, pSubscription, pInvoice, pTransactionId, pPrice, pVolume, pAmount, pCommission, pCost, pCode, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_transaction ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Updates an existing transaction
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
 * @param {numeric} pCost - Cost
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {void}
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_transaction (
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
  pCost             numeric DEFAULT null,
  pCode             text DEFAULT null,
  pLabel            text DEFAULT null,
  pDescription      text DEFAULT null
) RETURNS           void
AS $$
BEGIN
  PERFORM FROM db.transaction WHERE id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('transaction', 'id', pId);
  END IF;

  PERFORM EditTransaction(pId, pParent, pType, pClient, pService, pCurrency, pOrder, pDevice, pTariff, pSubscription, pInvoice, pTransactionId, pPrice, pVolume, pAmount, pCommission, pCost, pCode, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_transaction ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a transaction (upsert)
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
 * @param {numeric} pCost - Cost
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {SETOF api.transaction}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_transaction (
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
  pCost             numeric DEFAULT null,
  pCode             text DEFAULT null,
  pLabel            text DEFAULT null,
  pDescription      text DEFAULT null
) RETURNS           SETOF api.transaction
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_transaction(pParent, pType, pClient, pService, pCurrency, pOrder, pDevice, pTariff, pSubscription, pInvoice, pTransactionId, pPrice, pVolume, pAmount, pCommission, pCost, pCode, pLabel, pDescription);
  ELSE
    PERFORM api.update_transaction(pId, pParent, pType, pClient, pService, pCurrency, pOrder, pDevice, pTariff, pSubscription, pInvoice, pTransactionId, pPrice, pVolume, pAmount, pCommission, pCost, pCode, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.transaction WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_transaction ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a transaction by identifier
 * @param {uuid} pId - Record identifier
 * @return {SETOF api.transaction}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_transaction (
  pId        uuid
) RETURNS    SETOF api.transaction
AS $$
  SELECT * FROM api.transaction WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_transaction -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of transaction records
 * @return {SETOF api.transaction}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_transaction (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'transaction', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_transaction --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a filtered/sorted list of transaction records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @param {jsonb} pFields - Fields
 * @return {SETOF api.transaction}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_transaction (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null,
  pFields   jsonb default null
) RETURNS   SETOF api.transaction
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'transaction', pSearch, pFilter, pLimit, pOffSet, pOrderBy, pFields);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
