--------------------------------------------------------------------------------
-- identity --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.identity ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.identity
AS
  SELECT * FROM ObjectIdentity;

GRANT SELECT ON api.identity TO administrator;

--------------------------------------------------------------------------------
-- api.add_identity ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Adds a new identity document
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCountry - Country identifier
 * @param {uuid} pClient - Client identifier
 * @param {text} pSeries - Document series
 * @param {text} pNumber - Document number
 * @param {text} pCode - Department code / other code
 * @param {text} pIssued - Issued by
 * @param {date} pdDate - Issue date
 * @param {text} pPhoto - Photo in BASE64 format
 * @param {timestamptz} pReminderDate - Reminder date
 * @param {timestamptz} pValidFromDate - Period start date
 * @param {timestamptz} pValidToDate - Period end date
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_identity (
  pParent           uuid,
  pType             uuid,
  pCountry          uuid,
  pClient           uuid,
  pSeries           text,
  pNumber           text,
  pCode             text default null,
  pIssued           text default null,
  pDate             date default null,
  pPhoto            text default null,
  pReminderDate     timestamptz default null,
  pValidFromDate    timestamptz default null,
  pValidToDate      timestamptz default null
) RETURNS           uuid
AS $$
BEGIN
  RETURN CreateIdentity(pParent, coalesce(pType, GetType('passport.identity')), pCountry, pClient, pSeries, pNumber, pCode, pIssued, pDate, decode(pPhoto, 'base64'), pReminderDate, pValidFromDate, pValidToDate);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_identity ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing identity document
 * @param {uuid} pId - Identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCountry - Country identifier
 * @param {uuid} pClient - Client identifier
 * @param {text} pSeries - Document series
 * @param {text} pNumber - Document number
 * @param {text} pCode - Department code / other code
 * @param {text} pIssued - Issued by
 * @param {date} pdDate - Issue date
 * @param {text} pPhoto - Photo in BASE64 format
 * @param {timestamptz} pReminderDate - Reminder date
 * @param {timestamptz} pValidFromDate - Period start date
 * @param {timestamptz} pValidToDate - Period end date
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_identity (
  pId               uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pCountry          uuid default null,
  pClient           uuid default null,
  pSeries           text default null,
  pNumber           text default null,
  pCode             text default null,
  pIssued           text default null,
  pDate             date default null,
  pPhoto            text default null,
  pReminderDate     timestamptz default null,
  pValidFromDate    timestamptz default null,
  pValidToDate      timestamptz default null
) RETURNS           void
AS $$
BEGIN
  PERFORM EditIdentity(pId, pParent, pType, pCountry, pClient, pSeries, pNumber, pCode, pIssued, pDate, decode(pPhoto, 'base64'), pReminderDate, pValidFromDate, pValidToDate);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_identity ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates an identity document (upsert)
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCountry - Country
 * @param {uuid} pClient - Client identifier
 * @param {text} pSeries - Series
 * @param {text} pNumber - Number
 * @param {text} pCode - Code
 * @param {text} pIssued - Issued
 * @param {date} pDate - Date
 * @param {text} pPhoto - Photo
 * @param {timestamptz} pReminderDate - ReminderDate
 * @param {timestamptz} pValidFromDate - ValidFromDate
 * @param {timestamptz} pValidToDate - ValidToDate
 * @return {SETOF api.identity}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_identity (
  pId               uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pCountry          uuid default null,
  pClient           uuid default null,
  pSeries           text default null,
  pNumber           text default null,
  pCode             text default null,
  pIssued           text default null,
  pDate             date default null,
  pPhoto            text default null,
  pReminderDate     timestamptz default null,
  pValidFromDate    timestamptz default null,
  pValidToDate      timestamptz default null
) RETURNS           SETOF api.identity
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_identity(pParent, pType, pCountry, pClient, pSeries, pNumber, pCode, pIssued, pDate, pPhoto, pReminderDate, pValidFromDate, pValidToDate);
  ELSE
    PERFORM api.update_identity(pId, pParent, pType, pCountry, pClient, pSeries, pNumber, pCode, pIssued, pDate, pPhoto, pReminderDate, pValidFromDate, pValidToDate);
  END IF;

  RETURN QUERY SELECT * FROM api.identity WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_identity ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns an identity document by identifier
 * @param {uuid} pId - Identifier
 * @return {api.identity}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_identity (
  pId		uuid
) RETURNS	SETOF api.identity
AS $$
  SELECT * FROM api.identity WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_identity ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of identity document records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_identity (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'identity', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_identity -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a filtered/sorted list of identity document records
 * @param {jsonb} pSearch - Search conditions array
 * @param {jsonb} pFilter - Filter object
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.identity}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_identity (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.identity
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'identity', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
