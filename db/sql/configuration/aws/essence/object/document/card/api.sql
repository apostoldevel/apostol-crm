--------------------------------------------------------------------------------
-- CARD ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.card --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.card
AS
  SELECT * FROM ObjectCard;

GRANT SELECT ON api.card TO administrator;

--------------------------------------------------------------------------------
-- api.add_card ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет карту.
 * @param {numeric} pParent - Ссылка на родительский объект: api.document | null
 * @param {varchar} pType - Tип карты
 * @param {numeric} pClient - Идентификатор
 * @param {varchar} pCode - Код
 * @param {text} pName - Наименование
 * @param {date} pExpire - Дата окончания
 * @param {text} pDescription - Описание
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.add_card (
  pParent       numeric,
  pType         varchar,
  pClient       numeric,
  pCode         varchar,
  pName         text default null,
  pExpire       date default null,
  pDescription  text default null
) RETURNS       numeric
AS $$
BEGIN
  RETURN CreateCard(pParent, CodeToType(lower(coalesce(pType, 'rfid')), 'card'), pClient, pCode, pName, pExpire, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_card -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет данные карты.
 * @param {numeric} pId - Идентификатор карты (api.get_card)
 * @param {numeric} pParent - Ссылка на родительский объект: api.document | null
 * @param {varchar} pType - Tип карты
 * @param {numeric} pClient - Идентификатор
 * @param {varchar} pCode - Код
 * @param {text} pName - Наименование
 * @param {date} pExpire - Дата окончания
 * @param {text} pDescription - Описание
 * @out param {numeric} id - Идентификатор карты
 * @out param {boolean} result - Результат
 * @out param {text} message - Текст ошибки
 * @return {record}
 */
CREATE OR REPLACE FUNCTION api.update_card (
  pId           numeric,
  pParent       numeric,
  pType         varchar,
  pClient       numeric,
  pCode         varchar,
  pName         text default null,
  pExpire       date default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  nType         numeric;
  nCard         numeric;
BEGIN
  SELECT c.id INTO nCard FROM db.card c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('карта', 'id', pId);
  END IF;

  IF pType IS NOT NULL THEN
    nType := CodeToType(lower(pType), 'card');
  ELSE
    SELECT o.type INTO nType FROM db.object o WHERE o.id = pId;
  END IF;

  PERFORM EditCard(nCard, pParent, nType, pClient,pCode, pName, pExpire, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_card ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_card (
  pId           numeric,
  pParent       numeric,
  pType         varchar,
  pClient       numeric,
  pCode         varchar,
  pName         text default null,
  pExpire       date default null,
  pDescription  text default null
) RETURNS       numeric
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_card(pParent, pType, pClient, pCode, pName, pExpire, pDescription);
  ELSE
    PERFORM api.update_card(pId, pParent, pType, pClient, pCode, pName, pExpire, pDescription);
  END IF;
  RETURN pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_card ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает клиента
 * @param {numeric} pId - Идентификатор
 * @return {api.card} - Клиент
 */
CREATE OR REPLACE FUNCTION api.get_card (
  pId		numeric
) RETURNS	api.card
AS $$
  SELECT * FROM api.card WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_card ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список клиентов.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.card} - Клиенты
 */
CREATE OR REPLACE FUNCTION api.list_card (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.card
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'card', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
