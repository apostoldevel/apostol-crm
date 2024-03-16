--------------------------------------------------------------------------------
-- MEASURE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.measure -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.measure
AS
  SELECT * FROM ObjectMeasure;

GRANT SELECT ON api.measure TO administrator;

--------------------------------------------------------------------------------
-- api.add_measure -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет меру.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Идентификатор типа
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_measure (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription    text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateMeasure(pParent, coalesce(pType, GetType('time.measure')), pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_measure ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует меру.
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Идентификатор типа
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_measure (
  pId            uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription    text default null
) RETURNS       void
AS $$
DECLARE
  uMeasure        uuid;
BEGIN
  SELECT t.id INTO uMeasure FROM db.measure t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('мера', 'id', pId);
  END IF;

  PERFORM EditMeasure(uMeasure, pParent, pType, pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_measure -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_measure (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription    text default null
) RETURNS       SETOF api.measure
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_measure(pParent, pType, pCode, pName, pDescription);
  ELSE
    PERFORM api.update_measure(pId, pParent, pType, pCode, pName, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.measure WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_measure -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает меру
 * @param {uuid} pId - Идентификатор
 * @return {api.measure}
 */
CREATE OR REPLACE FUNCTION api.get_measure (
  pId        uuid
) RETURNS    api.measure
AS $$
  SELECT * FROM api.measure WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_measure ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список мер.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.measure}
 */
CREATE OR REPLACE FUNCTION api.list_measure (
  pSearch    jsonb default null,
  pFilter    jsonb default null,
  pLimit    integer default null,
  pOffSet    integer default null,
  pOrderBy    jsonb default null
) RETURNS    SETOF api.measure
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'measure', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
