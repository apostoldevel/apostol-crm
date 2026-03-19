--------------------------------------------------------------------------------
-- DEVICE ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- VIEW api.device -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.device
AS
  SELECT * FROM ObjectDevice;

GRANT SELECT ON api.device TO administrator;

--------------------------------------------------------------------------------
-- FUNCTION api.add_device -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Adds a new device
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pModel - Model identifier
 * @param {uuid} pClient - Client identifier
 * @param {text} pIdentifier - String identifier
 * @param {text} pPassword - Device password for server access
 * @param {text} pVersion - Version
 * @param {text} pSerial - Serial number
 * @param {text} pHost - Host
 * @param {inet} pIp - Network address
 * @param {text} piccid - Integrated circuit card identifier (ICCID)
 * @param {text} pimsi - International Mobile Subscriber Identity (IMSI)
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Additional metadata
 * @return {uuid} - Device identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_device (
  pParent           uuid,
  pType             uuid,
  pModel            uuid,
  pClient           uuid,
  pIdentifier       text,
  pPassword         text DEFAULT null,
  pVersion          text DEFAULT null,
  pSerial           text DEFAULT null,
  pHost             text DEFAULT null,
  pIp               inet DEFAULT null,
  piccid            text DEFAULT null,
  pimsi             text DEFAULT null,
  pLabel            text DEFAULT null,
  pDescription      text DEFAULT null,
  pMetadata         jsonb DEFAULT null
) RETURNS           uuid
AS $$
BEGIN
  RETURN CreateDevice(pParent, coalesce(pType, GetType('mobile.device')), coalesce(pModel, GetModel('unknown.model')), coalesce(pClient, current_client()), coalesce(pIdentifier, pSerial), pPassword, pVersion, pSerial, pHost, pIp, piccid, pimsi, pLabel, pDescription, pMetadata);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION api.update_device --------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing device
 * @param {uuid} pId - Device identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pModel - Model identifier
 * @param {uuid} pClient - Client identifier
 * @param {text} pIdentifier - String identifier
 * @param {text} pPassword - Device password for server access
 * @param {text} pVersion - Version
 * @param {text} pSerial - Serial number
 * @param {text} pHost - Host
 * @param {inet} pIp - Network address
 * @param {text} piccid - Integrated circuit card identifier (ICCID)
 * @param {text} pimsi - International Mobile Subscriber Identity (IMSI)
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Additional metadata
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_device (
  pId               uuid,
  pParent           uuid DEFAULT null,
  pType             uuid DEFAULT null,
  pModel            uuid DEFAULT null,
  pClient           uuid DEFAULT null,
  pIdentifier       text DEFAULT null,
  pPassword         text DEFAULT null,
  pVersion          text DEFAULT null,
  pSerial           text DEFAULT null,
  pHost             text DEFAULT null,
  pIp               inet DEFAULT null,
  piccid            text DEFAULT null,
  pimsi             text DEFAULT null,
  pLabel            text DEFAULT null,
  pDescription      text DEFAULT null,
  pMetadata         jsonb DEFAULT null
) RETURNS           void
AS $$
DECLARE
BEGIN
  PERFORM FROM db.device c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('device', 'id', pId);
  END IF;

  PERFORM EditDevice(pId, pParent, pType, pModel, pClient, pIdentifier, pPassword, pVersion, pSerial, pHost, pIp, piccid, pimsi, pLabel, pDescription, pMetadata);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION api.set_device -----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a device (upsert)
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pModel - Model
 * @param {uuid} pClient - Client identifier
 * @param {text} pIdentifier - Identifier
 * @param {text} pPassword - Password
 * @param {text} pVersion - Version
 * @param {text} pSerial - Serial
 * @param {text} pHost - Host
 * @param {inet} pIp - Ip
 * @param {text} piccid - iccid
 * @param {text} pimsi - imsi
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Metadata
 * @return {SETOF api.device}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_device (
  pId               uuid,
  pParent           uuid DEFAULT null,
  pType             uuid DEFAULT null,
  pModel            uuid DEFAULT null,
  pClient           uuid DEFAULT null,
  pIdentifier       text DEFAULT null,
  pPassword         text DEFAULT null,
  pVersion          text DEFAULT null,
  pSerial           text DEFAULT null,
  pHost             text DEFAULT null,
  pIp               inet DEFAULT null,
  piccid            text DEFAULT null,
  pimsi             text DEFAULT null,
  pLabel            text DEFAULT null,
  pDescription      text DEFAULT null,
  pMetadata         jsonb DEFAULT null
) RETURNS           SETOF api.device
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_device(pParent, pType, pModel, pClient, pIdentifier, pPassword, pVersion, pSerial, pHost, pIp, piccid, pimsi, pLabel, pDescription, pMetadata);
  ELSE
    PERFORM api.update_device(pId, pParent, pType, pModel, pClient, pIdentifier, pPassword, pVersion, pSerial, pHost, pIp, piccid, pimsi, pLabel, pDescription, pMetadata);
  END IF;

  RETURN QUERY SELECT * FROM api.device WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION api.switch_device --------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief api.switch_device
 * @param {uuid} pDevice - Device
 * @param {uuid} pClient - Client identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.switch_device (
  pDevice            uuid,
  pClient            uuid
) RETURNS            void
AS $$
DECLARE
  uClient            uuid;
BEGIN
  SELECT client INTO uClient FROM db.device WHERE id = pDevice;
  IF FOUND AND coalesce(pClient, uClient) <> uClient THEN
    PERFORM SwitchDevice(pDevice, pClient);
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION api.init_device ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief api.init_device
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pModel - Model
 * @param {uuid} pClient - Client identifier
 * @param {text} pIdentifier - Identifier
 * @param {text} pPassword - Password
 * @param {text} pVersion - Version
 * @param {text} pSerial - Serial
 * @param {text} pHost - Host
 * @param {inet} pIp - Ip
 * @param {text} piccid - iccid
 * @param {text} pimsi - imsi
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @param {jsonb} pMetadata - Metadata
 * @return {SETOF api.device}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.init_device (
  pParent           uuid,
  pType             uuid,
  pModel            uuid,
  pClient           uuid,
  pIdentifier       text,
  pPassword         text DEFAULT null,
  pVersion          text DEFAULT null,
  pSerial           text DEFAULT null,
  pHost             text DEFAULT null,
  pIp               inet DEFAULT null,
  piccid            text DEFAULT null,
  pimsi             text DEFAULT null,
  pLabel            text DEFAULT null,
  pDescription      text DEFAULT null,
  pMetadata         jsonb DEFAULT null
) RETURNS           SETOF api.device
AS $$
DECLARE
  uId               uuid;
  uModel            uuid;
BEGIN
  pIdentifier := coalesce(pIdentifier, pSerial);
  uModel := GetModel(pModel);
  pClient := coalesce(pClient, GetClientByUserId(current_userid()));

  SELECT c.id INTO uId FROM db.device c WHERE c.identifier = pIdentifier;

  IF uId IS NULL THEN
    uId := api.add_device(pParent, pType, uModel, pClient, pIdentifier, pPassword, pVersion, pSerial, pHost, pIp, piccid, pimsi, pLabel, pDescription, pMetadata);
  ELSE
    PERFORM api.switch_device(uId, pClient);
    PERFORM api.update_device(uId, pParent, pType, uModel, pClient, pIdentifier, pPassword, pVersion, pSerial, pHost, pIp, piccid, pimsi, pLabel, pDescription, pMetadata);

    IF IsDisabled(uId) THEN
      PERFORM DoEnable(uId);
    END IF;
  END IF;

  RETURN QUERY SELECT * FROM api.device WHERE id = uId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_device --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a device by identifier
 * @param {uuid} pId - Device identifier
 * @return {api.device} - Device record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_device (
  pId           uuid
) RETURNS       SETOF api.device
AS $$
  SELECT * FROM api.device WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_device --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a device by identifier
 * @param {text} pIdentifier - Device string identifier
 * @return {api.device} - Device record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_device (
  pIdentifier   text
) RETURNS       SETOF api.device
AS $$
  SELECT * FROM api.device WHERE identifier = pIdentifier AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_device ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of device records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_device (
  pSearch    jsonb DEFAULT null,
  pFilter    jsonb DEFAULT null
) RETURNS    SETOF bigint
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'device', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_device -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a filtered/sorted list of device records
 * @param {jsonb} pSearch - Search conditions array
 * @param {jsonb} pFilter - Filter object
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.device} - List of device records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_device (
  pSearch       jsonb DEFAULT null,
  pFilter       jsonb DEFAULT null,
  pLimit        integer DEFAULT null,
  pOffSet       integer DEFAULT null,
  pOrderBy      jsonb DEFAULT null
) RETURNS       SETOF api.device
AS $$
BEGIN
  IF NOT IsAdmin() THEN
    pFilter := coalesce(pFilter, '{}'::jsonb) || jsonb_build_object('client', current_client());
  END IF;

  RETURN QUERY EXECUTE api.sql('api', 'device', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- STATUS NOTIFICATION ---------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- VIEW api.device_notification ------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.device_notification
AS
  SELECT * FROM DeviceNotification;

GRANT SELECT ON api.device_notification TO administrator;

--------------------------------------------------------------------------------
-- api.device_notification -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns device status notifications
 * @param {uuid} pDevice - Device identifier
 * @param {integer} pInterfaceId - Device interface identifier
 * @param {timestamptz} pDate - Date and time
 * @return {SETOF api.device_notification}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.device_notification (
  pDevice       uuid,
  pInterfaceId  integer DEFAULT null,
  pDate         timestamptz default current_timestamp at time zone 'utc'
) RETURNS       SETOF api.device_notification
AS $$
  SELECT *
    FROM api.device_notification
   WHERE device = pDevice
     AND interfaceId = coalesce(pInterfaceId, interfaceId)
     AND pDate BETWEEN validfromdate AND validtodate
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_device_notification -------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a device by identifier
 * @param {uuid} pId - Identifier
 * @return {api.device_notification}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_device_notification (
  pId        uuid
) RETURNS    api.device_notification
AS $$
  SELECT * FROM api.device_notification WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_device_notification -----------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of device records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_device_notification (
  pSearch    jsonb DEFAULT null,
  pFilter    jsonb DEFAULT null
) RETURNS    SETOF bigint
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'device_notification', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_device_notification ------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a filtered/sorted list of device records
 * @param {jsonb} pSearch - Search conditions array
 * @param {jsonb} pFilter - Filter object
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.device_notification}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_device_notification (
  pSearch       jsonb DEFAULT null,
  pFilter       jsonb DEFAULT null,
  pLimit        integer DEFAULT null,
  pOffSet       integer DEFAULT null,
  pOrderBy      jsonb DEFAULT null
) RETURNS       SETOF api.device_notification
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'device_notification', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- DEVICE VALUE ----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- VIEW api.device_value -------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.device_value
AS
  SELECT * FROM DeviceValue;

GRANT SELECT ON api.device_value TO administrator;

--------------------------------------------------------------------------------
-- api.get_device_value --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a device by identifier
 * @param {uuid} pId - Identifier
 * @return {api.device_value}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_device_value (
  pId        uuid
) RETURNS    SETOF api.device_value
AS $$
  SELECT * FROM api.device_value WHERE id = pId AND CheckObjectAccess(device, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_device_value ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of device records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_device_value (
  pSearch    jsonb DEFAULT null,
  pFilter    jsonb DEFAULT null
) RETURNS    SETOF bigint
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'device_value', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_device_value -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a filtered/sorted list of device records
 * @param {jsonb} pSearch - Search conditions array
 * @param {jsonb} pFilter - Filter object
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.device_value}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_device_value (
  pSearch   jsonb DEFAULT null,
  pFilter   jsonb DEFAULT null,
  pLimit    integer DEFAULT null,
  pOffSet   integer DEFAULT null,
  pOrderBy  jsonb DEFAULT null
) RETURNS   SETOF api.device_value
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'device_value', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- DEVICE DATA -----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- VIEW api.device_data --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.device_data
AS
  SELECT * FROM DeviceData;

GRANT SELECT ON api.device_data TO administrator;

--------------------------------------------------------------------------------
-- api.get_device_data ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a device by identifier
 * @param {uuid} pId - Identifier
 * @return {api.device_data}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_device_data (
  pId        uuid
) RETURNS    SETOF api.device_data
AS $$
  SELECT * FROM api.device_data WHERE id = pId AND CheckObjectAccess(device, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_device_data -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of device records
 * @return {SETOF bigint}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_device_data (
  pSearch    jsonb DEFAULT null,
  pFilter    jsonb DEFAULT null
) RETURNS    SETOF bigint
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'device_data', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_device_data --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a filtered/sorted list of device records
 * @param {jsonb} pSearch - Search conditions array
 * @param {jsonb} pFilter - Filter object
 * @param {integer} pLimit - Maximum number of rows
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort order fields
 * @return {SETOF api.device_data}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_device_data (
  pSearch   jsonb DEFAULT null,
  pFilter   jsonb DEFAULT null,
  pLimit    integer DEFAULT null,
  pOffSet   integer DEFAULT null,
  pOrderBy  jsonb DEFAULT null
) RETURNS   SETOF api.device_data
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'device_data', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
