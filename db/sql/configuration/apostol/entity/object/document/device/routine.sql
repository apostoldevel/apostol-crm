--------------------------------------------------------------------------------
-- CreateDevice ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new device
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
CREATE OR REPLACE FUNCTION CreateDevice (
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
DECLARE
  uDocument         uuid;
  uClass            uuid;
  uMethod           uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetClassCode(uClass) NOT IN ('device', 'caster', 'station') THEN
    PERFORM IncorrectClassType();
  END IF;

  pModel := coalesce(pModel, GetModel('unknown.model'));

  PERFORM FROM db.model WHERE id = pModel;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('model', 'id', pModel);
  END IF;

  pClient := coalesce(nullif(pClient, null_uuid()), current_client());

  IF pClient IS NOT NULL THEN
    PERFORM FROM db.client WHERE id = pClient;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('client', 'id', pClient);
    END IF;
  END IF;

  PERFORM FROM db.device WHERE identifier = pIdentifier;

  IF FOUND THEN
    PERFORM DeviceExists(pIdentifier);
  END IF;

  uDocument := CreateDocument(pParent, pType, coalesce(pLabel, pIdentifier), pDescription);

  INSERT INTO db.device (id, document, model, client, identifier, pswhash, version, serial, host, ip, iccid, imsi, metadata)
  VALUES (uDocument, uDocument, pModel, pClient, pIdentifier, crypt(pPassword, gen_salt('md5')), pVersion, pSerial, pHost, pIp, piccid, pimsi, pMetadata);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uDocument, uMethod);

  RETURN uDocument;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- EditDevice ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Edits an existing device
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
CREATE OR REPLACE FUNCTION EditDevice (
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
  vIdentifier       text;

  uClass            uuid;
  uMethod           uuid;
BEGIN
  SELECT identifier INTO vIdentifier FROM db.device WHERE id = pId;

  IF vIdentifier <> coalesce(pIdentifier, vIdentifier) THEN
    PERFORM FROM db.device WHERE identifier = pIdentifier;
    IF FOUND THEN
      PERFORM DeviceExists(pIdentifier);
    END IF;
  END IF;

  IF nullif(pClient, null_uuid()) IS NOT NULL THEN
    PERFORM FROM db.client WHERE id = pClient;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('client', 'id', pClient);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.device
     SET model = coalesce(pModel, model),
         client = CheckNull(coalesce(pClient, client, null_uuid())),
         identifier = coalesce(pIdentifier, identifier),
         version = CheckNull(coalesce(pVersion, version, '')),
         serial = CheckNull(coalesce(pSerial, serial, '')),
         host = CheckNull(coalesce(pHost, host, '')),
         ip = coalesce(pIp, ip),
         iccid = CheckNull(coalesce(piccid, iccid, '')),
         imsi = CheckNull(coalesce(pimsi, imsi, '')),
         metadata = CheckNull(coalesce(pMetadata, metadata, '{}'::jsonb))
   WHERE id = pId;

  IF pPassword IS NOT NULL THEN
    IF NOT IsUserRole(GetGroup('administrator')) THEN
      PERFORM AccessDenied();
    END IF;

    UPDATE db.device
       SET pswhash = crypt(pPassword, gen_salt('md5'))
     WHERE id = pId;
  END IF;

  SELECT class INTO uClass FROM db.object WHERE id = pId;

  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- GetDevice -------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the device by code
 * @param {text} pIdentifier - Identifier
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetDevice (
  pIdentifier   text
) RETURNS       uuid
AS $$
  SELECT id FROM db.device WHERE identifier = pIdentifier;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetDeviceIdentifier ---------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the device by code
 * @param {uuid} pDevice - Device
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetDeviceIdentifier (
  pDevice       uuid
) RETURNS       text
AS $$
  SELECT identifier FROM db.device WHERE id = pDevice;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SwitchDevice ----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief SwitchDevice
 * @param {uuid} pDevice - Device
 * @param {uuid} pClient - Client identifier
 * @return {boolean}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SwitchDevice (
  pDevice       uuid,
  pClient       uuid
) RETURNS       boolean
AS $$
DECLARE
  uUserId       uuid;
BEGIN
  uUserId := GetClientUserId(pClient);

  IF uUserId IS NOT NULL THEN
    UPDATE db.device SET client = pClient WHERE id = pDevice;
    PERFORM SetObjectOwner(pDevice, uUserId);

    RETURN true;
  END IF;

  RETURN false;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION AddDeviceNotification ----------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief AddDeviceNotification
 * @param {uuid} pDevice - Device
 * @param {integer} pInterfaceId - InterfaceId
 * @param {text} pStatus - Status
 * @param {text} pErrorCode - ErrorCode
 * @param {text} pInfo - Info
 * @param {text} pVendorErrorCode - VendorErrorCode
 * @param {timestamp} pTimeStamp - TimeStamp
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION AddDeviceNotification (
  pDevice           uuid,
  pInterfaceId      integer,
  pStatus           text,
  pErrorCode        text DEFAULT null,
  pInfo             text DEFAULT null,
  pVendorErrorCode  text DEFAULT null,
  pTimeStamp        timestamp DEFAULT Now()
) RETURNS           uuid
AS $$
DECLARE
  uId               uuid;

  dtDateFrom        timestamp;
  dtDateTo          timestamp;
BEGIN
  pErrorCode := coalesce(pErrorCode, 'NoError');

  -- get the value date within the current date range
  SELECT id, validFromDate, validToDate INTO uId, dtDateFrom, dtDateTo
    FROM db.device_notification
   WHERE device = pDevice
     AND interfaceId = pInterfaceId
     AND validFromDate <= pTimeStamp
     AND validToDate > pTimeStamp;

  IF coalesce(dtDateFrom, MINDATE()) = pTimeStamp THEN
    -- update the value within the current date range
    UPDATE db.device_notification
       SET status = pStatus,
           errorCode = pErrorCode,
           info = pInfo,
           vendorErrorCode = pVendorErrorCode
     WHERE device = pDevice
       AND interfaceId = pInterfaceId
       AND validFromDate <= pTimeStamp
       AND validToDate > pTimeStamp;
  ELSE
    -- update the value date within the current date range
    UPDATE db.device_notification SET validToDate = pTimeStamp
     WHERE device = pDevice
       AND interfaceId = pInterfaceId
       AND validFromDate <= pTimeStamp
       AND validToDate > pTimeStamp;

    INSERT INTO db.device_notification (device, interfaceId, status, errorCode, info, vendorErrorCode, validfromdate, validtodate)
    VALUES (pDevice, pInterfaceId, pStatus, pErrorCode, pInfo, pVendorErrorCode, pTimeStamp, coalesce(dtDateTo, MAXDATE()))
    RETURNING id INTO uId;
  END IF;

  RETURN uId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetJsonDeviceNotification ---------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the device by code
 * @param {uuid} pDevice - Device
 * @param {integer} pInterfaceId - InterfaceId
 * @param {timestamp} pDate - Date
 * @return {json}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetJsonDeviceNotification (
  pDevice       uuid,
  pInterfaceId  integer DEFAULT null,
  pDate         timestamp default current_timestamp at time zone 'utc'
) RETURNS       json
AS $$
DECLARE
  arResult      json[];
  r             record;
BEGIN
  FOR r IN
    SELECT *
      FROM DeviceNotification
     WHERE device = pDevice
       AND interfaceId = coalesce(pInterfaceId, interfaceId)
       AND validFromDate <= pDate
       AND validToDate > pDate
  LOOP
    arResult := array_append(arResult, row_to_json(r));
  END LOOP;

  RETURN array_to_json(arResult);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION AddDeviceValue -----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief AddDeviceValue
 * @param {uuid} pDevice - Device
 * @param {integer} pType - Type identifier
 * @param {jsonb} pValue - Value
 * @param {timestamp} pTimeStamp - TimeStamp
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION AddDeviceValue (
  pDevice       uuid,
  pType         integer,
  pValue        jsonb,
  pTimeStamp    timestamp default oper_date()
) RETURNS       uuid
AS $$
DECLARE
  uId           uuid;

  dtDateFrom    timestamp;
  dtDateTo      timestamp;
BEGIN
  -- get the value date within the current date range
  SELECT id, validFromDate, validToDate INTO uId, dtDateFrom, dtDateTo
    FROM db.device_value
   WHERE device = pDevice
     AND type = pType
     AND validFromDate <= pTimeStamp
     AND validToDate > pTimeStamp;

  IF coalesce(dtDateFrom, MINDATE()) = pTimeStamp THEN
    -- update the value within the current date range
    UPDATE db.device_value
       SET value = pValue
     WHERE device = pDevice
       AND type = pType
       AND validFromDate <= pTimeStamp
       AND validToDate > pTimeStamp;
  ELSE
    -- update the value date within the current date range
    UPDATE db.device_value SET validToDate = pTimeStamp
     WHERE device = pDevice
       AND type = pType
       AND validFromDate <= pTimeStamp
       AND validToDate > pTimeStamp;

    INSERT INTO db.device_value (device, type, value, validfromdate, validtodate)
    VALUES (pDevice, pType, pValue, pTimeStamp, coalesce(dtDateTo, MAXDATE()))
    RETURNING id INTO uId;
  END IF;

  RETURN uId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION AddDeviceData ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief AddDeviceData
 * @param {uuid} pDevice - Device
 * @param {text} pAgent - Agent identifier
 * @param {bytea} pData - Additional data
 * @param {timestamp} pTimeStamp - TimeStamp
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION AddDeviceData (
  pDevice       uuid,
  pAgent        text,
  pData         bytea,
  pTimeStamp    timestamp default oper_date()
) RETURNS       uuid
AS $$
DECLARE
  uId           uuid;

  dtDateFrom    timestamp;
  dtDateTo      timestamp;
BEGIN
  -- get the value date within the current date range
  SELECT id, validFromDate, validToDate INTO uId, dtDateFrom, dtDateTo
    FROM db.device_data
   WHERE device = pDevice
     AND agent = pAgent
     AND validFromDate <= pTimeStamp
     AND validToDate > pTimeStamp;

  IF coalesce(dtDateFrom, MINDATE()) = pTimeStamp THEN
    -- update the value within the current date range
    UPDATE db.device_data
       SET data = pData
     WHERE device = pDevice
       AND agent = pAgent
       AND validFromDate <= pTimeStamp
       AND validToDate > pTimeStamp;
  ELSE
    -- update the value date within the current date range
    UPDATE db.device_data SET validToDate = pTimeStamp
     WHERE device = pDevice
       AND agent = pAgent
       AND validFromDate <= pTimeStamp
       AND validToDate > pTimeStamp;

    INSERT INTO db.device_data (device, agent, data, validfromdate, validtodate)
    VALUES (pDevice, pAgent, pData, pTimeStamp, coalesce(dtDateTo, MAXDATE()))
    RETURNING id INTO uId;
  END IF;

  RETURN uId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SetDeviceConnected ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief SetDeviceConnected
 * @param {uuid} pId - Record identifier
 * @param {boolean} pConnected - Connected
 * @param {text} pHost - Host
 * @param {inet} pIP - IP
 * @param {int} pPort - Port
 * @param {jsonb} pMetadata - Metadata
 * @return {boolean}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SetDeviceConnected (
  pId           uuid,
  pConnected    boolean,
  pHost         text DEFAULT null,
  pIP           inet DEFAULT null,
  pPort         int DEFAULT null,
  pMetadata     jsonb DEFAULT null
) RETURNS       boolean
AS $$
DECLARE
  vIdentifier   text;

  bConnected    boolean;

  vMessage      text;
  vContext      text;

  ErrorCode     int;
  ErrorMessage  text;
BEGIN
  SELECT identifier, connected INTO vIdentifier, bConnected FROM db.device WHERE id = pId;

  IF FOUND THEN

    IF pConnected THEN
      PERFORM WriteToEventLog('M', 1900, 'connected', format('Device %s connected.', vIdentifier), pId);
    ELSE
      PERFORM WriteToEventLog('M', 1900, 'disconnected', format('Device %s disconnected.', vIdentifier), pId);
    END IF;

    IF pHost IS NULL AND pIP IS NOT NULL THEN
      IF pPort IS NOT NULL THEN
	    pHost := format('%s:%s', pIP, pPort);
	  ELSE
	    pHost := format('%s', pIP);
      END IF;
	END IF;

    IF pMetadata IS NOT NULL THEN
      UPDATE db.device SET host = pHost, ip = pIP, connected = pConnected, connect_updated = Now(), metadata = coalesce(metadata, jsonb_build_object()) || pMetadata WHERE id = pId;
    ELSE
      UPDATE db.device SET host = pHost, ip = pIP, connected = pConnected, connect_updated = Now() WHERE id = pId;
    END IF;

    RETURN true;
  END IF;

  RETURN false;
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetErrorMessage(vMessage);

  SELECT * INTO ErrorCode, ErrorMessage FROM ParseMessage(vMessage);

  PERFORM WriteToEventLog('E', ErrorCode, ErrorMessage);
  PERFORM WriteToEventLog('D', ErrorCode, vContext);

  RETURN false;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
