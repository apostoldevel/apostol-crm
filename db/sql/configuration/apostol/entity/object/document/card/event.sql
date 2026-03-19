--------------------------------------------------------------------------------
-- CARD ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventCardCreate -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the card creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCardCreate (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Card created.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCardOpen ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the card open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCardOpen (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Card opened.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCardEdit ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the card edit event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCardEdit (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Card modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCardSave ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the card save event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCardSave (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Card saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCardEnable -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the card enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @throws CardNotAssociated
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCardEnable (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  uClient       uuid;
  vPaySystem    text;
BEGIN
  SELECT client INTO uClient FROM db.card WHERE id = pObject;

  IF uClient IS NULL THEN
    PERFORM CardNotAssociated(GetCardCode(pObject));
  END IF;

  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  IF vPaySystem = 'yookassa' THEN
    PERFORM SetObjectDataJSON(uClient, 'bindings', GetCardBindingsJson(uClient));
  ELSIF vPaySystem = 't-kassa' THEN
    PERFORM SetObjectDataJSON(uClient, 'bindings', GetCardBindingsJson(uClient));
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'enable', 'Card enabled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCardDisable ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the card disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCardDisable (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  uClient       uuid;
  uAccount      uuid;

  nAmount       numeric;

  vPaySystem    text;
BEGIN
  SELECT client INTO uClient FROM db.card WHERE id = pObject;

  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  PERFORM FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid WHERE t.client = uClient;

  IF FOUND THEN
    RAISE EXCEPTION 'ERR-40000: Incomplete transactions found. Operation aborted.';
  END IF;

  uAccount := GetClientAccount(uClient, DefaultCurrency(), '200');
  nAmount := coalesce(GetBalance(uAccount), 0);

  IF nAmount <> 0 THEN
    RAISE EXCEPTION 'ERR-40000: Outstanding debt for services found. Operation aborted.';
  END IF;

  UPDATE db.card SET binding = null WHERE id = pObject;

  PERFORM ClearCardData(pObject, GetAgent(vPaySystem || '.agent'));
  PERFORM SetObjectDataJSON(uClient, 'bindings', GetCardBindingsJson(uClient));

  PERFORM WriteToEventLog('M', 1000, 'disable', 'Card closed.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCardDelete -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the card delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCardDelete (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  uClient       uuid;
  vPaySystem    text;
BEGIN
  vPaySystem := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem');

  SELECT client INTO uClient FROM db.card WHERE id = pObject;
  UPDATE db.card SET binding = null WHERE id = pObject;

  PERFORM ClearCardData(pObject, GetAgent(vPaySystem || '.agent'));
  PERFORM SetObjectDataJSON(uClient, 'bindings', GetCardBindingsJson(uClient));
  PERFORM SetObjectData(pObject, 'text', 'Version', null);

  PERFORM WriteToEventLog('M', 1000, 'delete', 'Card deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCardRestore ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the card restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCardRestore (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Card restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCardDrop ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the card drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCardDrop (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  r             record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.card WHERE id = pObject;

  PERFORM WriteToEventLog('M', 2000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Card dropped.');
END;
$$ LANGUAGE plpgsql;
