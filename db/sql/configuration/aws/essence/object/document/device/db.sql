--------------------------------------------------------------------------------
-- db.device -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.device (
    id                  numeric(12) PRIMARY KEY,
    document            numeric(12) NOT NULL,
    model               numeric(12) NOT NULL,
    client              numeric(12),
    identity            text NOT NULL,
    version             text,
    serial              varchar(25),
    iccid               varchar(20),
    imsi                varchar(20),
    CONSTRAINT fk_device_document FOREIGN KEY (document) REFERENCES db.document(id),
    CONSTRAINT fk_device_client FOREIGN KEY (client) REFERENCES db.client(id)
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.device IS 'Зарядная станция.';

COMMENT ON COLUMN db.device.id IS 'Идентификатор.';
COMMENT ON COLUMN db.device.document IS 'Документ.';
COMMENT ON COLUMN db.device.model IS 'Идентификатор модели.';
COMMENT ON COLUMN db.device.client IS 'Идентификатор клиента.';
COMMENT ON COLUMN db.device.identity IS 'Строковый идентификатор.';
COMMENT ON COLUMN db.device.version IS 'Версия.';
COMMENT ON COLUMN db.device.serial IS 'Серийный номер.';
COMMENT ON COLUMN db.device.iccid IS 'Integrated circuit card identifier (ICCID) — уникальный серийный номер SIM-карты.';
COMMENT ON COLUMN db.device.imsi IS 'International Mobile Subscriber Identity (IMSI) — международный идентификатор мобильного абонента (индивидуальный номер абонента).';

--------------------------------------------------------------------------------

CREATE INDEX ON db.device (document);

CREATE UNIQUE INDEX ON db.device (identity);

CREATE INDEX ON db.device (model);
CREATE INDEX ON db.device (serial);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_device_before_insert()
RETURNS trigger AS $$
DECLARE
BEGIN
  IF NEW.id IS NULL OR NEW.id = 0 THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  RAISE DEBUG 'Создано устройство Id: %', NEW.ID;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_device_before_insert
  BEFORE INSERT ON db.device
  FOR EACH ROW
  EXECUTE PROCEDURE ft_device_before_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_device_after_update()
RETURNS trigger AS $$
BEGIN
  RAISE DEBUG 'Изменено устройство Id: %', NEW.ID;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_device_after_update
  AFTER UPDATE ON db.device
  FOR EACH ROW
  EXECUTE PROCEDURE ft_device_after_update();

--------------------------------------------------------------------------------
-- CreateDevice ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateDevice (
  pParent               numeric,
  pType                 numeric,
  pModel                numeric,
  pClient               numeric,
  pIdentity             text,
  pVersion              text,
  pSerial               varchar default null,
  piccid                varchar default null,
  pimsi                 varchar default null,
  pLabel                varchar default null,
  pDescription          text default null
) RETURNS               numeric
AS $$
DECLARE
  nDocument             numeric;
  nClass                numeric;
  nMethod               numeric;
BEGIN
  SELECT class INTO nClass FROM db.type WHERE id = pType;

  IF nClass IS NULL OR GetClassCode(nClass) <> 'device' THEN
    PERFORM IncorrectClassType();
  END IF;

  SELECT id INTO nDocument FROM db.device WHERE identity = pIdentity;

  IF found THEN
    PERFORM DeviceExists(pIdentity);
  END IF;

  nDocument := CreateDocument(pParent, pType, coalesce(pLabel, pIdentity), pDescription);

  INSERT INTO db.device (id, document, model, client, identity, version, serial, iccid, imsi)
  VALUES (nDocument, nDocument, pModel, pClient, pIdentity, pVersion, pSerial, piccid, pimsi);

  nMethod := GetMethod(nClass, null, GetAction('create'));
  PERFORM ExecuteMethod(nDocument, nMethod);

  RETURN nDocument;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditDevice ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EditDevice (
  pId                   numeric,
  pParent               numeric default null,
  pType                 numeric default null,
  pModel                numeric default null,
  pClient               numeric default null,
  pIdentity             text default null,
  pVersion              text default null,
  pSerial               text default null,
  piccid                text default null,
  pimsi                 text default null,
  pLabel                text default null,
  pDescription          text default null
) RETURNS               void
AS $$
DECLARE
  nDocument             numeric;
  vIdentity             text;

  nClass	            numeric;
  nMethod	            numeric;
BEGIN
  SELECT identity INTO vIdentity FROM db.device WHERE id = pId;
  IF vIdentity <> coalesce(pIdentity, vIdentity) THEN
    SELECT id INTO nDocument FROM db.device WHERE identity = pIdentity;
    IF found THEN
      PERFORM DeviceExists(pIdentity);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.device
     SET model = coalesce(pModel, model),
         client = CheckNull(coalesce(pClient, client, 0)),         
         identity = coalesce(pIdentity, identity),
         version = CheckNull(coalesce(pVersion, version, '<null>')),
         serial = CheckNull(coalesce(pSerial, serial, '<null>')),
         iccid = CheckNull(coalesce(piccid, iccid, '<null>')),
         imsi = CheckNull(coalesce(pimsi, imsi, '<null>'))
   WHERE id = pId;

  SELECT class INTO nClass FROM db.type WHERE id = pType;

  nMethod := GetMethod(nClass, null, GetAction('edit'));
  PERFORM ExecuteMethod(pId, nMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetDevice -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetDevice (
  pIdentity text
) RETURNS	numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  SELECT id INTO nId FROM db.device WHERE identity = pIdentity;
  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- db.status_notification ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.status_notification (
    id              numeric(12) PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_STATUS'),
    device          numeric(12) NOT NULL,
    connectorId     integer NOT NULL,
    status          varchar(50) NOT NULL,
    errorCode       varchar(30) NOT NULL,
    info            text,
    vendorErrorCode	varchar(50),
    validFromDate	timestamptz DEFAULT NOW() NOT NULL,
    validToDate		timestamptz DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL,
    CONSTRAINT fk_status_notification_device FOREIGN KEY (device) REFERENCES db.device(id)
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.status_notification IS 'Уведомление о статусе.';

COMMENT ON COLUMN db.status_notification.id IS 'Идентификатор.';
COMMENT ON COLUMN db.status_notification.device IS 'Устройство.';
COMMENT ON COLUMN db.status_notification.connectorId IS 'Required. The id of the connector for which the status is reported. Id "0" (zero) is used if the status is for the Device main controller.';
COMMENT ON COLUMN db.status_notification.status IS 'Required. This contains the current status of the Device.';
COMMENT ON COLUMN db.status_notification.errorCode IS 'Required. This contains the error code reported by the Device.';
COMMENT ON COLUMN db.status_notification.info IS 'Optional. Additional free format information related to the error.';
COMMENT ON COLUMN db.status_notification.vendorErrorCode IS 'Optional. This contains the vendor-specific error code.';
COMMENT ON COLUMN db.status_notification.validFromDate IS 'Дата начала периода действия';
COMMENT ON COLUMN db.status_notification.validToDate IS 'Дата окончания периода действия.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.status_notification (device);
CREATE INDEX ON db.status_notification (connectorId);
CREATE INDEX ON db.status_notification (device, validFromDate, validToDate);

CREATE UNIQUE INDEX ON db.status_notification (device, connectorId, validFromDate, validToDate);

--------------------------------------------------------------------------------
-- FUNCTION AddStatusNotification ----------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddStatusNotification (
  pDevice           numeric,
  pConnectorId		integer,
  pStatus		    text,
  pErrorCode		text,
  pInfo			    text,
  pVendorErrorCode	text,
  pTimeStamp		timestamptz
) RETURNS 		    numeric
AS $$
DECLARE
  nId			    numeric;

  dtDateFrom 		timestamptz;
  dtDateTo 		    timestamptz;
BEGIN
  -- получим дату значения в текущем диапозоне дат
  SELECT validFromDate, validToDate INTO dtDateFrom, dtDateTo
    FROM db.status_notification
   WHERE device = pDevice
     AND connectorId = pConnectorId
     AND validFromDate <= pTimeStamp
     AND validToDate > pTimeStamp;

  IF coalesce(dtDateFrom, MINDATE()) = pTimeStamp THEN
    -- обновим значение в текущем диапозоне дат
    UPDATE db.status_notification
       SET status = pStatus,
           errorCode = pErrorCode,
           info = pInfo,
           vendorErrorCode = pVendorErrorCode
     WHERE device = pDevice
       AND connectorId = pConnectorId
       AND validFromDate <= pTimeStamp
       AND validToDate > pTimeStamp;
  ELSE
    -- обновим дату значения в текущем диапозоне дат
    UPDATE db.status_notification SET validToDate = pTimeStamp
     WHERE device = pDevice
       AND connectorId = pConnectorId
       AND validFromDate <= pTimeStamp
       AND validToDate > pTimeStamp;

    INSERT INTO db.status_notification (device, connectorId, status, errorCode, info, vendorErrorCode, validfromdate, validtodate)
    VALUES (pDevice, pConnectorId, pStatus, pErrorCode, pInfo, pVendorErrorCode, pTimeStamp, coalesce(dtDateTo, MAXDATE()))
    RETURNING id INTO nId;
  END IF;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- StatusNotification ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW StatusNotification
AS
  SELECT * FROM db.status_notification;

GRANT SELECT ON StatusNotification TO administrator;

--------------------------------------------------------------------------------
-- GetJsonStatusNotification ---------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetJsonStatusNotification (
  pDevice  numeric,
  pConnectorId  integer default null,
  pDate         timestamptz default current_timestamp at time zone 'utc'
) RETURNS	    json
AS $$
DECLARE
  arResult	    json[];
  r		        record;
BEGIN
  FOR r IN
    SELECT *
      FROM StatusNotification
     WHERE device = pDevice
       AND connectorid = coalesce(pConnectorId, connectorid)
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
-- db.transaction --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.transaction (
    id			    numeric(12) PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_TRANSACTION'),
    card		    numeric(12) NOT NULL,
    device          numeric(12) NOT NULL,
    connectorId		integer NOT NULL,
    meterStart		integer NOT NULL,
    meterStop		integer,
    reservationId	integer,
    reason		    text,
    data		    json,
    dateStart		timestamptz NOT NULL,
    dateStop		timestamptz DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL,
    CONSTRAINT fk_transaction_card FOREIGN KEY (card) REFERENCES db.card(id),
    CONSTRAINT fk_transaction_device FOREIGN KEY (device) REFERENCES db.device(id)
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.transaction IS 'Уведомление о статусе.';

COMMENT ON COLUMN db.transaction.id IS 'Идентификатор.';
COMMENT ON COLUMN db.transaction.card IS 'Пластиковая карта.';
COMMENT ON COLUMN db.transaction.device IS 'Зарядная станция.';
COMMENT ON COLUMN db.transaction.connectorId IS 'Required. This identifies which connector of the Device is used.';
COMMENT ON COLUMN db.transaction.meterStart IS 'Required. This contains the meter value in Wh for the connector at start of the transaction.';
COMMENT ON COLUMN db.transaction.meterStop IS 'Required. This contains the meter value in Wh for the connector at end of the transaction.';
COMMENT ON COLUMN db.transaction.reservationId IS 'Optional. This contains the id of the reservation that terminates as a result of this transaction.';
COMMENT ON COLUMN db.transaction.reason IS 'Optional. This contains the reason why the transaction was stopped. MAY only be omitted when the Reason is "Local".';
COMMENT ON COLUMN db.transaction.data IS 'Optional. This contains transaction usage details relevant for billing purposes.';
COMMENT ON COLUMN db.transaction.dateStart IS 'Required. This contains the date and time on which the transaction is started.';
COMMENT ON COLUMN db.transaction.dateStop IS 'Required. This contains the date and time on which the transaction is stopped.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.transaction (card);
CREATE INDEX ON db.transaction (device);
CREATE INDEX ON db.transaction (connectorId);
CREATE INDEX ON db.transaction (card, device, connectorId);

--------------------------------------------------------------------------------
-- FUNCTION StartTransaction ---------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION StartTransaction (
  pCard			    numeric,
  pDevice           numeric,
  pConnectorId		integer,
  pMeterStart		integer,
  pReservationId	integer,
  pTimeStamp		timestamptz
) RETURNS 		    numeric
AS $$
DECLARE
  nId			    numeric;
BEGIN
  INSERT INTO db.transaction (card, device, connectorId, meterStart, reservationId, dateStart)
  VALUES (pCard, pDevice, pConnectorId, pMeterStart, pReservationId, pTimeStamp)
  RETURNING id INTO nId;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION StopTransaction ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION StopTransaction (
  pId			numeric,
  pMeterStop	integer,
  pReason		text,
  pData			json,
  pTimeStamp	timestamptz
) RETURNS 		integer
AS $$
DECLARE
  nMeterStart	integer;
BEGIN
  SELECT meterStart INTO nMeterStart FROM db.transaction WHERE Id = pId;

  IF NOT FOUND THEN
    PERFORM UnknownTransaction(pId);
  END IF;

  UPDATE db.transaction
     SET meterStop = pMeterStop,
         reason = pReason,
         data = pData,
         dateStop = pTimeStamp
   WHERE id = pId;

  RETURN pMeterStop - nMeterStart;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- Transaction -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Transaction
AS
  SELECT * FROM db.transaction;

GRANT SELECT ON Transaction TO administrator;

--------------------------------------------------------------------------------
-- db.meter_value --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.meter_value (
    id			    numeric(12) PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_STATUS'),
    device          numeric(12) NOT NULL,
    connectorId		integer NOT NULL,
    transactionId	numeric(12),
    meterValue		json NOT NULL,
    validFromDate	timestamptz DEFAULT NOW() NOT NULL,
    validToDate		timestamptz DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL,
    CONSTRAINT fk_meter_value_device FOREIGN KEY (device) REFERENCES db.device(id),
    CONSTRAINT fk_meter_value_transactionId FOREIGN KEY (transactionId) REFERENCES db.transaction(id)
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.meter_value IS 'Meter values.';

COMMENT ON COLUMN db.meter_value.Id IS 'Идентификатор.';
COMMENT ON COLUMN db.meter_value.device IS 'Зарядная станция.';
COMMENT ON COLUMN db.meter_value.connectorId IS 'Required. The id of the connector for which the status is reported. Id "0" (zero) is used if the status is for the Device main controller.';
COMMENT ON COLUMN db.meter_value.transactionId IS 'Optional. The transaction to which these meter samples are related.';
COMMENT ON COLUMN db.meter_value.meterValue IS 'Required. The sampled meter values with timestamps.';
COMMENT ON COLUMN db.meter_value.validFromDate IS 'Дата начала периода действия';
COMMENT ON COLUMN db.meter_value.validToDate IS 'Дата окончания периода действия.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.meter_value (device);
CREATE INDEX ON db.meter_value (connectorId);
CREATE INDEX ON db.meter_value (transactionId);

CREATE UNIQUE INDEX ON db.meter_value (device, connectorId, validFromDate, validToDate);

--------------------------------------------------------------------------------
-- FUNCTION AddMeterValue ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddMeterValue (
  pDevice           numeric,
  pConnectorId		integer,
  pTransactionId	numeric,
  pMeterValue		json,
  pTimeStamp		timestamptz default now()
) RETURNS 		    numeric
AS $$
DECLARE
  nId			    numeric;

  dtDateFrom 		timestamptz;
  dtDateTo 		    timestamptz;
BEGIN
  -- получим дату значения в текущем диапозоне дат
  SELECT validFromDate, validToDate INTO dtDateFrom, dtDateTo
    FROM db.meter_value
   WHERE device = pDevice
     AND connectorId = pConnectorId
     AND validFromDate <= pTimeStamp
     AND validToDate > pTimeStamp;

  IF coalesce(dtDateFrom, MINDATE()) = pTimeStamp THEN
    -- обновим значение в текущем диапозоне дат
    UPDATE db.meter_value
       SET transactionId = pTransactionId,
           meterValue = pMeterValue
     WHERE device = pDevice
       AND connectorId = pConnectorId
       AND validFromDate <= pTimeStamp
       AND validToDate > pTimeStamp;
  ELSE
    -- обновим дату значения в текущем диапозоне дат
    UPDATE db.meter_value SET validToDate = pTimeStamp
     WHERE device = pDevice
       AND connectorId = pConnectorId
       AND validFromDate <= pTimeStamp
       AND validToDate > pTimeStamp;

    INSERT INTO db.meter_value (device, connectorId, transactionId, meterValue, validfromdate, validtodate)
    VALUES (pDevice, pConnectorId, pTransactionId, pMeterValue, pTimeStamp, coalesce(dtDateTo, MAXDATE()))
    RETURNING id INTO nId;
  END IF;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- VIEW MeterValue -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW MeterValue
AS
  SELECT * FROM db.meter_value;

GRANT SELECT ON MeterValue TO administrator;

--------------------------------------------------------------------------------
-- Device ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Device (Id, Document,
  Vendor, VendorCode, VendorName,
  Model, ModelCode, ModelName,
  Client, ClientCode, ClientName,
  Identity, Serial, Version, iccid, imsi
)
AS
  SELECT d.id, d.document,
         m.vendor, m.vendorcode, m.vendorname,
         d.model, m.code, m.name,
         d.client, c.code, c.fullname,
         d.identity, d.version, d.serial, d.iccid, d.imsi
    FROM db.device d INNER JOIN Model m ON m.id = d.model
                      LEFT JOIN Client c ON c.id = d.client;

GRANT SELECT ON Device TO administrator;

--------------------------------------------------------------------------------
-- ObjectDevice -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectDevice (Id, Object, Parent,
  Essence, EssenceCode, EssenceName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Vendor, VendorCode, VendorName,
  Model, ModelCode, ModelName,
  Client, ClientCode, ClientName,
  Identity, Serial, Version, iccid, imsi,
  Label, Description,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Area, AreaCode, AreaName
)
AS
  SELECT d.id, o.object, o.parent,
         o.essence, o.essencecode, o.essencename,
         o.class, o.classcode, o.classlabel,
         o.type, o.typecode, o.typename, o.typedescription,
         d.vendor, d.vendorcode, d.vendorname,
         d.model, d.modelcode, d.modelname,
         d.client, d.clientcode, d.clientname,
         d.identity, d.serial, d.version, d.iccid, d.imsi,
         o.label, o.description,
         o.statetype, o.statetypecode, o.statetypename,
         o.state, o.statecode, o.statelabel, o.lastupdate,
         o.owner, o.ownercode, o.ownername, o.created,
         o.oper, o.opercode, o.opername, o.operdate,
         o.area, o.areacode, o.areaname
    FROM Device d INNER JOIN ObjectDocument o ON o.id = d.document;

GRANT SELECT ON ObjectDevice TO administrator;
