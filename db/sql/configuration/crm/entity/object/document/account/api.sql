--------------------------------------------------------------------------------
-- ACCOUNT ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.account -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.account
AS
  SELECT * FROM ObjectAccount;

GRANT SELECT ON api.account TO administrator;

--------------------------------------------------------------------------------
-- api.account -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.account (
  pState    uuid
) RETURNS   SETOF api.account
AS $$
  SELECT * FROM api.account WHERE state = pState;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.account -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.account (
  pState    text
) RETURNS   SETOF api.account
AS $$
BEGIN
  RETURN QUERY SELECT * FROM api.account(GetState(GetClass('account'), pState));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.add_account -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет счет.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Tип
 * @param {uuid} pCurrency - Валюта
 * @param {uuid} pClient - Клиент
 * @param {uuid} pCategory - Категория
 * @param {text} pCode - Код
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_account (
  pParent       uuid,
  pType         uuid,
  pCurrency     uuid,
  pClient       uuid,
  pCategory     uuid default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateAccount(pParent, coalesce(pType, GetType('passive.account')), pCurrency, pClient, pCategory, pCode, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_account ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет данные счёта.
 * @param {uuid} pId - Идентификатор (api.get_account)
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Tип
 * @param {uuid} pCurrency - Валюта
 * @param {uuid} pClient - Клиент
 * @param {uuid} pCategory - Категория
 * @param {text} pCode - Код
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_account (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCurrency     uuid default null,
  pClient       uuid default null,
  pCategory     uuid default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
BEGIN
  PERFORM FROM db.account WHERE id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('account', 'id', pId);
  END IF;

  PERFORM EditAccount(pId, pParent, pType, pCurrency, pClient, pCategory, pCode, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_account -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_account (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCurrency     uuid default null,
  pClient       uuid default null,
  pCategory     uuid default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       SETOF api.account
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_account(pParent, pType, pCurrency, pClient, pCategory, pCode, pLabel, pDescription);
  ELSE
    PERFORM api.update_account(pId, pParent, pType, pCurrency, pClient, pCategory, pCode, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.account WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_account -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает счёт
 * @param {uuid} pId - Идентификатор
 * @return {api.account}
 */
CREATE OR REPLACE FUNCTION api.get_account (
  pId       uuid
) RETURNS   api.account
AS $$
  SELECT * FROM api.account WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_account ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.list_account (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.account
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'account', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_account_id ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_account_id (
  pCode     text,
  pCurrency text
) RETURNS   uuid
AS $$
BEGIN
  RETURN GetAccount(pCode, GetCurrency(pCurrency));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_account_balance -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_account_balance (
  pId       uuid,
  pDateFrom timestamptz DEFAULT oper_date()
) RETURNS   numeric
AS $$
BEGIN
  IF NOT CheckObjectAccess(pId, B'100') THEN
    PERFORM AccessDenied();
  END IF;

  RETURN GetBalance(pId, pDateFrom);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
