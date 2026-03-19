--------------------------------------------------------------------------------
-- REST API CALLBACK -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief REST JSON API callback dispatcher for service reports
 * @param {text} pPath - Request path (e.g., '/callback/service/<report>')
 * @param {jsonb} pPayload - Request payload
 * @return {SETOF json} - Response records as JSON
 * @throws AudienceNotFound - When system OAuth2 audience is not configured
 * @throws RouteNotFound - When the path does not match any handler
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION rest.callback (
  pPath         text,
  pPayload      jsonb DEFAULT null
) RETURNS       SETOF json
AS $$
DECLARE
  vReport       text;

  vSession      text;
  vOAuthClient  text;
  vOAuthSecret  text;
BEGIN
  IF NULLIF(pPath, '') IS NULL THEN
    PERFORM RouteIsEmpty();
  END IF;

  SELECT a.code, a.secret INTO vOAuthClient, vOAuthSecret FROM oauth2.audience a WHERE a.code = current_database();

  IF FOUND THEN
    vSession := SignIn(CreateSystemOAuth2(), vOAuthClient, vOAuthSecret);

    PERFORM SubstituteUser(GetUser('apibot'), vOAuthSecret);

    IF split_part(pPath, '/', 3) = 'service' THEN

      vReport := split_part(pPath, '/', 4);

      IF vReport IS NULL THEN
        RETURN NEXT json_build_object('ok', api.service_callback(pPayload));
      ELSE
        RETURN NEXT json_build_object('ok', api.service_callback(pPayload || jsonb_build_object('report', vReport)));
      END IF;

    ELSE
      PERFORM SubstituteUser(session_userid(), vOAuthSecret);
      PERFORM SessionOut(vSession, false);

      PERFORM RouteNotFound(pPath);
    END IF;

    PERFORM SubstituteUser(session_userid(), vOAuthSecret);
    PERFORM SessionOut(vSession, false);

  ELSE
    PERFORM AudienceNotFound();
  END IF;

  RETURN;
END;
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, pg_temp;
