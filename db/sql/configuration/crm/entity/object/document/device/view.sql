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
-- Device ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Device (Id, Document,
  Vendor, VendorCode, VendorName,
  Model, ModelCode, ModelName,
  Client, ClientCode, ClientName,
  Identity, Version, Serial, Address, iccid, imsi
)
AS
  SELECT d.id, d.document,
         m.vendor, m.vendorcode, m.vendorname,
         d.model, m.code, m.name,
         d.client, c.code, c.fullname,
         d.identity, d.version, d.serial, d.address, d.iccid, d.imsi
    FROM db.device d INNER JOIN Model m ON m.id = d.model
                      LEFT JOIN Client c ON c.id = d.client;

GRANT SELECT ON Device TO administrator;

--------------------------------------------------------------------------------
-- AccessDevice ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessDevice
AS
WITH _access AS (
  WITH _membergroup AS (
    SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
  ) SELECT object
      FROM db.aou AS a INNER JOIN db.entity    e ON a.entity = e.id AND e.code = 'device'
                       INNER JOIN _membergroup m ON a.userid = m.userid
     GROUP BY object
     HAVING (bit_or(a.allow) & ~bit_or(a.deny)) & B'100' = B'100'
) SELECT o.* FROM db.device o INNER JOIN _access ac ON o.id = ac.object;

GRANT SELECT ON AccessDevice TO administrator;

--------------------------------------------------------------------------------
-- ObjectDevice ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectDevice (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Vendor, VendorCode, VendorName,
  Model, ModelCode, ModelName,
  Client, ClientCode, ClientName,
  Identity, Version, Serial, Address, iccid, imsi,
  Label, Description,
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
         m.vendor, vr.code, vrt.name,
         t.model, mr.code, mrt.name,
         t.client, c.code, cn.name,
         t.identity, t.version, t.serial, t.address, t.iccid, t.imsi,
         ot.label, dt.description,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM AccessDevice t INNER JOIN db.document          d ON t.document = d.id
                        INNER JOIN DocumentAreaTreeId dat ON d.area = dat.id
                         LEFT JOIN db.document_text    dt ON dt.document = d.id AND dt.locale = current_locale()

                        INNER JOIN db.object            o ON t.document = o.id
                         LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()

                        INNER JOIN db.entity            e ON o.entity = e.id
                         LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()

                        INNER JOIN db.class_tree       ct ON o.class = ct.id
                         LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                        INNER JOIN db.type              y ON o.type = y.id
                         LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                        INNER JOIN db.model             m ON t.model = m.id
                        INNER JOIN db.reference        mr ON m.id = mr.id
                         LEFT JOIN db.reference_text  mrt ON mrt.reference = mr.id AND mrt.locale = current_locale()

                        INNER JOIN db.reference        vr ON m.vendor = vr.id
                         LEFT JOIN db.reference_text  vrt ON vrt.reference = vr.id AND vrt.locale = current_locale()

                         LEFT JOIN db.client            c ON t.client = c.id
                         LEFT JOIN db.client_name      cn ON cn.client = c.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()

                        INNER JOIN db.state_type       st ON o.state_type = st.id
                         LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                        INNER JOIN db.state             s ON o.state = s.id
                         LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                        INNER JOIN db.user              w ON o.owner = w.id
                        INNER JOIN db.user              u ON o.oper = u.id

                        INNER JOIN db.area              a ON d.area = a.id
                        INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectDevice TO administrator;
