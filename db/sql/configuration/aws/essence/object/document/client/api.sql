--------------------------------------------------------------------------------
-- CLIENT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.client ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.client
AS
  SELECT * FROM ObjectClient;

GRANT SELECT ON api.client TO administrator;

--------------------------------------------------------------------------------
-- api.add_client --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет нового клиента.
 * @param {numeric} pParent - Идентификатор родителя | null
 * @param {varchar} pType - Tип клиента
 * @param {varchar} pCode - ИНН - для юридического лица | Имя пользователя (login) | null
 * @param {numeric} pUserId - Идентификатор пользователя системы | null
 * @param {jsonb} pName - Полное наименование компании/Ф.И.О.
 * @param {jsonb} pPhone - Телефоны
 * @param {jsonb} pEmail - Электронные адреса
 * @param {jsonb} pInfo - Дополнительная информация
 * @param {text} pDescription - Информация о клиенте
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.add_client (
  pParent       numeric,
  pType         varchar,
  pCode         varchar,
  pUserId       numeric,
  pName         jsonb,
  pPhone        jsonb DEFAULT null,
  pEmail        jsonb DEFAULT null,
  pInfo         jsonb DEFAULT null,
  pDescription  text DEFAULT null
) RETURNS       numeric
AS $$
DECLARE
  cn            record;
  nClient       numeric;
  arKeys        text[];
BEGIN
  pType := lower(coalesce(pType, 'physical'));

  arKeys := array_cat(arKeys, ARRAY['name', 'short', 'first', 'last', 'middle']);
  PERFORM CheckJsonbKeys('add_client', arKeys, pName);

  SELECT * INTO cn FROM jsonb_to_record(pName) AS x(name varchar, short varchar, first varchar, last varchar, middle varchar);

  IF NULLIF(cn.name, '') IS NULL THEN
    cn.name := pCode;
  END IF;

  IF pUserId = 0 THEN
    pUserId := CreateUser(pCode, pCode, coalesce(cn.short, cn.name), pPhone->>0, pEmail->>0, cn.name);
  END IF;

  nClient := CreateClient(pParent, CodeToType(pType, 'client'), pCode, pUserId, pPhone, pEmail, pInfo, pDescription);

  PERFORM NewClientName(nClient, cn.name, cn.short, cn.first, cn.last, cn.middle);

  RETURN nClient;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_client -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет данные клиента.
 * @param {numeric} pId - Идентификатор (api.get_client)
 * @param {numeric} pParent - Идентификатор родителя | null
 * @param {varchar} pType - Tип клиента
 * @param {varchar} pCode - ИНН - для юридического лица | Имя пользователя (login) | null
 * @param {numeric} pUserId - Идентификатор пользователя системы | null
 * @param {jsonb} pName - Полное наименование компании/Ф.И.О.
 * @param {jsonb} pPhone - Телефоны
 * @param {jsonb} pEmail - Электронные адреса
 * @param {jsonb} pInfo - Дополнительная информация
 * @param {text} pDescription - Информация о клиенте
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_client (
  pId           numeric,
  pParent       numeric,
  pType         varchar,
  pCode         varchar,
  pUserId       numeric,
  pName         jsonb,
  pPhone        jsonb DEFAULT null,
  pEmail        jsonb DEFAULT null,
  pInfo         jsonb DEFAULT null,
  pDescription  text DEFAULT null
) RETURNS       void
AS $$
DECLARE
  r             record;
  nType         numeric;
  nClient       numeric;
  arKeys        text[];
BEGIN
  SELECT c.id INTO nClient FROM db.client c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('клиент', 'id', pId);
  END IF;

  IF pType IS NOT NULL THEN
    nType := CodeToType(lower(pType), 'client');
  ELSE
    SELECT o.type INTO nType FROM db.object o WHERE o.id = pId;
  END IF;

  arKeys := array_cat(arKeys, ARRAY['name', 'short', 'first', 'last', 'middle']);
  PERFORM CheckJsonbKeys('update_client', arKeys, pName);

  PERFORM EditClient(nClient, pParent, nType, pCode, pUserId, pPhone, pEmail, pInfo, pDescription);

  FOR r IN SELECT * FROM jsonb_to_record(pName) AS x(name varchar, short varchar, first varchar, last varchar, middle varchar)
  LOOP
    PERFORM EditClientName(nClient, r.name, r.short, r.first, r.last, r.middle);
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_client --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_client (
  pId           numeric,
  pParent       numeric,
  pType         varchar,
  pCode         varchar,
  pUserId       numeric,
  pName         jsonb,
  pPhone        jsonb DEFAULT null,
  pEmail        jsonb DEFAULT null,
  pInfo         jsonb DEFAULT null,
  pDescription  text DEFAULT null
) RETURNS       SETOF api.client
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_client(pParent, pType, pCode, pUserId, pName, pPhone, pEmail, pInfo, pDescription);
  ELSE
    PERFORM api.update_client(pId, pParent, pType, pCode, pUserId, pName, pPhone, pEmail, pInfo, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.client WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_client --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает клиента
 * @param {numeric} pId - Идентификатор
 * @return {api.client} - Клиент
 */
CREATE OR REPLACE FUNCTION api.get_client (
  pId		numeric
) RETURNS	SETOF api.client
AS $$
  SELECT * FROM api.client WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_client -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список клиентов.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.client} - Клиенты
 */
CREATE OR REPLACE FUNCTION api.list_client (
  pSearch	jsonb DEFAULT null,
  pFilter	jsonb DEFAULT null,
  pLimit	integer DEFAULT null,
  pOffSet	integer DEFAULT null,
  pOrderBy	jsonb DEFAULT null
) RETURNS	SETOF api.client
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'client', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CLIENT TARIFF ---------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.client_tariff -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.client_tariff
AS
  SELECT * FROM ClientTariffs;

GRANT SELECT ON api.client_tariff TO administrator;

--------------------------------------------------------------------------------
-- api.set_client_tariffs_json -------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_client_tariffs_json (
  pClient	    numeric,
  pTariffs      json
) RETURNS 	    numeric
AS $$
DECLARE
  nId		    numeric;
  nType         numeric;
  nTariff       numeric;

  arKeys	    text[];

  r		        record;
BEGIN
  SELECT o.id INTO nId FROM db.client o WHERE o.id = pClient;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('клиент', 'id', pClient);
  END IF;

  IF pTariffs IS NOT NULL THEN
    arKeys := array_cat(arKeys, GetRoutines('EditTariff', 'kernel', false));
    PERFORM CheckJsonKeys('/client/tariff/tariffs', arKeys, pTariffs);

    FOR r IN SELECT * FROM json_to_recordset(pTariffs) AS x(id numeric, parent numeric, type varchar, code varchar, name varchar, cost numeric, description text)
    LOOP
      nType := CodeToType(lower(coalesce(r.type, 'client')), 'tariff');

      IF r.id IS NOT NULL THEN
        SELECT o.id INTO nTariff FROM db.address o WHERE o.id = r.id;

        IF NOT FOUND THEN
          PERFORM ObjectNotFound('тариф', r.code, r.id);
        END IF;

        PERFORM EditTariff(r.id, r.parent, nType, r.code, r.name, r.cost, r.description);
      ELSE
        nTariff := CreateTariff(r.parent, nType, r.code, r.name, r.cost, r.description);
        nId := SetObjectLink(pClient, nTariff);
      END IF;
    END LOOP;
  ELSE
    PERFORM JsonIsEmpty();
  END IF;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_client_tariffs_jsonb ------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_client_tariffs_jsonb (
  pClient	    numeric,
  pTariffs	    jsonb
) RETURNS 	    numeric
AS $$
BEGIN
  RETURN api.set_client_tariffs_json(pClient, pTariffs::json);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_client_tariffs_json -------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_client_tariffs_json (
  pClient	numeric
) RETURNS	json
AS $$
BEGIN
  RETURN GetClientTariffsJson(pClient);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_client_tariffs_jsonb ------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_client_tariffs_jsonb (
  pClient	numeric
) RETURNS	jsonb
AS $$
BEGIN
  RETURN GetClientTariffsJsonb(pClient);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_client_tariff -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Устанавливает тариф клиенту
 * @param {numeric} pClient - Идентификатор клиента
 * @param {numeric} pTariff - Идентификатор тарифа
 * @param {timestamp} pDateFrom - Дата операции
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.set_client_tariff (
  pClient	    numeric,
  pTariff	    numeric,
  pDateFrom	    timestamp default oper_date()
) RETURNS       numeric
AS $$
BEGIN
  RETURN SetObjectLink(pClient, pTariff, pDateFrom);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_client_tariff -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает тариф клиента
 * @param {numeric} pId - Идентификатор записи
 * @return {api.client_tariff}
 */
CREATE OR REPLACE FUNCTION api.get_client_tariff (
  pId		numeric
) RETURNS	api.client_tariff
AS $$
  SELECT * FROM api.client_tariff WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_client_tariff ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает тарифы клиента.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.client_tariff}
 */
CREATE OR REPLACE FUNCTION api.list_client_tariff (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.client_tariff
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'client_tariff', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
