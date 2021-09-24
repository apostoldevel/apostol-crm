--------------------------------------------------------------------------------
-- FUNCTION DoLogin ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DoLogin (
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
-- FUNCTION DoLogout -----------------------------------------------------------
--------------------------------------------------------------------------------

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

CREATE OR REPLACE FUNCTION DoCreateArea (
  pArea         uuid
) RETURNS       void
AS $$
DECLARE
  r             record;

  vMessage      text;
  vContext      text;

  ErrorCode     int;
  ErrorMessage  text;
BEGIN
  SELECT * INTO r FROM Area WHERE id = pArea;

  PERFORM SetVar('object', 'id', r.id);
  PERFORM DoEnable(CreateClient(null, GetType('subdivision.client'), r.code, null, jsonb_build_object('name', r.name), null, null, null, null, r.description));
  PERFORM SetVar('object', 'id', null);
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetVar('object', 'id', null);

  PERFORM SetErrorMessage(vMessage);

  SELECT * INTO ErrorCode, ErrorMessage FROM ParseMessage(vMessage);

  PERFORM WriteToEventLog('E', ErrorCode, ErrorMessage);
  PERFORM WriteToEventLog('D', ErrorCode, vContext);
END;
  $$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoUpdateArea -------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DoUpdateArea (
  pArea         uuid
) RETURNS       void
AS $$
DECLARE
  r             record;

  vMessage      text;
  vContext      text;

  ErrorCode     int;
  ErrorMessage  text;
BEGIN
  SELECT * INTO r FROM Area WHERE id = pArea;
  PERFORM EditClient(r.id, null, GetType('subdivision.client'), r.code, null, r.name, null, null, null, null, r.description);
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetErrorMessage(vMessage);

  SELECT * INTO ErrorCode, ErrorMessage FROM ParseMessage(vMessage);

  PERFORM WriteToEventLog('E', ErrorCode, ErrorMessage);
  PERFORM WriteToEventLog('D', ErrorCode, vContext);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoDeleteArea -------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DoDeleteArea (
  pArea     uuid
) RETURNS   void
AS $$
BEGIN
  RETURN;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoCreateRole -------------------------------------------------------
--------------------------------------------------------------------------------

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

CREATE OR REPLACE FUNCTION DoUpdateRole (
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
-- FUNCTION DoDeleteRole -------------------------------------------------------
--------------------------------------------------------------------------------

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
