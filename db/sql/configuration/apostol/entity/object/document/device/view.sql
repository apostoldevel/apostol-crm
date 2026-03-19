--------------------------------------------------------------------------------
-- DEVICE ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Device ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Device (Id, Document,
  Type, TypeCode, TypeName, TypeDescription,
  Vendor, VendorCode, VendorName, VendorDescription,
  Model, ModelCode, ModelName, ModelDescription,
  Client, ClientCode, ClientName, ClientDescription,
  Identifier, Label, Version, Serial,
  Host, Ip, iccid, imsi,
  Connected, ConnectUpdated,
  Description, Metadata
) AS
  SELECT t.id, t.document,
         o.type, y.code, ty.name, ty.description,
         m.vendor, vr.code, vrt.name, vrt.description,
         t.model, mr.code, mrt.name, mrt.description,
         t.client, c.code, cn.name, cdt.description,
         t.identifier, ot.label, t.version, t.serial,
         t.host, t.ip, t.iccid, t.imsi,
         t.connected, t.connect_updated,
         dt.description, t.metadata
    FROM db.device t INNER JOIN db.object            o ON o.id = t.document
                      LEFT JOIN db.object_text      ot ON ot.object = t.document AND ot.locale = current_locale()
                      LEFT JOIN db.document_text    dt ON dt.document = t.document AND dt.locale = current_locale()

                     INNER JOIN db.type              y ON y.id = o.type
                      LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                     INNER JOIN db.model             m ON m.id = t.model
                     INNER JOIN db.reference        mr ON mr.id = m.id
                      LEFT JOIN db.reference_text  mrt ON mrt.reference = mr.id AND mrt.locale = current_locale()

                     INNER JOIN db.reference        vr ON vr.id = m.vendor
                      LEFT JOIN db.reference_text  vrt ON vrt.reference = vr.id AND vrt.locale = current_locale()

                      LEFT JOIN db.client            c ON c.id = t.client
                      LEFT JOIN db.client_name      cn ON cn.client = c.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()
                      LEFT JOIN db.document_text   cdt ON cdt.document = c.document AND cdt.locale = current_locale();

GRANT SELECT ON Device TO administrator;

--------------------------------------------------------------------------------
-- AccessDevice ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessDevice
AS
WITH _membergroup AS (
  SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
) SELECT object
    FROM db.device t INNER JOIN db.aou         a ON a.object = t.id
                     INNER JOIN _membergroup   m ON a.userid = m.userid
   WHERE a.mask = B'100'
   GROUP BY object;

GRANT SELECT ON AccessDevice TO administrator;

--------------------------------------------------------------------------------
-- ObjectDevice ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectDevice (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Vendor, VendorCode, VendorName, VendorDescription,
  Model, ModelCode, ModelName, ModelDescription,
  Client, ClientCode, ClientName, ClientDescription,
  Identifier, Label, Version, Serial,
  Host, Ip, iccid, imsi,
  Connected, ConnectUpdated,
  Description, Metadata,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Area, AreaCode, AreaName, AreaDescription,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, d.object, o.parent,
         o.entity, e.code, et.name,
         o.class, ct.code, ctt.label,
         o.type, y.code, ty.name, ty.description,
         m.vendor, vr.code, vrt.name, vrt.description,
         t.model, mr.code, mrt.name, mrt.description,
         t.client, c.code, cn.name, cdt.description,
         t.identifier, ot.label, t.version, t.serial,
         t.host, t.ip, t.iccid, t.imsi,
         t.connected, t.connect_updated,
         dt.description,t.metadata,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.device t INNER JOIN db.document              d ON t.document = d.id
                      LEFT JOIN db.document_text        dt ON dt.document = d.id AND dt.locale = current_locale()

                     INNER JOIN db.object                o ON t.document = o.id
                      LEFT JOIN db.object_text          ot ON ot.object = o.id AND ot.locale = current_locale()

                     INNER JOIN db.entity                e ON o.entity = e.id
                      LEFT JOIN db.entity_text          et ON et.entity = e.id AND et.locale = current_locale()

                     INNER JOIN db.class_tree           ct ON o.class = ct.id
                      LEFT JOIN db.class_text          ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                     INNER JOIN db.type                  y ON o.type = y.id
                      LEFT JOIN db.type_text            ty ON ty.type = y.id AND ty.locale = current_locale()

                     INNER JOIN db.model                 m ON t.model = m.id
                     INNER JOIN db.reference            mr ON m.id = mr.id
                      LEFT JOIN db.reference_text      mrt ON mrt.reference = mr.id AND mrt.locale = current_locale()

                     INNER JOIN db.reference            vr ON m.vendor = vr.id
                      LEFT JOIN db.reference_text      vrt ON vrt.reference = vr.id AND vrt.locale = current_locale()

                      LEFT JOIN db.client                c ON t.client = c.id
                      LEFT JOIN db.client_name          cn ON cn.client = c.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()
                      LEFT JOIN db.document_text       cdt ON cdt.document = c.document AND cdt.locale = current_locale()

                     INNER JOIN db.state_type           st ON o.state_type = st.id
                      LEFT JOIN db.state_type_text     stt ON stt.type = st.id AND stt.locale = current_locale()

                     INNER JOIN db.state                 s ON o.state = s.id
                      LEFT JOIN db.state_text          sst ON sst.state = s.id AND sst.locale = current_locale()

                     INNER JOIN db.user                  w ON o.owner = w.id
                     INNER JOIN db.user                  u ON o.oper = u.id

                     INNER JOIN DocumentAreaTree         a ON d.area = a.id
                     INNER JOIN db.scope                sc ON o.scope = sc.id;

GRANT SELECT ON ObjectDevice TO administrator;

--------------------------------------------------------------------------------
-- DeviceNotification ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW DeviceNotification
AS
  SELECT * FROM db.device_notification;

GRANT SELECT ON DeviceNotification TO administrator;

--------------------------------------------------------------------------------
-- VIEW DeviceValue ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW DeviceValue
AS
  SELECT * FROM db.device_value;

GRANT SELECT ON DeviceValue TO administrator;

--------------------------------------------------------------------------------
-- VIEW DeviceData -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW DeviceData
AS
  SELECT * FROM db.device_data;

GRANT SELECT ON DeviceData TO administrator;

--------------------------------------------------------------------------------
-- StationTransaction ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW StationTransaction
AS
  SELECT t.id, t.device, d.identifier, ot.label,
         t.meterstart, t.meterstop, t.reason, t.data, t.datestart, t.datestop, t.volume
    FROM db.device_transaction t INNER JOIN db.device       d ON d.id = t.device
                                  LEFT JOIN db.object_text ot ON ot.object = d.document AND ot.locale = current_locale();

GRANT SELECT ON StationTransaction TO administrator;

--------------------------------------------------------------------------------
-- VIEW MeterValue -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW MeterValue
AS
  SELECT t.id, t.device, d.identifier, d.serial,
         t.transactionId, t.value, t.meterValue, t.meterCost,
         t.validfromdate, t.validtodate
    FROM db.meter_value t INNER JOIN db.device d ON t.id = t.device;

GRANT SELECT ON MeterValue TO administrator;

--------------------------------------------------------------------------------
-- DataTransfer ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW DataTransfer
AS
  SELECT t.id, t.datetime, t.timestamp, t.device, d.identifier, d.serial,
         t.messageid, t.data
    FROM db.data_transfer t INNER JOIN db.device d ON d.id = t.device;

GRANT SELECT ON DataTransfer TO administrator;
