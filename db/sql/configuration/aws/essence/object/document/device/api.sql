--------------------------------------------------------------------------------
-- DEVICE ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- VIEW api.device -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.device
AS
  SELECT o.*, g.data::json AS geo
    FROM ObjectDevice o LEFT JOIN db.object_data g ON g.object = o.object AND g.code = 'geo';

GRANT SELECT ON api.device TO administrator;

--------------------------------------------------------------------------------
-- api.device ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.device (
  pState	numeric
) RETURNS	SETOF api.device
AS $$
  SELECT * FROM api.device WHERE state = pState;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.device ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.device (
  pState	varchar
) RETURNS	SETOF api.device
AS $$
BEGIN
  RETURN QUERY SELECT * FROM api.device(GetState(GetClass('device'), pState));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION api.add_device -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет данные зарядной станции.
 * @param {numeric} pId - Идентификатор зарядной станции (api.get_device)
 * @param {numeric} pParent - Идентификатор родителя | null
 * @param {varchar} pType - Tип зарядной станции
 * @param {numeric} pClient - Идентификатор клиента | null
 * @param {varchar} pIdentity - Строковый идентификатор зарядной станции
 * @param {varchar} pModel - Required. This contains a value that identifies the model of the Device.
 * @param {varchar} pVendor - Required. This contains a value that identifies the vendor of the Device.
 * @param {varchar} pVersion - Optional. This contains the firmware version of the Device.
 * @param {varchar} pSerial - Optional. This contains a value that identifies the serial number of the Device.
 * @param {varchar} pBoxSerialNumber - Optional. This contains a value that identifies the serial number of the Charge Box inside the Device. Deprecated, will be removed in future version.
 * @param {varchar} pMeterSerialNumber - Optional. This contains the serial number of the main electrical meter of the Device.
 * @param {varchar} piccid - Optional. This contains the ICCID of the modem’s SIM card.
 * @param {varchar} pimsi - Optional. This contains the IMSI of the modem’s SIM card.
 * @param {varchar} pLabel - Метка
 * @param {varchar} pDescription - Описание
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.add_device (
  pParent               numeric,
  pType                 varchar,
  pClient               numeric,
  pIdentity             text,
  pModel                varchar,
  pVendor               varchar,
  pVersion              varchar,
  pSerialNumber         varchar,
  pBoxSerialNumber      varchar,
  pMeterSerialNumber    varchar,
  piccid                varchar,
  pimsi                 varchar,
  pLabel                varchar default null,
  pDescription          text default null
) RETURNS               numeric
AS $$
BEGIN
  RETURN CreateDevice(pParent, CodeToType(lower(coalesce(pType, 'public')), 'device'), pClient, pIdentity, pModel, pVendor, pVersion,
    pSerialNumber, pBoxSerialNumber, pMeterSerialNumber, piccid, pimsi, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION api.update_device --------------------------------------------
--------------------------------------------------------------------------------
/**
 * Меняет данные зарядной станции.
 * @param {numeric} pId - Идентификатор зарядной станции
 * @param {numeric} pParent - Идентификатор родителя | null
 * @param {varchar} pType - Tип зарядной станции
 * @param {numeric} pClient - Идентификатор клиента | null
 * @param {varchar} pIdentity - Строковый идентификатор зарядной станции
 * @param {varchar} pModel - Required. This contains a value that identifies the model of the Device.
 * @param {varchar} pVendor - Required. This contains a value that identifies the vendor of the Device.
 * @param {varchar} pVersion - Optional. This contains the firmware version of the Device.
 * @param {varchar} pSerialNumber - Optional. This contains a value that identifies the serial number of the Device.
 * @param {varchar} pBoxSerialNumber - Optional. This contains a value that identifies the serial number of the Charge Box inside the Device. Deprecated, will be removed in future version.
 * @param {varchar} pMeterSerialNumber - Optional. This contains the serial number of the main electrical meter of the Device.
 * @param {varchar} piccid - Optional. This contains the ICCID of the modem’s SIM card.
 * @param {varchar} pimsi - Optional. This contains the IMSI of the modem’s SIM card.
 * @param {varchar} pLabel - Метка
 * @param {varchar} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_device (
  pId                   numeric,
  pParent               numeric default null,
  pType                 varchar default null,
  pClient               numeric default null,
  pIdentity             text default null,
  pModel                varchar default null,
  pVendor               varchar default null,
  pVersion              varchar default null,
  pSerialNumber         varchar default null,
  pBoxSerialNumber      varchar default null,
  pMeterSerialNumber    varchar default null,
  piccid                varchar default null,
  pimsi                 varchar default null,
  pLabel                varchar default null,
  pDescription          text default null
) RETURNS               void
AS $$
DECLARE
  nId                   numeric;
  nType                 numeric;
BEGIN
  SELECT c.id INTO nId FROM db.device c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('зарядная станция', 'id', pId);
  END IF;

  IF pType IS NOT NULL THEN
    nType := CodeToType(lower(pType), 'device');
  ELSE
    SELECT o.type INTO nType FROM db.object o WHERE o.id = pId;
  END IF;

  PERFORM EditDevice(nId, pParent, nType, pClient, pIdentity, pModel, pVendor, pVersion,
    pSerialNumber, pBoxSerialNumber, pMeterSerialNumber, piccid, pimsi, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION api.set_device -----------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_device (
  pId                   numeric,
  pParent               numeric default null,
  pType                 varchar default null,
  pClient               numeric default null,
  pIdentity             text default null,
  pModel                varchar default null,
  pVendor               varchar default null,
  pVersion              varchar default null,
  pSerialNumber         varchar default null,
  pBoxSerialNumber      varchar default null,
  pMeterSerialNumber    varchar default null,
  piccid                varchar default null,
  pimsi                 varchar default null,
  pLabel                varchar default null,
  pDescription          text default null
) RETURNS               SETOF api.device
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_device(pParent, pType, pClient, pIdentity, pModel, pVendor, pVersion, pSerialNumber, pBoxSerialNumber, pMeterSerialNumber, piccid, pimsi, pLabel, pDescription);
  ELSE
    PERFORM api.update_device(pId, pParent, pType, pClient, pIdentity, pModel, pVendor, pVersion, pSerialNumber, pBoxSerialNumber, pMeterSerialNumber, piccid, pimsi, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.device WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_device --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает зарядную станцию по идентификатору
 * @param {numeric} pId - Идентификатор зарядной станции
 * @return {api.device} - Зарядная станция
 */
CREATE OR REPLACE FUNCTION api.get_device (
  pId           numeric
) RETURNS       api.device
AS $$
  SELECT * FROM api.device WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_device --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает зарядную станцию по строковому идентификатору
 * @param {numeric} pId - Идентификатор зарядной станции
 * @return {api.device} - Зарядная станция
 */
CREATE OR REPLACE FUNCTION api.get_device (
  pIdentity     varchar
) RETURNS       api.device
AS $$
  SELECT * FROM api.device WHERE identity = pIdentity
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_device -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список зарядных станций.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.device} - Зарядные станции
 */
CREATE OR REPLACE FUNCTION api.list_device (
  pSearch       jsonb default null,
  pFilter       jsonb default null,
  pLimit        integer default null,
  pOffSet       integer default null,
  pOrderBy      jsonb default null
) RETURNS       SETOF api.device
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'device', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- STATUS NOTIFICATION ---------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- VIEW api.status_notification ------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.status_notification
AS
  SELECT * FROM StatusNotification;

GRANT SELECT ON api.status_notification TO administrator;

--------------------------------------------------------------------------------
-- api.status_notification -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает уведомления о статусе зарядной станций
 * @param {numeric} pDevice - Идентификатор зарядной станции
 * @param {integer} pConnectorId - Идентификатор разъёма зарядной станции
 * @param {timestamptz} pDate - Дата и время
 * @return {SETOF api.status_notification}
 */
CREATE OR REPLACE FUNCTION api.status_notification (
  pDevice       numeric,
  pConnectorId  integer default null,
  pDate         timestamptz default current_timestamp at time zone 'utc'
) RETURNS	    SETOF api.status_notification
AS $$
  SELECT *
    FROM api.status_notification
   WHERE device = pDevice
     AND connectorid = coalesce(pConnectorId, connectorid)
     AND pDate BETWEEN validfromdate AND validtodate
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_status_notification -------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает уведомление о статусе зарядной станции.
 * @param {numeric} pId - Идентификатор
 * @return {api.status_notification}
 */
CREATE OR REPLACE FUNCTION api.get_status_notification (
  pId		numeric
) RETURNS	api.status_notification
AS $$
  SELECT * FROM api.status_notification WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_status_notification ------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает уведомления о статусе зарядных станций.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.status_notification}
 */
CREATE OR REPLACE FUNCTION api.list_status_notification (
  pSearch       jsonb default null,
  pFilter       jsonb default null,
  pLimit        integer default null,
  pOffSet       integer default null,
  pOrderBy      jsonb default null
) RETURNS       SETOF api.status_notification
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'status_notification', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- TRANSACTION -----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- VIEW api.transaction --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.transaction
AS
  SELECT * FROM Transaction;

GRANT SELECT ON api.transaction TO administrator;

--------------------------------------------------------------------------------
-- api.get_transaction ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает транзакцию зарядной станции.
 * @param {numeric} pId - Идентификатор
 * @return {api.transaction}
 */
CREATE OR REPLACE FUNCTION api.get_transaction (
  pId		numeric
) RETURNS	api.transaction
AS $$
  SELECT * FROM api.transaction WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_transaction --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает транзакции зарядных станций.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.transaction} - уведомление о статусе
 */
CREATE OR REPLACE FUNCTION api.list_transaction (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.transaction
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'transaction', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- METER VALUE -----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- VIEW api.meter_value --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.meter_value
AS
  SELECT * FROM MeterValue;

GRANT SELECT ON api.meter_value TO administrator;

--------------------------------------------------------------------------------
-- api.get_meter_value ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает показания счётчика зарядной станции.
 * @param {numeric} pId - Идентификатор
 * @return {api.meter_value}
 */
CREATE OR REPLACE FUNCTION api.get_meter_value (
  pId		numeric
) RETURNS	api.meter_value
AS $$
  SELECT * FROM api.meter_value WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_meter_value --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает показания счётчика зарядных станций.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.meter_value}
 */
CREATE OR REPLACE FUNCTION api.list_meter_value (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.meter_value
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'meter_value', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
