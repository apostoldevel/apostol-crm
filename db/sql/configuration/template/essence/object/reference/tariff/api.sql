--------------------------------------------------------------------------------
-- TARIFF ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.tariff ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.tariff
AS
  SELECT * FROM ObjectTariff;

GRANT SELECT ON api.tariff TO administrator;

--------------------------------------------------------------------------------
-- api.add_tariff --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет тариф.
 * @param {numeric} pParent - Ссылка на родительский объект: api.document | null
 * @param {varchar} pType - Тип
 * @param {varchar} pCode - Код
 * @param {varchar} pName - Наименование
 * @param {numeric} pCost - Стоимость
 * @param {text} pDescription - Описание
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.add_tariff (
  pParent       numeric,
  pType         varchar,
  pCode         varchar,
  pName         varchar,
  pCost         numeric,
  pDescription	text default null
) RETURNS       numeric
AS $$
BEGIN
  RETURN CreateTariff(pParent, CodeToType(lower(coalesce(pType, 'client')), 'tariff'), pCode, pName, pCost, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_tariff -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Меняет тариф.
 * @param {numeric} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {varchar} pType - Тип
 * @param {varchar} pCode - Код
 * @param {varchar} pName - Наименование
 * @param {numeric} pCost - Стоимость
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_tariff (
  pId		    numeric,
  pParent       numeric default null,
  pType         varchar default null,
  pCode         varchar default null,
  pName         varchar default null,
  pCost         numeric default null,
  pDescription	text default null
) RETURNS       void
AS $$
DECLARE
  nType         numeric;
  nTariff       numeric;
BEGIN
  SELECT t.id INTO nTariff FROM db.tariff t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('тариф', 'id', pId);
  END IF;

  IF pType IS NOT NULL THEN
    nType := CodeToType(lower(pType), 'tariff');
  ELSE
    SELECT o.type INTO nType FROM db.object o WHERE o.id = pId;
  END IF;

  PERFORM EditTariff(nTariff, pParent, nType,pCode, pName, pCost, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_tariff --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_tariff (
  pId           numeric,
  pParent       numeric default null,
  pType         varchar default null,
  pCode         varchar default null,
  pName         varchar default null,
  pCost         numeric default null,
  pDescription	text default null
) RETURNS       SETOF api.tariff
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_tariff(pParent, pType, pCode, pName, pCost, pDescription);
  ELSE
    PERFORM api.update_tariff(pId, pParent, pType, pCode, pName, pCost, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.tariff WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_tariff --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает тариф
 * @param {numeric} pId - Идентификатор
 * @return {api.tariff}
 */
CREATE OR REPLACE FUNCTION api.get_tariff (
  pId		numeric
) RETURNS	api.tariff
AS $$
  SELECT * FROM api.tariff WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_tariff -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список тарифов.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.tariff}
 */
CREATE OR REPLACE FUNCTION api.list_tariff (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.tariff
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'tariff', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
