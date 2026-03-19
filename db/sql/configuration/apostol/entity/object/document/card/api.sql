--------------------------------------------------------------------------------
-- CARD ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.card --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.card
AS
  SELECT * FROM ObjectCard;

GRANT SELECT ON api.card TO administrator;

--------------------------------------------------------------------------------
-- api.card --------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief api.card
 * @param {uuid} pState - State identifier
 * @return {SETOF api.card}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.card (
  pState    uuid
) RETURNS   SETOF api.card
AS $$
  SELECT * FROM api.card WHERE state = pState;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.card --------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief api.card
 * @param {text} pState - State identifier
 * @return {SETOF api.card}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.card (
  pState    text
) RETURNS   SETOF api.card
AS $$
BEGIN
  RETURN QUERY SELECT * FROM api.card(GetState(GetClass('card'), pState));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.add_card ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Adds a new card
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pClient - Identifier
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {date} pExpiry - Expiry date
 * @param {text} pBinding - Binding identifier
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @param {integer} pSequence - Sort order
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_card (
  pParent       uuid,
  pType         uuid,
  pClient       uuid,
  pCode         text,
  pName         text default null,
  pExpiry       date default null,
  pBinding      text default null,
  pLabel        text default null,
  pDescription  text default null,
  pSequence     integer default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateCard(pParent, coalesce(pType, GetType('rfid.card')), pClient, pCode, pName, pExpiry, pBinding, pLabel, pDescription, pSequence);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_card -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing card
 * @param {uuid} pId - Card identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pClient - Identifier
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
CREATE OR REPLACE FUNCTION api.update_card (
  pId           uuid,
  pParent       uuid,
  pType         uuid,
  pClient       uuid,
  pCode         text,
  pName         text default null,
  pExpiry       date default null,
  pBinding      text default null,
  pLabel        text default null,
  pDescription  text default null,
  pSequence     integer default null
) RETURNS       void
AS $$
BEGIN
  PERFORM FROM db.card c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('card', 'id', pId);
  END IF;

  PERFORM EditCard(pId, pParent, pType, pClient,pCode, pName, pExpiry, pBinding, pLabel, pDescription, pSequence);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_card ----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a card (upsert)
 * @param {uuid} pId - Record identifier
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
 * @return {SETOF api.card}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_card (
  pId           uuid,
  pParent       uuid,
  pType         uuid,
  pClient       uuid,
  pCode         text,
  pName         text default null,
  pExpiry       date default null,
  pBinding      text default null,
  pLabel        text default null,
  pDescription  text default null,
  pSequence     integer default null
) RETURNS       SETOF api.card
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_card(pParent, pType, pClient, pCode, pName, pExpiry, pBinding, pLabel, pDescription, pSequence);
  ELSE
    PERFORM api.update_card(pId, pParent, pType, pClient, pCode, pName, pExpiry, pBinding, pLabel, pDescription, pSequence);
  END IF;

  RETURN QUERY SELECT * FROM api.card WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_card ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a card by identifier
 * @param {uuid} pId - Identifier
 * @return {api.card} - Card record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_card (
  pId        uuid
) RETURNS    SETOF api.card
AS $$
  SELECT * FROM api.card WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_card --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of card records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_card (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'card', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_card ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a filtered/sorted list of card records
 * @param {jsonb} pSearch - Search conditions array
 * @param {jsonb} pFilter - Filter object
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.card} - List of cards
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_card (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.card
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'card', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.bind_card ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Binds a card to the current user
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {date} pExpiry - Expiry date
 * @param {text} pHidden - Hidden/encrypted value
 * @param {text} pData - Additional data
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {json}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.bind_card (
  pCode         text,
  pName         text,
  pExpiry       date default null,
  pHidden       text default null,
  pData         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       json
AS $$
DECLARE
  uClient       uuid;
  uCard         uuid;

  vMaskedPan    text;
  vBinding      text;
  vPaySystem    text;
BEGIN
  SELECT id INTO uClient FROM db.client WHERE userid = current_userid();

  IF uClient IS NULL THEN
    PERFORM AccessDenied();
  END IF;

  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  vMaskedPan := SubStr(pCode, 1, 6) || 'XXXXXX' || SubStr(pCode, 13, 4);

  SELECT id, binding INTO uCard, vBinding FROM db.card WHERE client = uClient AND code = vMaskedPan;

  IF uCard IS NULL THEN
    uCard := CreateCard(uClient, GetType('credit.card'), uClient, vMaskedPan, pName, pExpiry, null, coalesce(pLabel, pName), pDescription);
  ELSE
    IF IsEnabled(uCard) AND vBinding IS NOT NULL THEN
      RAISE EXCEPTION 'ERR-40000: The card % is already binding.', vMaskedPan;
    END IF;

    PERFORM EditCard(uCard, uClient, GetType('credit.card'), uClient, vMaskedPan, pName, pExpiry, null, coalesce(pLabel, pName), coalesce(pDescription, ''));

    IF IsDisabled(uCard) THEN
      PERFORM DoDelete(uCard);
    END IF;

    IF IsDeleted(uCard) THEN
      PERFORM DoRestore(uCard);
    END IF;
  END IF;

  IF vPaySystem = 'cloudpayments' THEN
    PERFORM CP_BindCard(uCard, pData);
  ELSIF vPaySystem = 'yookassa' THEN
    PERFORM YK_CreateBindingPayment(uCard, pCode, pExpiry, pName, pHidden, coalesce(pDescription, pLabel));
  ELSE
    RAISE EXCEPTION 'E-4000: Unknown or not selected payment system';
  END IF;

  RETURN json_build_object('ok', true, 'status', 'InProgress');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.unbind_card -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Unbinds a card from the current user
 * @param {uuid} pId - Record identifier
 * @param {text} pCode - Code
 * @return {json}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.unbind_card (
  pId           uuid,
  pCode         text
) RETURNS       json
AS $$
DECLARE
  uClient       uuid;
  uCard         uuid;
  vPaySystem    text;
  status        json;
BEGIN
  status := json_build_object('ok', false, 'status', 'NotFound');

  SELECT id INTO uClient FROM db.client WHERE userid = current_userid();

  IF uClient IS NULL THEN
    PERFORM AccessDenied();
  END IF;

  pCode := SubStr(pCode, 1, 6) || 'XXXXXX' || SubStr(pCode, 13, 4);

  IF pId IS NOT NULL THEN
    SELECT id INTO uCard FROM db.card WHERE id = pId;
  ELSE
    SELECT id INTO uCard FROM db.card WHERE client = uClient AND code = pCode;
  END IF;

  IF uCard IS NOT NULL THEN
	vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

	IF vPaySystem = 'cloudpayments' THEN
	  IF IsActive(uCard) THEN
        status := json_build_object('ok', true, 'status', 'Success');
		PERFORM DoDisable(uCard);
	  END IF;
	ELSIF vPaySystem = 'yookassa' THEN
	  IF IsActive(uCard) THEN
        status := json_build_object('ok', true, 'status', 'Success');
		PERFORM DoDisable(uCard);
	  END IF;
	ELSIF vPaySystem = 't-kassa' THEN
	  IF IsActive(uCard) THEN
        status := json_build_object('ok', true, 'status', 'Success');
		PERFORM DoDisable(uCard);
	  END IF;
    ELSE
      RAISE EXCEPTION 'E-4000: Unknown or not selected payment system';
	END IF;
  END IF;

  RETURN status;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
