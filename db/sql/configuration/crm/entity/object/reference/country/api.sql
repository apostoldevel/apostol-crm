--------------------------------------------------------------------------------
-- COUNTRY ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.country -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.country
AS
  SELECT * FROM ObjectCountry;

GRANT SELECT ON api.country TO administrator;

--------------------------------------------------------------------------------
-- api.add_country -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет валюту.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Идентификатор типа
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {text} pDescription - Описание
 * @param {text} pAlpha2 - Буквенный код: Альфа-2
 * @param {text} pAlpha3 - Буквенный код: Альфа-3
 * @param {integer} pDigital - Цифровой код
 * @param {text} pFlag - Флаг страны
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_country (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription    text default null,
  pAlpha2       text default null,
  pAlpha3       text default null,
  pDigital        integer default null,
  pFlag         text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateCountry(pParent, coalesce(pType, GetType('iso.country')), pCode, pName, pDescription, pAlpha2, pAlpha3, pDigital, pFlag);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_country ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует валюту.
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Идентификатор типа
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {text} pDescription - Описание
 * @param {text} pAlpha2 - Буквенный код: Альфа-2
 * @param {text} pAlpha3 - Буквенный код: Альфа-3
 * @param {integer} pDigital - Цифровой код
 * @param {text} pFlag - Флаг страны
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_country (
  pId            uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription    text default null,
  pAlpha2       text default null,
  pAlpha3       text default null,
  pDigital        integer default null,
  pFlag         text default null
) RETURNS       void
AS $$
DECLARE
  uCountry     uuid;
BEGIN
  SELECT t.id INTO uCountry FROM db.country t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('country', 'id', pId);
  END IF;

  PERFORM EditCountry(uCountry, pParent, pType, pCode, pName, pDescription, pAlpha2, pAlpha3, pDigital, pFlag);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_country -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_country (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription    text default null,
  pAlpha2       text default null,
  pAlpha3       text default null,
  pDigital        integer default null,
  pFlag         text default null
) RETURNS       SETOF api.country
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_country(pParent, pType, pCode, pName, pDescription, pAlpha2, pAlpha3, pDigital, pFlag);
  ELSE
    PERFORM api.update_country(pId, pParent, pType, pCode, pName, pDescription, pAlpha2, pAlpha3, pDigital, pFlag);
  END IF;

  RETURN QUERY SELECT * FROM api.country WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_country -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает валюту
 * @param {uuid} pId - Идентификатор
 * @return {api.country}
 */
CREATE OR REPLACE FUNCTION api.get_country (
  pId        uuid
) RETURNS    api.country
AS $$
  SELECT * FROM api.country WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_country ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список валют.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.country}
 */
CREATE OR REPLACE FUNCTION api.list_country (
  pSearch    jsonb default null,
  pFilter    jsonb default null,
  pLimit    integer default null,
  pOffSet    integer default null,
  pOrderBy    jsonb default null
) RETURNS    SETOF api.country
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'country', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_country_id ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает uuid по коду.
 * @param {text} pCode - Код валюты
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.get_country_id (
  pCode        text
) RETURNS    uuid
AS $$
BEGIN
  RETURN GetCountry(pCode);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
