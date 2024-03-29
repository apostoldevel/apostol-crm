--------------------------------------------------------------------------------
-- CATEGORY --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.category ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.category
AS
  SELECT * FROM ObjectCategory;

GRANT SELECT ON api.category TO administrator;

--------------------------------------------------------------------------------
-- api.add_category ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет категорию.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Идентификатор типа
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_category (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription    text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateCategory(pParent, coalesce(pType, GetType('service.category')), pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_category ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует категорию.
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Идентификатор типа
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_category (
  pId            uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription    text default null
) RETURNS       void
AS $$
DECLARE
  uCategory        uuid;
BEGIN
  SELECT t.id INTO uCategory FROM db.category t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('категория', 'id', pId);
  END IF;

  PERFORM EditCategory(uCategory, pParent, pType, pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_category ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_category (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription    text default null
) RETURNS       SETOF api.category
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_category(pParent, pType, pCode, pName, pDescription);
  ELSE
    PERFORM api.update_category(pId, pParent, pType, pCode, pName, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.category WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_category ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает категорию
 * @param {uuid} pId - Идентификатор
 * @return {api.category}
 */
CREATE OR REPLACE FUNCTION api.get_category (
  pId        uuid
) RETURNS    api.category
AS $$
  SELECT * FROM api.category WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_category -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список категорий.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.category}
 */
CREATE OR REPLACE FUNCTION api.list_category (
  pSearch    jsonb default null,
  pFilter    jsonb default null,
  pLimit    integer default null,
  pOffSet    integer default null,
  pOrderBy    jsonb default null
) RETURNS    SETOF api.category
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'category', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_category_id ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает uuid по коду.
 * @param {text} pCode - Код категории
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.get_category_id (
  pCode        text
) RETURNS    uuid
AS $$
BEGIN
  RETURN GetCategory(pCode);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
