--------------------------------------------------------------------------------
-- COMPANY ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventCompanyCreate ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the company creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCompanyCreate (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;

  uClient   uuid;
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Company created.', pObject);

  IF pObject != '00000000-0000-4003-a001-000000000000'::uuid THEN
	SELECT code, label, description INTO r FROM Company WHERE id = pObject;

    PERFORM FROM db.client WHERE code = r.code;

    IF NOT FOUND THEN
      uClient := CreateClient(pObject, GetType('company.client'), pObject, null_uuid(), r.code, r.label, null, null, null, null, null, null, null, null, null, r.code, null, null, null, null, null, null, null, r.description);
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCompanyOpen ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the company open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCompanyOpen (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Company opened for viewing.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCompanyEdit ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the company edit event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCompanyEdit (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Company modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCompanySave ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the company save event
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCompanySave (
  pObject   uuid default context_object(),
  pParams   jsonb default context_params()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Company saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCompanyEnable ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the company enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCompanyEnable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  FOR r IN
    SELECT t.id
      FROM db.client t INNER JOIN db.object o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000001'::uuid
     WHERE o.parent = pObject
  LOOP
    PERFORM ExecuteObjectAction(r.id, context_action());
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'enable', 'Company opened.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCompanyDisable ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the company disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCompanyDisable (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  FOR r IN
    SELECT t.id
      FROM db.client t INNER JOIN db.object o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
     WHERE o.parent = pObject
  LOOP
    PERFORM ExecuteObjectAction(r.id, context_action());
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'disable', 'Company closed.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCompanyDelete ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the company delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCompanyDelete (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  FOR r IN
    SELECT t.id
      FROM db.client t INNER JOIN db.object o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000004'::uuid
     WHERE o.parent = pObject
  LOOP
    PERFORM ExecuteObjectAction(r.id, context_action());
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'delete', 'Company deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCompanyRestore ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the company restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCompanyRestore (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Company restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventCompanyDrop ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the company drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventCompanyDrop (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  IF session_user <> 'admin' THEN
    IF NOT IsUserRole(GetGroup('su')) THEN
      PERFORM AccessDenied();
    END IF;
  END IF;

  FOR r IN SELECT id FROM db.client WHERE company = pObject
  LOOP
    IF NOT IsDeleted(r.id) THEN
      PERFORM DoDelete(r.id);
    END IF;
    PERFORM DoDrop(r.id);
  END LOOP;

  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.company WHERE id = pObject;

  PERFORM WriteToEventLog('M', 2000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Company dropped.');
END;
$$ LANGUAGE plpgsql;
