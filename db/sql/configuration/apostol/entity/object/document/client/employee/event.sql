--------------------------------------------------------------------------------
-- EMPLOYEE --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventEmployeeCreate ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the employee creation event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventEmployeeCreate (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  IF NOT IsUserRole(GetGroup('administrator')) THEN
	PERFORM AccessDenied();
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'create', 'Employee created.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventEmployeeOpen -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the employee open event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventEmployeeOpen (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Employee opened for viewing.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventEmployeeEdit -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the employee edit event
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventEmployeeEdit (
  pObject	uuid default context_object(),
  pParams	jsonb default context_params()
) RETURNS	void
AS $$
DECLARE
  r             record;

  uUserId       uuid;
  uInterface    uuid;

  old_type      text;
  new_type      text;
BEGIN
  IF NOT IsUserRole(GetGroup('administrator')) THEN
	PERFORM AccessDenied();
  END IF;

  old_type = pParams#>'{old, typecode}';
  new_type = pParams#>'{new, typecode}';

  SELECT userid INTO uUserId FROM db.client WHERE id = pObject;

  IF uUserId IS NOT NULL THEN
    IF old_type = 'accountant.employee' THEN
      PERFORM DeleteGroupForMember(uUserId, GetGroup('accountant'));
      PERFORM DeleteInterfaceForMember(uUserId, GetInterface('accountant'));
	END IF;

    IF new_type = 'accountant.employee' THEN
      PERFORM AddMemberToGroup(uUserId, GetGroup('accountant'));
      uInterface := GetInterface('accountant');
	END IF;

    IF old_type = 'admin.employee' THEN
      IF NOT IsUserRole(GetGroup('administrator')) THEN
        PERFORM AccessDenied();
      END IF;

      PERFORM DeleteGroupForMember(uUserId, GetGroup('administrator'));
      PERFORM DeleteInterfaceForMember(uUserId, GetInterface('administrator'));
	END IF;

    IF new_type = 'admin.employee' THEN
      PERFORM AddMemberToGroup(uUserId, GetGroup('administrator'));
      uInterface := GetInterface('administrator');
	END IF;

    IF uInterface IS NOT NULL THEN
      PERFORM SetDefaultInterface(uInterface, uUserId);

      FOR r IN SELECT code FROM db.session WHERE userid = uUserId
      LOOP
        PERFORM SetInterface(uInterface, uUserId, r.code);
      END LOOP;
    END IF;
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'edit', 'Employee modified.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventEmployeeSave -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the employee save event
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pParams - Report parameters
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventEmployeeSave (
  pObject	uuid default context_object(),
  pParams   jsonb default context_params()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Employee saved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventEmployeeEnable ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the employee enable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventEmployeeEnable (
  pObject	    uuid default context_object()
) RETURNS	    void
AS $$
DECLARE
  r             record;

  vTypeCode     text;

  uUserId       uuid;
  uInterface    uuid;
BEGIN
  IF NOT IsUserRole(GetGroup('administrator')) THEN
	PERFORM AccessDenied();
  END IF;

  vTypeCode := GetObjectTypeCode(pObject);

  SELECT userid INTO uUserId FROM db.client WHERE id = pObject;

  IF uUserId IS NOT NULL THEN
    PERFORM AddMemberToGroup(uUserId, GetGroup('employee'));
    uInterface := GetInterface('employee');

    IF vTypeCode = 'accountant.employee' THEN
      PERFORM AddMemberToGroup(uUserId, GetGroup('accountant'));
      uInterface := GetInterface('accountant');
	END IF;

    IF vTypeCode = 'admin.employee' THEN
      IF NOT IsUserRole(GetGroup('administrator')) THEN
        PERFORM AccessDenied();
      END IF;

      PERFORM AddMemberToGroup(uUserId, GetGroup('administrator'));
      uInterface := GetInterface('administrator');
	END IF;

    IF uInterface IS NOT NULL THEN
      PERFORM SetDefaultInterface(uInterface, uUserId);

      FOR r IN SELECT code FROM db.session WHERE userid = uUserId
      LOOP
        PERFORM SetInterface(uInterface, uUserId, r.code);
      END LOOP;
    END IF;
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'enable', 'Employee approved.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventEmployeeDisable --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the employee disable event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventEmployeeDisable (
  pObject	uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  IF NOT IsUserRole(GetGroup('administrator')) THEN
	PERFORM AccessDenied();
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'disable', 'Employee disabled.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventEmployeeDelete ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the employee delete event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventEmployeeDelete (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  IF NOT IsUserRole(GetGroup('administrator')) THEN
	PERFORM AccessDenied();
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'delete', 'Employee deleted.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventEmployeeRestore --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the employee restore event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventEmployeeRestore (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  IF NOT IsUserRole(GetGroup('administrator')) THEN
	PERFORM AccessDenied();
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'restore', 'Employee restored.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventEmployeeDrop -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Handles the employee drop (permanent deletion) event
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @throws AccessDenied
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EventEmployeeDrop (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r         record;
BEGIN
  IF NOT IsUserRole(GetGroup('administrator')) THEN
	PERFORM AccessDenied();
  END IF;

  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  PERFORM WriteToEventLog('W', 1000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '') || '] Сотрудник уничтожен.');
END;
$$ LANGUAGE plpgsql;
