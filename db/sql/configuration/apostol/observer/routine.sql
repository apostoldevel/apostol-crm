--------------------------------------------------------------------------------
-- FUNCTION DoCheckListenerFilter ----------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Validate observer listener filter keys for a given publisher
 * @param {text} pPublisher - Publisher channel name ('confirmation', 'urgent')
 * @param {jsonb} pFilter - Filter object to validate
 * @return {void}
 * @throws InvalidJsonbKeys - When filter contains unsupported keys
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoCheckListenerFilter (
  pPublisher	text,
  pFilter		jsonb
) RETURNS		void
AS $$
DECLARE
  arFilter		text[];
BEGIN
  IF pPublisher = 'confirmation' THEN
  	arFilter := array_cat(arFilter, ARRAY['agents']);
  	PERFORM CheckJsonbKeys('/listener/confirmation/filter', arFilter, pFilter);
  ELSIF pPublisher = 'urgent' THEN
  	arFilter := array_cat(arFilter, ARRAY['events', 'reasons']);
  	PERFORM CheckJsonbKeys('/listener/urgent/filter', arFilter, pFilter);
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoCheckListenerParams ----------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Validate observer listener params and their allowed values for a given publisher
 * @param {text} pPublisher - Publisher channel name ('confirmation', 'urgent')
 * @param {jsonb} pParams - Params object to validate (must contain 'type' with value 'notify')
 * @return {void}
 * @throws InvalidJsonbKeys - When params contains unsupported keys
 * @throws IncorrectValueInArray - When 'type' value is not in the allowed set
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoCheckListenerParams (
  pPublisher	text,
  pParams		jsonb
) RETURNS		void
AS $$
DECLARE
  type			text;

  arParams		text[];
  arValues      text[];
BEGIN
  IF pPublisher = 'confirmation' THEN
	arParams := array_cat(null, ARRAY['type']);
	PERFORM CheckJsonbKeys('/listener/confirmation/params', arParams, pParams);

	type := pParams->>'type';

	arValues := array_cat(null, ARRAY['notify']);
	IF NOT type = ANY (arValues) THEN
	  PERFORM IncorrectValueInArray(coalesce(type, '<null>'), 'type', arValues);
	END IF;
  ELSIF pPublisher = 'urgent' THEN
	arParams := array_cat(null, ARRAY['type']);
	PERFORM CheckJsonbKeys('/listener/urgent/params', arParams, pParams);

	type := pParams->>'type';

	arValues := array_cat(null, ARRAY['notify']);
	IF NOT type = ANY (arValues) THEN
	  PERFORM IncorrectValueInArray(coalesce(type, '<null>'), 'type', arValues);
	END IF;
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoFilterListener ---------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Apply listener filter logic to determine if an event should be delivered to a subscriber
 * @param {text} pPublisher - Publisher channel name ('confirmation', 'urgent')
 * @param {text} pSession - Session code of the subscriber
 * @param {text} pIdentity - Listener identity within the session
 * @param {jsonb} pData - Event data to filter against
 * @return {boolean} - true if the event passes the filter and should be delivered
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoFilterListener (
  pPublisher	text,
  pSession		text,
  pIdentity		text,
  pData			jsonb
) RETURNS		boolean
AS $$
DECLARE
  r				record;
  f				record;
  d				record;
  p				record;

  uUserId		uuid;
  uClient		uuid;
BEGIN
  SELECT userid INTO uUserId FROM db.session WHERE code = pSession;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  SELECT filter, params INTO r FROM db.listener WHERE publisher = pPublisher AND session = pSession AND identity = pIdentity;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  IF pData IS NULL THEN
    RETURN false;
  END IF;

  IF pPublisher = 'confirmation' THEN
	SELECT * INTO f FROM jsonb_to_record(r.filter) AS x(agents jsonb, clients jsonb, cards jsonb);
	SELECT * INTO d FROM jsonb_to_record(pData) AS x(agent uuid, payment uuid);

    SELECT card, client, invoice INTO p FROM db.payment WHERE id = d.payment;
    SELECT id INTO uClient FROM db.client WHERE userid = uUserId;

	RETURN coalesce(d.agent = ANY (JsonbToUUIDArray(f.agents)), true)
       AND coalesce(p.client = ANY (JsonbToUUIDArray(f.clients)), true)
       AND coalesce(p.card = ANY (JsonbToUUIDArray(f.cards)), true)
	   AND p.client = uClient
  	   AND CheckObjectAccess(coalesce(p.card, p.invoice), B'100', uUserId);
  ELSIF pPublisher = 'urgent' THEN
	SELECT * INTO f FROM jsonb_to_record(r.filter) AS x(events jsonb, reasons jsonb);
	SELECT * INTO d FROM jsonb_to_record(pData) AS x(userid uuid, event text, reason text);

	RETURN d.userid = uUserId
	   AND coalesce(d.event = ANY (JsonbToStrArray(f.events)), true)
	   AND coalesce(d.reason = ANY (JsonbToStrArray(f.reasons)), true);
  END IF;

  RETURN false;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoEventListener ----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Transform event data for delivery to a subscriber
 * @param {text} pPublisher - Publisher channel name ('confirmation', 'urgent')
 * @param {varchar} pSession - Session code of the subscriber
 * @param {text} pIdentity - Listener identity within the session
 * @param {jsonb} pData - Raw event data from the publisher
 * @return {SETOF json} - Transformed event data as JSON for the subscriber
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoEventListener (
  pPublisher    text,
  pSession      varchar,
  pIdentity     text,
  pData         jsonb
) RETURNS       SETOF json
AS $$
DECLARE
  e             record;
BEGIN
  IF pPublisher = 'confirmation' THEN
	FOR e IN SELECT * FROM api.confirmation WHERE id = (pData->>'id')::uuid
	LOOP
	  RETURN NEXT row_to_json(e);
	END LOOP;
  ELSIF pPublisher = 'urgent' THEN
    RETURN NEXT pData::json;
  ELSE
    RETURN NEXT pData;
  END IF;

  RETURN;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
