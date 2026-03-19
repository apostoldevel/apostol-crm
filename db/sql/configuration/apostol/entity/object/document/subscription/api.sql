--------------------------------------------------------------------------------
-- SUBSCRIPTION ----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.subscription ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.subscription
AS
  SELECT * FROM ObjectSubscription;

GRANT SELECT ON api.subscription TO administrator;

--------------------------------------------------------------------------------
-- api.add_subscription --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Adds a new subscription
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
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_subscription (
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
BEGIN
  RETURN CreateSubscription(pParent, coalesce(pType, GetType('charge_automatically.subscription')), pPrice, pClient, pCustomer, pCode, pPeriodStart, pPeriodEnd, pMetaData, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_subscription -----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Updates an existing subscription
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
CREATE OR REPLACE FUNCTION api.update_subscription (
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
BEGIN
  pId := coalesce(pId, GetSubscription(pCode));

  PERFORM FROM db.subscription c WHERE c.id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('subscription', 'id', pId);
  END IF;

  PERFORM EditSubscription(pId, pParent, pType, pPrice, pClient, pCustomer, pCode, pPeriodStart, pPeriodEnd, pMetaData, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_subscription --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a subscription (upsert)
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
 * @return {SETOF api.subscription}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_subscription (
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
) RETURNS       SETOF api.subscription
AS $$
BEGIN
  pId := coalesce(pId, GetSubscription(pCode));

  IF pId IS NULL THEN
    pId := api.add_subscription(pParent, pType, pPrice, pClient, pCustomer, pCode, pPeriodStart, pPeriodEnd, pMetaData, pLabel, pDescription);
  ELSE
    PERFORM api.update_subscription(pId, pParent, pType, pPrice, pClient, pCustomer, pCode, pPeriodStart, pPeriodEnd, pMetaData, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.subscription WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_subscription --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a subscription by identifier
 * @param {uuid} pId - Record identifier
 * @return {SETOF api.subscription}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_subscription (
  pId       uuid
) RETURNS   SETOF api.subscription
AS $$
  SELECT * FROM api.subscription WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_subscription ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the count of subscription records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_subscription (
  pSearch    jsonb default null,
  pFilter    jsonb default null
) RETURNS    SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'subscription', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_subscription -------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a filtered/sorted list of subscription records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.subscription}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_subscription (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.subscription
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'subscription', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
