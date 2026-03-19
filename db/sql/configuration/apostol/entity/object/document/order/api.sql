--------------------------------------------------------------------------------
-- ORDER -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.order -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.order
AS
  SELECT * FROM ObjectOrder;

GRANT SELECT ON api.order TO administrator;

--------------------------------------------------------------------------------
-- api.add_order ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Adds a new order
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pDebit - Debit amount
 * @param {uuid} pCredit - Credit amount
 * @param {numeric} pAmount - Amount
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_order (
  pParent       uuid,
  pType         uuid,
  pDebit        uuid,
  pCredit       uuid,
  pAmount       numeric,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateOrder(pParent, coalesce(pType, GetType('memo.order')), pDebit, pCredit, pAmount, pCode, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_order ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Updates an existing order
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pDebit - Debit amount
 * @param {uuid} pCredit - Credit amount
 * @param {numeric} pAmount - Amount
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {void}
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_order (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pDebit        uuid default null,
  pCredit       uuid default null,
  pAmount       numeric default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
BEGIN
  pId := coalesce(pId, GetOrder(pCode));

  PERFORM FROM db.order WHERE id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('order', 'id', pId);
  END IF;

  PERFORM EditOrder(pId, pParent, pType, pDebit, pCredit, pAmount, pCode, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_order ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates an order (upsert)
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pDebit - Debit amount
 * @param {uuid} pCredit - Credit amount
 * @param {numeric} pAmount - Amount
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {SETOF api.order}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_order (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pDebit        uuid default null,
  pCredit       uuid default null,
  pAmount       numeric default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       SETOF api.order
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_order(pParent, pType, pDebit, pCredit, pAmount, pCode, pLabel, pDescription);
  ELSE
    PERFORM api.update_order(pId, pParent, pType, pDebit, pCredit, pAmount, pCode, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.order WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_order ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns an order by identifier
 * @param {uuid} pId - Record identifier
 * @return {SETOF api.order}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_order (
  pId       uuid
) RETURNS   SETOF api.order
AS $$
  SELECT * FROM api.order WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_order -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of order records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_order (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
DECLARE
  r             record;
  uClient       uuid;
  arAccounts    uuid[];
BEGIN
  IF pFilter ? 'client' THEN
    uClient := pFilter->>'client';
	pFilter := pFilter - 'client';
  END IF;

  IF NOT IsAdmin() OR uClient IS NOT NULL THEN
	FOR r IN
	  SELECT id FROM db.account WHERE client = coalesce(uClient, current_client())
	LOOP
	  arAccounts := array_append(arAccounts, r.id);
	END LOOP;

    pSearch := coalesce(pSearch, '[]'::jsonb) || jsonb_build_array(jsonb_build_object('lstr', '(', 'field', 'debit', 'valarr', array_to_json(arAccounts), 'compare', 'IN'), jsonb_build_object('rstr', ')', 'condition', 'OR', 'field', 'credit', 'valarr', array_to_json(arAccounts), 'compare', 'IN'));
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'order', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_order --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a filtered/sorted list of order records
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.order}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_order (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.order
AS $$
DECLARE
  r             record;
  uClient       uuid;
  arAccounts    uuid[];
BEGIN
  IF pFilter ? 'client' THEN
    uClient := pFilter->>'client';
	pFilter := pFilter - 'client';
  END IF;

  IF NOT IsAdmin() OR uClient IS NOT NULL THEN
	FOR r IN
	  SELECT id FROM db.account WHERE client = coalesce(uClient, current_client())
	LOOP
	  arAccounts := array_append(arAccounts, r.id);
	END LOOP;

    pSearch := coalesce(pSearch, '[]'::jsonb) || jsonb_build_array(jsonb_build_object('lstr', '(', 'field', 'debit', 'valarr', array_to_json(arAccounts), 'compare', 'IN'), jsonb_build_object('rstr', ')', 'condition', 'OR', 'field', 'credit', 'valarr', array_to_json(arAccounts), 'compare', 'IN'));
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'order', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

