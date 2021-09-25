--------------------------------------------------------------------------------
-- CURRENCY --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.currency ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.currency
AS
  SELECT * FROM ObjectCurrency;

GRANT SELECT ON api.currency TO administrator;

--------------------------------------------------------------------------------
-- api.add_currency ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет валюту.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Тип
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {text} pDescription - Описание
 * @param {integer} pDigital - Цифровой код
 * @param {integer} pDecimal - Количество знаков после запятой
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_currency (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription	text default null,
  pDigital		integer default null,
  pDecimal		integer default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateCurrency(pParent, coalesce(pType, GetType('crypto.currency')), pCode, pName, pDescription, pDigital, pDecimal);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_currency ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует валюту.
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {text} pDescription - Описание
 * @param {integer} pDigital - Цифровой код
 * @param {integer} pDecimal - Количество знаков после запятой
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_currency (
  pId		    uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription	text default null,
  pDigital		integer default null,
  pDecimal		integer default null
) RETURNS       void
AS $$
DECLARE
  uCurrency     uuid;
BEGIN
  SELECT t.id INTO uCurrency FROM db.currency t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('currency', 'id', pId);
  END IF;

  PERFORM EditCurrency(uCurrency, pParent, pType, pCode, pName, pDescription, pDigital, pDecimal);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_currency ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_currency (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription	text default null,
  pDigital		integer default null,
  pDecimal		integer default null
) RETURNS       SETOF api.currency
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_currency(pParent, pType, pCode, pName, pDescription, pDigital, pDecimal);
  ELSE
    PERFORM api.update_currency(pId, pParent, pType, pCode, pName, pDescription, pDigital, pDecimal);
  END IF;

  RETURN QUERY SELECT * FROM api.currency WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_currency ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает валюту
 * @param {uuid} pId - Идентификатор
 * @return {api.currency}
 */
CREATE OR REPLACE FUNCTION api.get_currency (
  pId		uuid
) RETURNS	api.currency
AS $$
  SELECT * FROM api.currency WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_currency -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список валют.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.currency}
 */
CREATE OR REPLACE FUNCTION api.list_currency (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.currency
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'currency', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_currency_id ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает uuid по коду.
 * @param {text} pCode - Код валюты
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.get_currency_id (
  pCode		text
) RETURNS	uuid
AS $$
BEGIN
  RETURN GetCurrency(pCode);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
