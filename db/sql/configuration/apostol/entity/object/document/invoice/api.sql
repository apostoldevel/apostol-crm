--------------------------------------------------------------------------------
-- INVOICE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.invoice -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.invoice
AS
  SELECT * FROM ObjectInvoice;

GRANT SELECT ON api.invoice TO administrator;

--------------------------------------------------------------------------------
-- api.add_invoice -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Adds a new invoice
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pDevice - Device
 * @param {text} pCode - Code
 * @param {numeric} pAmount - Amount
 * @param {text} pPDF - PDF
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_invoice (
  pParent       uuid,
  pType         uuid,
  pCurrency     uuid,
  pClient       uuid,
  pDevice       uuid,
  pCode         text,
  pAmount       numeric,
  pPDF          text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateInvoice(pParent, coalesce(pType, GetType('top-up.invoice')), pCurrency, pClient, pDevice, pCode, pAmount, pPDF, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_invoice ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Updates an existing invoice
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pDevice - Device
 * @param {text} pCode - Code
 * @param {numeric} pAmount - Amount
 * @param {text} pPDF - PDF
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {void}
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_invoice (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCurrency     uuid default null,
  pClient       uuid default null,
  pDevice       uuid default null,
  pCode         text default null,
  pAmount       numeric default null,
  pPDF          text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
BEGIN
  PERFORM FROM db.invoice WHERE id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('invoice', 'id', pId);
  END IF;

  PERFORM EditInvoice(pId, pParent, pType, pCurrency, pClient, pDevice, pCode, pAmount, pPDF, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_invoice -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates an invoice (upsert)
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pDevice - Device
 * @param {text} pCode - Code
 * @param {numeric} pAmount - Amount
 * @param {text} pPDF - PDF
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {SETOF api.invoice}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_invoice (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCurrency     uuid default null,
  pClient       uuid default null,
  pDevice       uuid default null,
  pCode         text default null,
  pAmount       numeric default null,
  pPDF          text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       SETOF api.invoice
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_invoice(pParent, pType, pCurrency, pClient, pDevice, pCode, pAmount, pPDF, pLabel, pDescription);
  ELSE
    PERFORM api.update_invoice(pId, pParent, pType, pCurrency, pClient, pDevice, pCode, pAmount, pPDF, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.invoice WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_invoice -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns an account by identifier
 * @param {uuid} pId - Identifier
 * @return {api.invoice} - Invoice record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_invoice (
  pId        uuid
) RETURNS    SETOF api.invoice
AS $$
  SELECT * FROM api.invoice WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_invoice -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of invoice records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_invoice (
  pSearch    jsonb default null,
  pFilter    jsonb default null
) RETURNS    SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('kernel', 'ObjectInvoice', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_invoice ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a filtered/sorted list of invoice records
 * @param {jsonb} pSearch - Search conditions array
 * @param {jsonb} pFilter - Filter object
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.invoice} - List of invoice records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_invoice (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.invoice
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'invoice', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.check_invoice -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Checks invoices for payment
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.check_invoice()
RETURNS	void
AS $$
DECLARE
  r			    record;
  e			    record;
  i			    record;

  uArea         uuid;
  uInvoice      uuid;

  dtDate        timestamptz;

  vCode         text;

  params	    jsonb;

  vMessage      text;
  vContext      text;
BEGIN
  uArea := GetSessionArea();

  FOR r IN
	SELECT t.id, d.area
	  FROM db.invoice t INNER JOIN db.object   o ON o.id = t.document
	                    INNER JOIN db.document d ON d.id = t.document
                        INNER JOIN db.state    s ON o.state = s.id AND s.code IN ('created', 'failed')
  LOOP
    uInvoice := r.id;

    PERFORM SetSessionArea(r.area);

    params := GetObjectDataJSON(r.id, 'params')::jsonb;

    FOR e IN SELECT * FROM jsonb_to_record(params) AS x(auto_payment boolean)
    LOOP
      SELECT statecode INTO vCode FROM Object WHERE id = r.id;
	  IF coalesce(e.auto_payment, true) THEN
		IF vCode = 'failed' THEN
		  PERFORM DoTryAction(r.id, 'cancel');
		END IF;
	    PERFORM DoTryAction(r.id, 'enable', jsonb_build_object('clear_hash', false));
	  ELSE
	    SELECT ldate INTO dtDate FROM db.object WHERE id = r.id;
	    IF Now() - dtDate >= interval '1 day' THEN
          IF vCode = 'failed' THEN
            PERFORM DoTryAction(r.id, 'cancel');
          END IF;
          PERFORM DoTryAction(r.id, 'enable', jsonb_build_object('clear_hash', true));
		END IF;
	  END IF;
	END LOOP;
  END LOOP;

  FOR i IN
	SELECT t.device, d.area
	  FROM db.transaction t INNER JOIN db.object   o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000003'::uuid
	                        INNER JOIN db.document d ON d.id = t.document
       AND t.invoice IS NULL
     GROUP BY device, area
  LOOP
    PERFORM SetSessionArea(i.area);
	PERFORM BuildInvoice(i.device);
  END LOOP;

  PERFORM SetSessionArea(uArea);
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
  PERFORM WriteDiagnostics(vMessage, vContext, uInvoice);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
