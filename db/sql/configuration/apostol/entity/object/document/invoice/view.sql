--------------------------------------------------------------------------------
-- Invoice ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Invoice
AS
  SELECT t.id, t.document,
         o.type, y.code AS TypeCode, ty.name AS TypeName, ty.description AS TypeDescription,
         t.currency, cr.code AS CurrencyCode, crt.name AS CurrencyName, crt.description AS CurrencyDescription,
         c.decimal AS CurrencyDecimal, c.digital AS CurrencyDigital,
         t.client, cd.code AS ClientCode, cn.name AS ClientName, cn.short AS ClientShort, cn.last AS ClientLast, cn.first AS ClientFirst, cn.middle AS ClientMiddle,
         t.device, d.identifier AS DeviceIdentifier, dot.label AS DeviceLabel, ddt.description AS DeviceDescription,
         t.code, ot.label, dt.description, t.amount, t.pdf
    FROM db.invoice t INNER JOIN db.object            o ON o.id = t.document
                       LEFT JOIN db.object_text      ot ON ot.object = t.document AND ot.locale = current_locale()
                       LEFT JOIN db.document_text    dt ON dt.document = t.document AND dt.locale = current_locale()

                      INNER JOIN db.type              y ON y.id = o.type
                       LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                      INNER JOIN db.currency          c ON t.currency = c.id
                      INNER JOIN db.reference        cr ON c.reference = cr.id
                       LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()

                       LEFT JOIN db.client           cd ON t.client = cd.id
                       LEFT JOIN db.client_name      cn ON cn.client = cd.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()

                       LEFT JOIN db.device            d ON d.id = t.device
                       LEFT JOIN db.object_text     dot ON dot.object = d.id AND dot.locale = current_locale()
                       LEFT JOIN db.document_text   ddt ON ddt.document = d.id AND ddt.locale = current_locale();

GRANT SELECT ON Invoice TO administrator;

--------------------------------------------------------------------------------
-- AccessInvoice ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessInvoice
AS
WITH _membergroup AS (
  SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
) SELECT object
    FROM db.invoice t INNER JOIN db.aou         a ON a.object = t.id
                      INNER JOIN _membergroup   m ON a.userid = m.userid
   WHERE a.mask = B'100'
   GROUP BY object;

GRANT SELECT ON AccessInvoice TO administrator;

--------------------------------------------------------------------------------
-- ObjectInvoice ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectInvoice (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Currency, CurrencyCode, CurrencyName, CurrencyDescription, CurrencyDecimal, CurrencyDigital,
  Client, ClientCode, FullName, ShortName, LastName, FirstName, MiddleName,
  Device, DeviceIdentifier, DeviceLabel, DeviceDescription,
  Code, Label, Description, Amount, PDF,
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
         t.currency, cr.code, crt.name, crt.description, c.digital, c.decimal,
         t.client, cd.code, cn.name, cn.short, cn.last, cn.first, cn.middle,
         t.device, p.identifier, pot.label, pdt.description,
         t.code, ot.label, dt.description, t.amount, t.pdf,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.invoice t INNER JOIN db.document          d ON t.document = d.id
                       LEFT JOIN db.document_text    dt ON dt.document = d.id AND dt.locale = current_locale()

                      INNER JOIN db.object            o ON t.document = o.id
                       LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()

                      INNER JOIN db.entity            e ON o.entity = e.id
                       LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()

                      INNER JOIN db.class_tree       ct ON o.class = ct.id
                       LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                      INNER JOIN db.type              y ON o.type = y.id
                       LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                      INNER JOIN db.currency          c ON t.currency = c.id
                      INNER JOIN db.reference        cr ON c.reference = cr.id
                       LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()

                       LEFT JOIN db.client           cd ON t.client = cd.id
                       LEFT JOIN db.client_name      cn ON cn.client = cd.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()

                       LEFT JOIN db.device            p ON d.id = t.device
                       LEFT JOIN db.object_text     pot ON pot.object = p.id AND pot.locale = current_locale()
                       LEFT JOIN db.document_text   pdt ON pdt.document = p.id AND pdt.locale = current_locale()

                      INNER JOIN db.state_type       st ON o.state_type = st.id
                       LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                      INNER JOIN db.state             s ON o.state = s.id
                       LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                      INNER JOIN db.user              w ON o.owner = w.id
                      INNER JOIN db.user              u ON o.oper = u.id

                      INNER JOIN DocumentAreaTree     a ON d.area = a.id
                      INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectInvoice TO administrator;
