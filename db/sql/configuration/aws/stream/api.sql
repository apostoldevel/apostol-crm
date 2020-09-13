--------------------------------------------------------------------------------
-- STERAM LOG ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.stream_log
AS
  SELECT * FROM streamLog;

GRANT SELECT ON api.stream_log TO administrator;

--------------------------------------------------------------------------------
-- api.get_stream_log ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает событие
 * @param {numeric} pId - Идентификатор
 * @return {api.stream}
 */
CREATE OR REPLACE FUNCTION api.get_stream_log (
  pId		numeric
) RETURNS	api.stream_log
AS $$
  SELECT * FROM api.stream_log WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_stream_log ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает журнал событий OCPP.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.stream}
 */
CREATE OR REPLACE FUNCTION api.list_stream_log (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.stream_log
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'stream_log', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
