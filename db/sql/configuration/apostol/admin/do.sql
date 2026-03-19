--------------------------------------------------------------------------------
-- FUNCTION DoLogin ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Handle post-login area resolution and access control for a user.
 * @param {uuid} pUserId - User identifier to resolve the working area for
 * @return {void}
 * @throws AccessDenied - When the session agent is a Python client
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoLogin (
  pUserId   uuid
) RETURNS   void
AS $$
DECLARE
  uArea     uuid;
  uType     uuid;
BEGIN
  SELECT area INTO uArea FROM db.profile WHERE userid = pUserId AND scope = current_scope();

  IF NOT FOUND THEN
    uArea := GetArea(current_database()::text, GetScope(current_database()::text));
  ELSE
    SELECT type INTO uType FROM db.area WHERE id = uArea;
    IF uType NOT IN ('00000000-0000-4002-a001-000000000001', '00000000-0000-4002-a001-000000000002', '00000000-0000-4002-a001-000000000003') THEN -- main, remote, mobile
      uArea := current_company();
    END IF;

    IF current_application_code() = 'web' AND IsUserRole(GetGroup('system'), pUserId) THEN
      IF uType = '00000000-0000-4002-a000-000000000002' THEN -- guest
        uArea := current_company();
      END IF;
    END IF;
  END IF;

  IF IsMemberArea(uArea, pUserId) THEN
    PERFORM SetArea(uArea, pUserId);
  END IF;

  -- Block access from Python-based automation agents
  PERFORM FROM db.session WHERE code = current_session() AND agent ILIKE 'python-%';
  IF FOUND THEN
    PERFORM AccessDenied();
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoLogout -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Handle post-logout cleanup for a user session.
 * @param {uuid} pUserId - User identifier of the user logging out
 * @return {void}
 * @see DoLogin
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoLogout (
  pUserId   uuid
) RETURNS   void
AS $$
BEGIN
  RETURN;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoCreateArea -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Handle post-creation hook for a new area (organizational unit).
 * @param {uuid} pArea - Identifier of the newly created area
 * @return {void}
 * @see DoUpdateArea, DoDeleteArea
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoCreateArea (
  pArea         uuid
) RETURNS       void
AS $$
DECLARE
  vMessage      text;
  vContext      text;
BEGIN
  RETURN;
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
  PERFORM WriteDiagnostics(vMessage, vContext);
END;
  $$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoUpdateArea -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Handle post-update hook for an area (organizational unit).
 * @param {uuid} pArea - Identifier of the updated area
 * @return {void}
 * @see DoCreateArea, DoDeleteArea
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoUpdateArea (
  pArea         uuid
) RETURNS       void
AS $$
DECLARE
  vMessage      text;
  vContext      text;
BEGIN
  RETURN;
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
  PERFORM WriteDiagnostics(vMessage, vContext);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoDeleteArea -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Validate and handle pre-deletion check for an area (organizational unit).
 * @param {uuid} pArea - Identifier of the area to be deleted
 * @return {void}
 * @see DoCreateArea, DoUpdateArea
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoDeleteArea (
  pArea         uuid
) RETURNS       void
AS $$
BEGIN
  -- Prevent deletion if the area still contains documents
  PERFORM FROM db.document WHERE area = pArea;

  IF FOUND THEN
    RAISE EXCEPTION 'ERR-40000: Operation aborted. The area contains documents.';
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoCreateRole -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Handle post-creation hook for a new user role.
 * @param {uuid} pRole - Identifier of the newly created role (user)
 * @return {void}
 * @see DoUpdateRole, DoDeleteRole
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoCreateRole (
  pRole     uuid
) RETURNS   void
AS $$
BEGIN
  RETURN;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoUpdateRole -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Synchronize client code with the updated username when a role is modified.
 * @param {uuid} pRole - Identifier of the updated role (user)
 * @return {void}
 * @see DoCreateRole, DoDeleteRole
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoUpdateRole (
  pRole     uuid
) RETURNS   void
AS $$
DECLARE
  u         record;
  c         record;
BEGIN
  SELECT * INTO u FROM db.user WHERE id = pRole;
  SELECT * INTO c FROM db.client WHERE userId = pRole;

  IF u.username <> c.code THEN
	PERFORM EditClient(c.id, pCode => u.username);
  END IF;

  RETURN;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoDeleteRole -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Detach and soft-delete the linked client record when a role is removed.
 * @param {uuid} pRole - Identifier of the role (user) being deleted
 * @return {void}
 * @see DoCreateRole, DoUpdateRole
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoDeleteRole (
  pRole     uuid
) RETURNS   void
AS $$
DECLARE
  uId       uuid;
BEGIN
  SELECT id INTO uId FROM db.client WHERE userid = pRole;
  IF FOUND THEN
    UPDATE db.client SET userid = null WHERE id = uId;
    IF NOT IsDeleted(uId) THEN
      PERFORM DoDelete(uId);
    END IF;
  END IF;
  RETURN;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- DoFCMTokens -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Collect Firebase Cloud Messaging tokens for a user across all active mobile devices.
 * @param {uuid} pUserId - User identifier to retrieve FCM tokens for
 * @return {text[]} - Array of FCM registration tokens (from devices or registry fallback)
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DoFCMTokens (
  pUserId       uuid
) RETURNS       text[]
AS $$
DECLARE
  r             record;

  uType         uuid;
  uClient       uuid;

  result        text[];
BEGIN
  uType := GetType('mobile.device');

  SELECT c.id INTO uClient FROM db.client c WHERE c.userid = pUserId;

  IF NOT FOUND THEN
    result := array_append(result, RegGetValueString('CURRENT_USER', 'CONFIG\Firebase\CloudMessaging', 'Token', pUserId));
  ELSE
    FOR r IN
      SELECT identifier
        FROM db.device t INNER JOIN db.object o ON o.id = t.document
       WHERE t.client = uClient
         AND o.type = uType
         AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
    LOOP
      result := array_append(result, r.identifier);
    END LOOP;
  END IF;

  RETURN result;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
