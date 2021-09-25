--------------------------------------------------------------------------------
-- MODE ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.mode --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.mode
AS
  SELECT * FROM ObjectMode;

GRANT SELECT ON api.mode TO administrator;

--------------------------------------------------------------------------------
-- api.add_mode ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет режим.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {text} pType - Тип
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_mode (
  pParent       uuid,
  pType         text,
  pCode         text,
  pName         text,
  pDescription	text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateMode(pParent, CodeToType(lower(coalesce(pType, 'charger')), 'mode'), pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_mode -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует режим.
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {text} pType - Тип
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_mode (
  pId		    uuid,
  pParent       uuid default null,
  pType         text default null,
  pCode         text default null,
  pName         text default null,
  pDescription	text default null
) RETURNS       void
AS $$
DECLARE
  uType         uuid;
  nMode         uuid;
BEGIN
  SELECT t.id INTO nMode FROM db.mode t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('режим', 'id', pId);
  END IF;

  IF pType IS NOT NULL THEN
    uType := CodeToType(lower(pType), 'mode');
  ELSE
    SELECT o.type INTO uType FROM db.object o WHERE o.id = pId;
  END IF;

  PERFORM EditMode(nMode, pParent, uType,pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_mode ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_mode (
  pId           uuid,
  pParent       uuid default null,
  pType         text default null,
  pCode         text default null,
  pName         text default null,
  pDescription	text default null
) RETURNS       SETOF api.mode
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_mode(pParent, pType, pCode, pName, pDescription);
  ELSE
    PERFORM api.update_mode(pId, pParent, pType, pCode, pName, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.mode WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_mode ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает режим
 * @param {uuid} pId - Идентификатор
 * @return {api.mode}
 */
CREATE OR REPLACE FUNCTION api.get_mode (
  pId		uuid
) RETURNS	api.mode
AS $$
  SELECT * FROM api.mode WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_mode ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список режимов.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.mode}
 */
CREATE OR REPLACE FUNCTION api.list_mode (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.mode
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'mode', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
