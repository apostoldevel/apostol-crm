--------------------------------------------------------------------------------
-- DEVICE ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.device -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.device (
    id                  uuid PRIMARY KEY,
    document            uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    model               uuid NOT NULL REFERENCES db.model(id) ON DELETE RESTRICT,
    client              uuid REFERENCES db.client(id) ON DELETE RESTRICT,
    identifier          text NOT NULL,
    pswhash             text,
    version             text,
    serial              text,
    host                text,
    ip                  inet,
    iccid               text,
    imsi                text,
    connected           boolean,
    connect_updated     timestamptz,
    metadata            jsonb
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.device IS 'Physical or virtual device (e.g., charging station, IoT sensor) registered in the system.';

COMMENT ON COLUMN db.device.id IS 'Primary key, matches the parent document ID.';
COMMENT ON COLUMN db.device.document IS 'Reference to the parent document.';
COMMENT ON COLUMN db.device.model IS 'Device model reference.';
COMMENT ON COLUMN db.device.client IS 'Client who owns or manages this device, if assigned.';
COMMENT ON COLUMN db.device.identifier IS 'Unique string identifier for the device (e.g., serial number or vendor ID).';
COMMENT ON COLUMN db.device.pswhash IS 'Password hash used for device-to-server authentication.';
COMMENT ON COLUMN db.device.version IS 'Firmware or software version of the device.';
COMMENT ON COLUMN db.device.serial IS 'Manufacturer serial number. Unique within a model.';
COMMENT ON COLUMN db.device.host IS 'Hostname or FQDN of the device.';
COMMENT ON COLUMN db.device.ip IS 'IP address of the device.';
COMMENT ON COLUMN db.device.iccid IS 'Integrated Circuit Card Identifier (ICCID) — unique SIM card serial number.';
COMMENT ON COLUMN db.device.imsi IS 'International Mobile Subscriber Identity (IMSI) — unique mobile subscriber identifier.';
COMMENT ON COLUMN db.device.connected IS 'Whether the device is currently connected.';
COMMENT ON COLUMN db.device.connect_updated IS 'Timestamp of the last connection status change.';
COMMENT ON COLUMN db.device.metadata IS 'Additional device data in JSON format.';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.device (identifier);
CREATE UNIQUE INDEX ON db.device (model, serial);

CREATE INDEX ON db.device (document);
CREATE INDEX ON db.device (model);
CREATE INDEX ON db.device (client);
CREATE INDEX ON db.device (serial);
CREATE INDEX ON db.device USING GIN (metadata jsonb_path_ops);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_device_before_insert()
RETURNS trigger AS $$
DECLARE
  uOwner    uuid;
  uUserId   uuid;
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NEW.client IS NOT NULL THEN
    SELECT owner INTO uOwner FROM db.object WHERE id = NEW.document;

    uUserId := GetClientUserId(NEW.client);
    IF uOwner <> uUserId THEN
      UPDATE db.aou SET allow = allow | B'110' WHERE object = NEW.document AND userid = uUserId;
      IF NOT FOUND THEN
        INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'110';
      END IF;
    END IF;
  END IF;

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

CREATE OR REPLACE FUNCTION ft_device_before_update()
RETURNS trigger AS $$
DECLARE
  uOwner    uuid;
  uUserId   uuid;
BEGIN
  IF OLD.client <> NEW.client THEN
    SELECT owner INTO uOwner FROM db.object WHERE id = NEW.document;

    IF NEW.client IS NOT NULL THEN
      uUserId := GetClientUserId(NEW.client);
      IF uOwner <> uUserId THEN
        UPDATE db.aou SET allow = allow | B'110' WHERE object = NEW.document AND userid = uUserId;
        IF NOT FOUND THEN
          INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'110';
        END IF;
      END IF;
    END IF;

    IF OLD.client IS NOT NULL THEN
      uUserId := GetClientUserId(OLD.client);
      IF uOwner <> uUserId THEN
        DELETE FROM db.aou WHERE object = OLD.document AND userid = uUserId;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_device_before_update
  BEFORE UPDATE ON db.device
  FOR EACH ROW
  EXECUTE PROCEDURE ft_device_before_update();

--------------------------------------------------------------------------------
-- db.device_notification ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.device_notification (
    id              uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    device          uuid NOT NULL REFERENCES db.device(id) ON DELETE CASCADE,
    interfaceId     integer NOT NULL DEFAULT 0,
    status          text NOT NULL,
    errorCode       text NOT NULL,
    info            text,
    vendorErrorCode text,
    validFromDate   timestamp DEFAULT NOW() NOT NULL,
    validToDate     timestamp DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.device_notification IS 'Device status notification with temporal validity. Tracks status changes and error reports per interface.';

COMMENT ON COLUMN db.device_notification.id IS 'Primary key, auto-generated UUID.';
COMMENT ON COLUMN db.device_notification.device IS 'Device that reported this notification.';
COMMENT ON COLUMN db.device_notification.interfaceId IS 'Interface or port identifier on the device. 0 represents the device itself.';
COMMENT ON COLUMN db.device_notification.status IS 'Current status reported by the device.';
COMMENT ON COLUMN db.device_notification.errorCode IS 'Error code reported by the device.';
COMMENT ON COLUMN db.device_notification.info IS 'Free-form additional information related to the error.';
COMMENT ON COLUMN db.device_notification.vendorErrorCode IS 'Vendor-specific error code.';
COMMENT ON COLUMN db.device_notification.validFromDate IS 'Start of the validity period for this notification.';
COMMENT ON COLUMN db.device_notification.validToDate IS 'End of the validity period for this notification.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.device_notification (device);
CREATE INDEX ON db.device_notification (interfaceId);
CREATE INDEX ON db.device_notification (device, validFromDate, validToDate);

CREATE UNIQUE INDEX ON db.device_notification (device, interfaceId, validFromDate, validToDate);

--------------------------------------------------------------------------------
-- db.device_value -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.device_value (
    id              uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    device          uuid NOT NULL REFERENCES db.device(id) ON DELETE CASCADE,
    type            integer NOT NULL,
    value           jsonb NOT NULL,
    validFromDate   timestamp DEFAULT NOW() NOT NULL,
    validToDate     timestamp DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.device_value IS 'Temporal key-value storage for device measurements and parameters.';

COMMENT ON COLUMN db.device_value.id IS 'Primary key, auto-generated UUID.';
COMMENT ON COLUMN db.device_value.device IS 'Device this value belongs to.';
COMMENT ON COLUMN db.device_value.type IS 'Value type identifier (application-defined).';
COMMENT ON COLUMN db.device_value.value IS 'Value payload in JSON format.';
COMMENT ON COLUMN db.device_value.validFromDate IS 'Start of the validity period for this value.';
COMMENT ON COLUMN db.device_value.validToDate IS 'End of the validity period for this value.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.device_value (device);
CREATE INDEX ON db.device_value (type);

CREATE UNIQUE INDEX ON db.device_value (device, type, validFromDate, validToDate);

--------------------------------------------------------------------------------
-- db.device_data --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.device_data (
    id              uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    device          uuid NOT NULL REFERENCES db.device(id) ON DELETE CASCADE,
    agent           text NOT NULL,
    data            bytea NOT NULL,
    validFromDate   timestamp DEFAULT NOW() NOT NULL,
    validToDate     timestamp DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.device_data IS 'Binary data blobs associated with a device and agent, with temporal validity.';

COMMENT ON COLUMN db.device_data.id IS 'Primary key, auto-generated UUID.';
COMMENT ON COLUMN db.device_data.device IS 'Device this data belongs to.';
COMMENT ON COLUMN db.device_data.agent IS 'Agent or protocol identifier that produced this data.';
COMMENT ON COLUMN db.device_data.data IS 'Binary payload from the device.';
COMMENT ON COLUMN db.device_data.validFromDate IS 'Start of the validity period for this data.';
COMMENT ON COLUMN db.device_data.validToDate IS 'End of the validity period for this data.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.device_data (device);
CREATE INDEX ON db.device_data (agent);

CREATE UNIQUE INDEX ON db.device_data (device, agent, validFromDate, validToDate);

--------------------------------------------------------------------------------
-- db.device_transaction ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.device_transaction (
    id              bigserial NOT NULL PRIMARY KEY,
    device          uuid NOT NULL REFERENCES db.device(id) ON DELETE RESTRICT,
    meterStart      integer NOT NULL,
    meterStop       integer,
    reason          text,
    data            jsonb,
    dateStart       timestamptz NOT NULL DEFAULT Now(),
    dateStop        timestamptz NOT NULL DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD'),
    volume          integer NOT NULL DEFAULT 0
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.device_transaction IS 'Device-level transaction tracking metered service consumption (e.g., charging session on a station).';

COMMENT ON COLUMN db.device_transaction.id IS 'Auto-incremented primary key.';
COMMENT ON COLUMN db.device_transaction.device IS 'Device on which this transaction occurred.';
COMMENT ON COLUMN db.device_transaction.meterStart IS 'Meter reading (in device units) at the start of the transaction.';
COMMENT ON COLUMN db.device_transaction.meterStop IS 'Meter reading (in device units) when the transaction stopped.';
COMMENT ON COLUMN db.device_transaction.reason IS 'Reason the transaction was stopped (e.g., user action, error, timeout).';
COMMENT ON COLUMN db.device_transaction.data IS 'Usage details needed for billing in JSON format.';
COMMENT ON COLUMN db.device_transaction.dateStart IS 'Timestamp when the transaction started.';
COMMENT ON COLUMN db.device_transaction.dateStop IS 'Timestamp when the transaction stopped.';
COMMENT ON COLUMN db.device_transaction.volume IS 'Total volume of service delivered during this transaction.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.device_transaction (device);
CREATE INDEX ON db.device_transaction (device);
CREATE UNIQUE INDEX ON db.device_transaction (device, device, dateStart, dateStop);

--------------------------------------------------------------------------------
-- db.device_limit ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.device_limit (
    id              uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    device          uuid NOT NULL REFERENCES db.device(id) ON DELETE CASCADE,
    mode            integer NOT NULL DEFAULT 0 CHECK ( mode IN (0, 1, 2) ),
    value           numeric NOT NULL DEFAULT 0,
    validFromDate   timestamptz DEFAULT Now() NOT NULL,
    validToDate     timestamptz DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.device_limit IS 'Usage limits applied to a device with temporal validity.';

COMMENT ON COLUMN db.device_limit.id IS 'Primary key, auto-generated UUID.';
COMMENT ON COLUMN db.device_limit.device IS 'Device this limit applies to.';
COMMENT ON COLUMN db.device_limit.mode IS 'Limit mode: 0 = unlimited, 1 = time-limited (minutes), 2 = amount-limited.';
COMMENT ON COLUMN db.device_limit.value IS 'Limit value (interpretation depends on mode).';
COMMENT ON COLUMN db.device_limit.validFromDate IS 'Start of the validity period for this limit.';
COMMENT ON COLUMN db.device_limit.validToDate IS 'End of the validity period for this limit.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.device_limit (device);
CREATE INDEX ON db.device_limit (device, device, validFromDate, validToDate);

--------------------------------------------------------------------------------
-- db.meter_value --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.meter_value (
    id              uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    device          uuid NOT NULL REFERENCES db.device(id),
    transactionId   bigint REFERENCES db.device_transaction(id) ON DELETE CASCADE,
    meterValue      jsonb NOT NULL,
    meterCost       jsonb,
    value           integer NOT NULL,
    validFromDate   timestamptz DEFAULT Now() NOT NULL,
    validToDate     timestamptz DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.meter_value IS 'Meter readings sampled from a device during a transaction, with associated costs.';

COMMENT ON COLUMN db.meter_value.id IS 'Primary key, auto-generated UUID.';
COMMENT ON COLUMN db.meter_value.device IS 'Device from which the meter reading was taken.';
COMMENT ON COLUMN db.meter_value.transactionId IS 'Device transaction these meter samples belong to.';
COMMENT ON COLUMN db.meter_value.meterValue IS 'Sampled meter values with timestamps in JSON format.';
COMMENT ON COLUMN db.meter_value.meterCost IS 'Cost breakdown for the meter readings in JSON format.';
COMMENT ON COLUMN db.meter_value.value IS 'Current meter reading as an integer.';
COMMENT ON COLUMN db.meter_value.validFromDate IS 'Start of the validity period for this reading.';
COMMENT ON COLUMN db.meter_value.validToDate IS 'End of the validity period for this reading.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.meter_value (device);
CREATE INDEX ON db.meter_value (transactionId);
CREATE UNIQUE INDEX ON db.meter_value (device, validFromDate, validToDate);

--------------------------------------------------------------------------------
-- db.data_transfer ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE UNLOGGED TABLE db.data_transfer (
    id              bigserial PRIMARY KEY NOT NULL,
    datetime        timestamptz DEFAULT clock_timestamp() NOT NULL,
    timestamp       timestamptz DEFAULT Now() NOT NULL,
    device          uuid NOT NULL REFERENCES db.device(id) ON DELETE CASCADE,
    messageId       text NOT NULL,
    data            bytea NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.data_transfer IS 'Raw data transfer log from devices. Unlogged table for high-throughput message capture.';

COMMENT ON COLUMN db.data_transfer.id IS 'Auto-incremented primary key.';
COMMENT ON COLUMN db.data_transfer.datetime IS 'Wall-clock timestamp when the record was written.';
COMMENT ON COLUMN db.data_transfer.timestamp IS 'Transaction timestamp (logical time).';
COMMENT ON COLUMN db.data_transfer.device IS 'Device that sent this data.';
COMMENT ON COLUMN db.data_transfer.messageId IS 'Protocol-level message identifier.';
COMMENT ON COLUMN db.data_transfer.data IS 'Raw binary payload from the device.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.data_transfer (device);
CREATE INDEX ON db.data_transfer (messageId);
CREATE INDEX ON db.data_transfer (datetime);
