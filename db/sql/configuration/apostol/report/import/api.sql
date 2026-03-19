--------------------------------------------------------------------------------
-- API IMPORT ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Submit data for asynchronous import via the report engine
 * @param {jsonb} pPayload - Import data payload in JSON format
 * @return {jsonb} - Result object: {ok, report_id, status} on success; {ok, status, message} on failure
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.import (
  pPayload  jsonb
) RETURNS   jsonb
AS $$
DECLARE
  uReady    uuid;
  data      text;
  file      jsonb;

  vMessage  text;
  vContext  text;
BEGIN
  data := encode(convert_to(jsonb_pretty(pPayload), 'utf8'), 'base64');

  file := jsonb_build_object('data', data, 'date', Now(), 'name', 'import.json', 'size', length(data), 'text', 'Входной реестр для загрузки в формате JSON', 'type', 'data:application/json;base64,');

  uReady := BuildReport(GetReport('import_data'), GetType('async.report_ready'), jsonb_build_object('format', 'json', 'files', jsonb_build_array(file)));

  RETURN jsonb_build_object('ok', true, 'report_id', uReady, 'status', 'progress');
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
  PERFORM WriteDiagnostics(vMessage, vContext, uReady);

  RETURN jsonb_build_object('ok', false, 'status', 'failed', 'message', vMessage);
END;
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, pg_temp;
