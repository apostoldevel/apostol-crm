--------------------------------------------------------------------------------
-- REST IMPORT -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief REST JSON API dispatcher for data import
 * @param {text} pPath - Request path (e.g., '/import/<object>/<file>')
 * @param {jsonb} pPayload - Import data payload
 * @return {SETOF json} - Response records as JSON
 * @throws RouteIsEmpty - When pPath is NULL
 * @throws JsonIsEmpty - When pPayload is NULL
 * @throws RouteNotFound - When pPath does not start with '/import'
 * @throws AudienceNotFound - When system OAuth2 audience is not configured
 * @see api.import
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION rest.import (
  pPath         text,
  pPayload      jsonb default null
) RETURNS       SETOF json
AS $$
DECLARE
  vObject       text;
  vFile         text;

  vSession      text;
  vOAuthClient  text;
  vOAuthSecret  text;
BEGIN
  IF pPath IS NULL THEN
    PERFORM RouteIsEmpty();
  END IF;

  IF split_part(pPath, '/', 2) = 'import' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    vObject := split_part(pPath, '/', 3);
    vFile := split_part(pPath, '/', 4);

    IF vObject IS NOT NULL THEN
      pPayload := pPayload || jsonb_build_object('object', vObject);
    END IF;

    IF vFile IS NOT NULL THEN
      pPayload := pPayload || jsonb_build_object('file', vFile);
    END IF;

    SELECT code, secret INTO vOAuthClient, vOAuthSecret FROM oauth2.audience WHERE id = 1;
  
    IF FOUND THEN
      vSession := SignIn(CreateSystemOAuth2(), vOAuthClient, vOAuthSecret);
      PERFORM SubstituteUser('apibot', vOAuthSecret);
    END IF;
    
    RETURN NEXT api.import(pPayload);
  ELSE
    PERFORM RouteNotFound(pPath);
  END IF;

  RETURN;
END;
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, pg_temp;
