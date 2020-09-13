--------------------------------------------------------------------------------
-- stream.log ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE stream.log (
    id          numeric PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_STREAM_LOG'),
    datetime	timestamptz DEFAULT clock_timestamp() NOT NULL,
    username	text NOT NULL DEFAULT session_user,
    protocol    text NOT NULL,
    identity	text NOT NULL,
    request     bytea,
    response	bytea,
    runtime     interval
);

COMMENT ON TABLE stream.log IS 'Лог OCPP.';

COMMENT ON COLUMN stream.log.id IS 'Идентификатор';
COMMENT ON COLUMN stream.log.datetime IS 'Дата и время';
COMMENT ON COLUMN stream.log.username IS 'Пользователь СУБД';
COMMENT ON COLUMN stream.log.protocol IS 'Протокол';
COMMENT ON COLUMN stream.log.identity IS 'Идентификатор';
COMMENT ON COLUMN stream.log.request IS 'Запрос';
COMMENT ON COLUMN stream.log.response IS 'Ответ';
COMMENT ON COLUMN stream.log.runtime IS 'Время выполнения запроса';

CREATE INDEX ON stream.log (protocol);
CREATE INDEX ON stream.log (identity);
CREATE INDEX ON stream.log (datetime);

--------------------------------------------------------------------------------
-- stream.WriteToLog -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.WriteToLog (
  pProtocol	text,
  pIdentity	text,
  pRequest	bytea default null,
  pResponse	bytea default null,
  pRunTime	interval default null
) RETURNS	numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  INSERT INTO stream.log (protocol, identity, request, response, runtime)
  VALUES (pProtocol, pIdentity, pRequest, pResponse, pRunTime)
  RETURNING id INTO nId;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.ClearLog -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.ClearLog (
  pDateTime	timestamptz
) RETURNS	void
AS $$
BEGIN
  DELETE FROM stream.log WHERE datetime < pDateTime;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- VIEW streamLog --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW streamLog (Id, DateTime, UserName, Protocol,
  Identity, Request, RequestLength, Response, ResponseLength, RunTime)
AS
  SELECT id, datetime, username, protocol, identity,
         encode(request, 'hex'), octet_length(request),
         encode(response, 'hex'), octet_length(response),
         round(extract(second from runtime)::numeric, 3)
    FROM stream.log;

--------------------------------------------------------------------------------
-- stream.SetSession -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.SetSession (
) RETURNS       text
AS $$
DECLARE
  nUserId       numeric;
  nArea         numeric;
  nInterface	numeric;

  vSession      text;
BEGIN
  IF session_user <> 'stream' THEN
    PERFORM AccessDeniedForUser(session_user);
  END IF;

  nUserId := GetUser('stream');

  IF nUserId IS NOT NULL THEN
    SELECT code INTO vSession FROM db.session WHERE userid = nUserId;

    IF NOT FOUND THEN
      nArea := GetDefaultArea(nUserId);
      nInterface := GetDefaultInterface(nUserId);

      INSERT INTO db.session (userid, area, interface, oauth2)
      VALUES (nUserId, nArea, nInterface, CreateSystemOAuth2())
      RETURNING code INTO vSession;
    END IF;

    PERFORM SetCurrentSession(vSession);
    PERFORM SetCurrentUserId(nUserId);
  END IF;

  RETURN vSession;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.lpwan ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.lpwan (
  pRequest          bytea,
  OUT identity      text,
  OUT response      bytea
) RETURNS           record
AS $$
BEGIN
  identity := null;
  response := null;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.Parse ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Разбор пакета.
 * @param {text} pProtocol - Протокол (формат данных)
 * @param {text} pBase64 - Данные в формате BASE64
 * @return {text} - Ответ в формате BASE64
 */
CREATE OR REPLACE FUNCTION stream.Parse (
  pProtocol	text,
  pBase64       text
) RETURNS	text
AS $$
DECLARE
  vIdentity	text;

  tsBegin	timestamp;

  vError	text;
  vSession	text DEFAULT 'Успешно.';

  bRequest	bytea;
  bResponse	bytea;
BEGIN
  vSession := stream.SetSession();

  tsBegin := clock_timestamp();

  bRequest = decode(pBase64, 'base64');

  CASE pProtocol
  WHEN 'lpwan' THEN

    SELECT identity, response INTO vIdentity, bResponse FROM stream.lpwan(bRequest);

  ELSE
    PERFORM UnknownProtocol(pProtocol);
  END CASE;

  PERFORM stream.WriteTolog(pProtocol, coalesce(vIdentity, 'null'), bRequest, bResponse, age(clock_timestamp(), tsBegin));

  RETURN encode(bResponse, 'base64');
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vError = MESSAGE_TEXT;

  PERFORM SetErrorMessage(vError);

  PERFORM kernel.WriteToEventLog('E', 8000, vError);

  RETURN null;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
