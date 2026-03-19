--------------------------------------------------------------------------------
-- CreateIdentity --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new identity document
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCountry - Country
 * @param {uuid} pClient - Client identifier
 * @param {text} pSeries - Series
 * @param {text} pNumber - Number
 * @param {text} pCode - Code
 * @param {text} pIssued - Issued
 * @param {date} pDate - Date
 * @param {bytea} pPhoto - Photo
 * @param {timestamptz} pReminderDate - ReminderDate
 * @param {timestamptz} pValidFromDate - ValidFromDate
 * @param {timestamptz} pValidToDate - ValidToDate
 * @return {uuid}
 * @throws IdentityExists
 * @throws IncorrectClassType
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateIdentity (
  pParent           uuid,
  pType             uuid,
  pCountry          uuid,
  pClient           uuid,
  pSeries           text,
  pNumber           text,
  pCode             text default null,
  pIssued           text default null,
  pDate             date default null,
  pPhoto            bytea default null,
  pReminderDate     timestamptz default null,
  pValidFromDate    timestamptz default null,
  pValidToDate      timestamptz default null
) RETURNS           uuid
AS $$
DECLARE
  vIdentity         text;

  uDocument         uuid;
  uClass            uuid;
  uMethod           uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetClassCode(uClass) <> 'identity' THEN
    PERFORM IncorrectClassType();
  END IF;

  pCountry := coalesce(pCountry, GetCountry(643));

  PERFORM FROM db.country WHERE id = pCountry;
  IF NOT FOUND THEN
	PERFORM ObjectNotFound('country', 'id', pCountry);
  END IF;

  PERFORM FROM db.client WHERE id = pClient;
  IF NOT FOUND THEN
	PERFORM ObjectNotFound('client', 'id', pClient);
  END IF;

  vIdentity := coalesce(pSeries, '') || ' ' || pNumber;

  PERFORM FROM db.identity WHERE type = pType AND identity = vIdentity;
  IF FOUND THEN
    PERFORM IdentityExists(vIdentity);
  END IF;

  uDocument := CreateDocument(pParent, pType, vIdentity, GetClientName(pClient));

  IF pValidToDate IS NOT NULL THEN
    pReminderDate := coalesce(pReminderDate, pValidToDate - interval '60 day');
  END IF;

  pValidFromDate := coalesce(pValidFromDate, Now());
  pValidToDate := coalesce(pValidToDate, MAXDATE());

  INSERT INTO db.identity (id, document, type, country, client, series, number, code, issued, date, photo, reminderDate, validFromDate, validToDate)
  VALUES (uDocument, uDocument, pType, pCountry, pClient, pSeries, pNumber, pCode, pIssued, pDate, pPhoto, pReminderDate, pValidFromDate, pValidToDate);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uDocument, uMethod);

  RETURN uDocument;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditIdentity ----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Edits an existing identity document
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
 * @param {bytea} pPhoto - Photo
 * @param {timestamptz} pReminderDate - ReminderDate
 * @param {timestamptz} pValidFromDate - ValidFromDate
 * @param {timestamptz} pValidToDate - ValidToDate
 * @return {void}
 * @throws IdentityExists
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditIdentity (
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
  pPhoto            bytea default null,
  pReminderDate     timestamptz default null,
  pValidFromDate    timestamptz default null,
  pValidToDate      timestamptz default null
) RETURNS           void
AS $$
DECLARE
  uClass            uuid;
  uMethod           uuid;
  cType             uuid;

  vIdentity         text;
  vDescription      text;

  cIdentity         text;
BEGIN
  SELECT type, identity INTO cType, cIdentity FROM db.identity WHERE id = pId;
  IF NOT FOUND THEN
	PERFORM ObjectNotFound('identity', 'id', pId);
  END IF;

  vIdentity := coalesce(coalesce(pSeries, '') || ' ' || pNumber, cIdentity);

  IF cIdentity IS DISTINCT FROM vIdentity THEN
    PERFORM FROM db.identity WHERE type = coalesce(pType, cType) AND identity = vIdentity;
    IF FOUND THEN
      PERFORM IdentityExists(vIdentity);
    END IF;
  END IF;

  IF pCountry IS NOT NULL THEN
    PERFORM FROM db.country WHERE id = pCountry;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('country', 'id', pCountry);
    END IF;
  END IF;

  IF pClient IS NOT NULL THEN
    PERFORM FROM db.client WHERE id = pClient;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('client', 'id', pClient);
    END IF;

    vDescription := GetClientName(pClient);
  END IF;

  PERFORM EditDocument(pId, pParent, pType, vIdentity, vDescription, vDescription, current_locale());

  UPDATE db.identity
     SET country = coalesce(pCountry, country),
         client = coalesce(pClient, client),
         series = CheckNull(coalesce(pSeries, series, '')),
         number = coalesce(pNumber, number),
         code = CheckNull(coalesce(pCode, code, '')),
         issued = CheckNull(coalesce(pIssued, issued, '')),
         date = CheckNull(coalesce(pDate, date, MINDATE())),
         reminderDate = CheckNull(coalesce(pReminderDate, reminderDate, MINDATE())),
         validFromDate = coalesce(pValidFromDate, validFromDate),
         validToDate = coalesce(pValidToDate, validToDate)
   WHERE id = pId;

  IF pPhoto IS NOT NULL THEN
    UPDATE db.identity
       SET photo = pPhoto
     WHERE id = pId;
  END IF;

  SELECT class INTO uClass FROM db.object WHERE id = pId;

  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SetIdentity -----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief SetIdentity
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
 * @param {bytea} pPhoto - Photo
 * @param {timestamptz} pReminderDate - ReminderDate
 * @param {timestamptz} pValidFromDate - ValidFromDate
 * @param {timestamptz} pValidToDate - ValidToDate
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SetIdentity (
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
  pPhoto            bytea default null,
  pReminderDate     timestamptz default null,
  pValidFromDate    timestamptz default null,
  pValidToDate      timestamptz default null
) RETURNS           uuid
AS $$
BEGIN
  IF pId IS NULL THEN
    SELECT id INTO pId FROM db.identity i WHERE i.type = pType AND i.identity = coalesce(pSeries || ' ' || pNumber, pNumber);
  END IF;

  PERFORM FROM db.identity WHERE id = pId;

  IF FOUND THEN
	PERFORM EditIdentity(pId, pParent, pType, pCountry, pClient, pSeries, pNumber, pCode, pIssued, pDate, pPhoto, pReminderDate, pValidFromDate, pValidToDate);
  ELSE
	pId := CreateIdentity(pParent, pType, pCountry, pClient, pSeries, pNumber, pCode, pIssued, pDate, pPhoto, pReminderDate, pValidFromDate, pValidToDate);
  END IF;

  RETURN pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetIdentity -----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the identity document by code
 * @param {uuid} pType - Type identifier
 * @param {uuid} pClient - Client identifier
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetIdentity (
  pType     uuid,
  pClient   uuid
) RETURNS	text
AS $$
  SELECT identity FROM db.identity WHERE type = pType AND client = pClient AND validfromdate <= Now() AND validtodate > Now();
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetIdentityId ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the identity document by code
 * @param {uuid} pType - Type identifier
 * @param {uuid} pClient - Client identifier
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetIdentityId (
  pType     uuid,
  pClient   uuid
) RETURNS	uuid
AS $$
  SELECT id FROM db.identity WHERE type = pType AND client = pClient AND validfromdate <= Now() AND validtodate > Now();
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
