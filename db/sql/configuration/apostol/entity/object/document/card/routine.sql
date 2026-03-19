--------------------------------------------------------------------------------
-- CreateCard ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new card
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pClient - Client identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {date} pExpiry - Expiry date
 * @param {text} pBinding - Binding identifier
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @param {integer} pSequence - Sort order
 * @return {uuid} - Card identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateCard (
  pParent       uuid,
  pType         uuid,
  pClient       uuid,
  pCode         text default null,
  pName         text default null,
  pExpiry       date default null,
  pBinding      text default null,
  pLabel        text default null,
  pDescription  text default null,
  pSequence     integer default null
) RETURNS       uuid
AS $$
DECLARE
  uCard         uuid;
  uDocument     uuid;

  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'card' THEN
    PERFORM IncorrectClassType();
  END IF;

  IF pClient IS NOT NULL THEN
    PERFORM FROM db.client WHERE id = pClient;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('client', 'id', pClient);
    END IF;

    PERFORM FROM db.card WHERE client = pClient AND code = pCode;
    IF FOUND THEN
      PERFORM CardCodeExists(pCode);
    END IF;
  ELSE
    PERFORM FROM db.card WHERE code = pCode;
    IF FOUND THEN
      PERFORM CardCodeExists(pCode);
    END IF;
  END IF;

  IF NULLIF(pSequence, -1) IS NULL THEN
    SELECT max(sequence) + 1 INTO pSequence FROM db.card WHERE client IS NOT DISTINCT FROM pClient;
  ELSE
    PERFORM SetCardSequence(pClient, pSequence, 1);
  END IF;
  
  uDocument := CreateDocument(pParent, pType, pLabel, pDescription);

  INSERT INTO db.card (id, document, client, code, name, expiry, binding, sequence)
  VALUES (uDocument, uDocument, pClient, pCode, pName, pExpiry, pBinding, coalesce(pSequence, 0))
  RETURNING id INTO uCard;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uCard, uMethod);

  RETURN uCard;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditCard --------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Edits card parameters
 * @param {uuid} pId - Client identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pClient - Client identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {date} pExpiry - Expiry date
 * @param {text} pBinding - Binding identifier
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @param {integer} pSequence - Sort order
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditCard (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pClient       uuid default null,
  pCode         text default null,
  pName         text default null,
  pExpiry       date default null,
  pBinding      text default null,
  pLabel        text default null,
  pDescription  text default null,
  pSequence     integer default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;

  nSequence     integer;

  -- current
  cClient       uuid;
  cCode         text;
BEGIN
  SELECT code, client, sequence INTO cCode, cClient, nSequence FROM db.card WHERE id = pId;

  pCode := coalesce(pCode, cCode);
  pClient := coalesce(pClient, cClient);
  pSequence := coalesce(pSequence, nSequence);

  IF pCode <> cCode THEN
    PERFORM FROM db.card WHERE client = pClient AND code = pCode;
    IF found THEN
      PERFORM CardCodeExists(pCode);
    END IF;
  END IF;

  IF GetObjectTypeCode(pId) != 'rfid.card' THEN
    pClient := null;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.card
     SET code = pCode,
         name = coalesce(pName, name),
         client = coalesce(pClient, client),
         expiry = coalesce(pExpiry, expiry),
         binding = CheckNull(coalesce(pBinding, binding, '')),
         sequence = pSequence
   WHERE id = pId;

  IF pSequence != nSequence THEN
    PERFORM SetCardSequence(pId, pSequence, 1);
  END IF;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));

  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCard ---------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the card by code
 * @param {text} pCode - Code
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCard (
  pCode     text
) RETURNS   uuid
AS $$
  SELECT id FROM db.card WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCardCode -----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the card code by identifier
 * @param {uuid} pCard - Card identifier
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCardCode (
  pCard     uuid
) RETURNS   text
AS $$
  SELECT code FROM db.card WHERE id = pCard;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCardClient ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the client identifier for the card
 * @param {uuid} pCard - Card identifier
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCardClient (
  pCard     uuid
) RETURNS   uuid
AS $$
  SELECT client FROM db.card WHERE id = pCard;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClientCardsJson ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns card data as JSON for the given client
 * @param {uuid} pClient - Client identifier
 * @return {json}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetClientCardsJson (
  pClient   uuid
) RETURNS   json
AS $$
DECLARE
  arResult  json[];
  r         record;
BEGIN
  FOR r IN SELECT * FROM Card WHERE client = pClient ORDER BY sequence
  LOOP
    arResult := array_append(arResult, row_to_json(r));
  END LOOP;

  RETURN array_to_json(arResult);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION SetCardSequence ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Sets the sort order for a card
 * @param {uuid} pId - Record identifier
 * @param {integer} pSequence - Sort order
 * @param {integer} pDelta - Sequence increment direction
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SetCardSequence (
  pId       uuid,
  pSequence integer,
  pDelta    integer
) RETURNS   void
AS $$
DECLARE
  nId       uuid;
  uClient   uuid;
BEGIN
  IF pDelta <> 0 THEN
    SELECT client INTO uClient FROM db.card WHERE id = pId;
    SELECT id INTO nId
      FROM db.card
     WHERE client IS NOT DISTINCT FROM uClient
       AND sequence = pSequence
       AND id <> pId;

    IF FOUND THEN
      PERFORM SetCardSequence(nId, pSequence + pDelta, pDelta);
    END IF;
  END IF;

  UPDATE db.card SET sequence = pSequence WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION SortCard -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Re-sorts all card records for a client
 * @param {uuid} pClient - Client identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SortCard (
  pClient    uuid
) RETURNS    void
AS $$
DECLARE
  r          record;
BEGIN
  FOR r IN
    SELECT id, (row_number() OVER(order by sequence))::int as newsequence
      FROM db.card
     WHERE client IS NOT DISTINCT FROM pClient
  LOOP
    PERFORM SetCardSequence(r.id, r.newsequence - 1, 0);
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCardBindingsJson ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns card data as JSON for the given client
 * @param {uuid} pClient - Client identifier
 * @return {json}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCardBindingsJson (
  pClient       uuid
) RETURNS       json
AS $$
DECLARE
  uType         uuid;
  arResult      json[];
  r             record;
BEGIN
  uType = GetType('credit.card');

  FOR r IN
    SELECT c.code, c.expiry, d.binding, a.code AS agent_code
      FROM db.card c INNER JOIN db.object    o ON c.document = o.id
                     INNER JOIN db.card_data d ON c.id = d.card
                     INNER JOIN db.reference a ON a.id = d.agent
     WHERE c.client = pClient
       AND o.type = uType
       AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
     ORDER BY c.sequence
  LOOP
    arResult := array_append(arResult, json_build_object('bindingId', r.binding, 'maskedPan', r.code, 'expiryDate', DateToStr(r.expiry, 'YYYYMM'), 'paymentWay', 'CARD', 'displayLabel', 'XXXXXXXXXXXX' || SubStr(r.code, 13, 4), 'agentCode', r.agent_code));
  END LOOP;

  RETURN array_to_json(arResult);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION SetCardData --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Sets or updates card data
 * @param {uuid} pCard - Card identifier
 * @param {uuid} pAgent - Agent identifier
 * @param {text} pCardId - External card identifier
 * @param {text} pBinding - Binding identifier
 * @param {text} pEncrypted - Encrypted card data
 * @param {jsonb} pData - Additional data
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SetCardData (
  pCard         uuid,
  pAgent        uuid,
  pCardId       text DEFAULT null,
  pBinding      text DEFAULT null,
  pEncrypted    text DEFAULT null,
  pData         jsonb DEFAULT null
) RETURNS       void
AS $$
BEGIN
  UPDATE db.card_data
     SET card_id = CheckNull(coalesce(pCardId, card_id, '')),
         binding = CheckNull(coalesce(pBinding, binding, '')),
         encrypted = CheckNull(coalesce(pEncrypted, encrypted, '')),
         data = CheckNull(coalesce(pData, data, '{}'::jsonb)),
         updated = Now()
   WHERE card = pCard
     AND agent = pAgent;

  IF NOT FOUND THEN
    INSERT INTO db.card_data SELECT pCard, pAgent, pCardId, pBinding, pEncrypted, pData;
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION ClearCardData ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Clears card data
 * @param {uuid} pCard - Card identifier
 * @param {uuid} pAgent - Agent identifier
 * @return {boolean}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION ClearCardData (
  pCard         uuid,
  pAgent        uuid
) RETURNS       boolean
AS $$
BEGIN
  DELETE FROM db.card_data
   WHERE card = pCard
     AND agent = pAgent;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
