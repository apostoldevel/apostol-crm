--------------------------------------------------------------------------------
-- FUNCTION NewClientName ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Adds or updates the client name
 * @param {uuid} pClient - Client identifier
 * @param {text} pName - Full company name / person full name
 * @param {text} pFirst - First name
 * @param {text} pLast - Last name
 * @param {text} pMiddle - Middle name
 * @param {text} pShort - Short company name
 * @param {uuid} pLocale - Locale identifier
 * @param {timestamptz} pDateFrom - Modification date
 * @return {(void|exception)}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION NewClientName (
  pClient       uuid,
  pName         text,
  pShort        text default null,
  pFirst        text default null,
  pLast         text default null,
  pMiddle       text default null,
  pLocale       uuid default current_locale(),
  pDateFrom     timestamptz default oper_date()
) RETURNS       void
AS $$
DECLARE
  uId           uuid;

  dtDateFrom    timestamptz;
  dtDateTo      timestamptz;
BEGIN
  uId := null;

  pName := NULLIF(trim(pName), '');
  pShort := NULLIF(trim(pShort), '');
  pFirst := NULLIF(trim(pFirst), '');
  pLast := NULLIF(trim(pLast), '');
  pMiddle := NULLIF(trim(pMiddle), '');

  -- get the value date within the current date range
  SELECT validFromDate, validToDate INTO dtDateFrom, dtDateTo
    FROM db.client_name
   WHERE client = pClient
     AND locale = pLocale
     AND validFromDate <= pDateFrom
     AND validToDate > pDateFrom;

  IF coalesce(dtDateFrom, MINDATE()) = pDateFrom THEN
    -- update the value within the current date range
    UPDATE db.client_name SET name = pName, short = pShort, first = pFirst, last = pLast, middle = pMiddle
     WHERE client = pClient
       AND locale = pLocale
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;
  ELSE
    -- update the value date within the current date range
    UPDATE db.client_name SET validToDate = pDateFrom
     WHERE client = pClient
       AND locale = pLocale
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;

    INSERT INTO db.client_name (client, locale, name, short, first, last, middle, validfromdate, validToDate)
    VALUES (pClient, pLocale, pName, pShort, pFirst, pLast, pMiddle, pDateFrom, coalesce(dtDateTo, MAXDATE()));
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION EditClientName -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Edits an existing name
 * @param {uuid} pClient - Client identifier
 * @param {text} pName - Full company name / person full name
 * @param {text} pShort - Short company name
 * @param {text} pFirst - First name
 * @param {text} pLast - Last name
 * @param {text} pMiddle - Middle name
 * @param {uuid} pLocale - Locale identifier
 * @param {timestamptz} pDateFrom - Modification date
 * @return {(void|exception)}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditClientName (
  pClient       uuid,
  pName         text,
  pShort        text default null,
  pFirst        text default null,
  pLast         text default null,
  pMiddle       text default null,
  pLocale       uuid default current_locale(),
  pDateFrom     timestamptz default oper_date()
) RETURNS       void
AS $$
DECLARE
  uMethod       uuid;

  vHash         text;
  cHash         text;

  r             record;
BEGIN
  SELECT * INTO r FROM GetClientNameRec(pClient, pLocale, pDateFrom);

  pName := coalesce(pName, r.name);
  pShort := coalesce(pShort, r.short, '');
  pFirst := coalesce(pFirst, r.first, '');
  pLast := coalesce(pLast, r.last, '');
  pMiddle := coalesce(pMiddle, r.middle, '');

  vHash := encode(digest(pName || pShort || pFirst || pLast || pMiddle, 'md5'), 'hex');
  cHash := encode(digest(r.name || coalesce(r.short, '') || coalesce(r.first, '') || coalesce(r.last, '') || coalesce(r.middle, ''), 'md5'), 'hex');

  IF vHash IS DISTINCT FROM cHash THEN
    PERFORM NewClientName(pClient, pName, CheckNull(pShort), CheckNull(pFirst), CheckNull(pLast), CheckNull(pMiddle), pLocale, pDateFrom);

    uMethod := GetMethod(GetObjectClass(pClient), GetAction('edit'));
    PERFORM ExecuteMethod(pClient, uMethod);
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetClientNameRec ---------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the name by code
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pLocale - Locale identifier
 * @param {timestamptz} pDate - Date
 * @return {SETOF db.client_name}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetClientNameRec (
  pClient       uuid,
  pLocale       uuid default current_locale(),
  pDate         timestamptz default oper_date()
) RETURNS       SETOF db.client_name
AS $$
BEGIN
  RETURN QUERY SELECT *
    FROM db.client_name n
   WHERE n.client = pClient
     AND n.locale = pLocale
     AND n.validFromDate <= pDate
     AND n.validToDate > pDate;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetClientNameJson --------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns name data as JSON for the given client
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pLocale - Locale identifier
 * @param {timestamptz} pDate - Date
 * @return {json}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetClientNameJson (
  pClient       uuid,
  pLocale       uuid default current_locale(),
  pDate         timestamptz default oper_date()
) RETURNS       SETOF json
AS $$
DECLARE
  r             record;
BEGIN
  FOR r IN
    SELECT *
      FROM db.client_name n
     WHERE n.client = pClient
       AND n.locale = pLocale
       AND n.validFromDate <= pDate
       AND n.validToDate > pDate
  LOOP
    RETURN NEXT row_to_json(r);
  END LOOP;

  RETURN;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetClientName ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the name by code
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pLocale - Locale identifier
 * @param {timestamptz} pDate - Date
 * @return {(text|null|exception)}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetClientName (
  pClient       uuid,
  pLocale       uuid default current_locale(),
  pDate         timestamptz default oper_date()
) RETURNS       text
AS $$
  SELECT name FROM GetClientNameRec(pClient, pLocale, pDate);
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetClientShortName -------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the name by code
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pLocale - Locale identifier
 * @param {timestamptz} pDate - Date
 * @return {(text|null|exception)}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetClientShortName (
  pClient       uuid,
  pLocale       uuid default current_locale(),
  pDate         timestamptz default oper_date()
) RETURNS       text
AS $$
  SELECT short FROM GetClientNameRec(pClient, pLocale, pDate);
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
