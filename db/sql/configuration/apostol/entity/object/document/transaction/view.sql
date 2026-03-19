--------------------------------------------------------------------------------
-- Transaction -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Transaction
AS
  SELECT t.id, t.document,
         o.type, y.code AS TypeCode, ty.name AS TypeName, ty.description AS TypeDescription,
         t.client, cl.code AS ClientCode, cn.name AS ClientName,
         t.service, sr.code AS ServiceCode, srt.name AS ServiceName, srt.description AS ServiceDescription, sd.value AS ServiceValue,
         t.currency, cr.code AS CurrencyCode, c.digital AS CurrencyDigital, crt.name AS CurrencyName, crt.description AS CurrencyDescription,
         t."order", r.code AS OrderCode, rot.label AS OrderName, rdt.description AS OrderDescription,
         t.device, j.identifier, jot.label AS DeviceName, jdt.description AS DeviceDescription,
         t.tariff, fot.label AS TariffName, fdt.description AS TariffDescription,
         t.subscription, s.code AS SubscriptionCode,
         t.invoice, i.code AS InvoiceCode,
         t.transactionid, t.code, ot.label, dt.description, t.price, t.volume, t.amount, t.commission, t.tax
    FROM db.transaction t INNER JOIN db.object            o ON o.id = t.document
                           LEFT JOIN db.object_text      ot ON ot.object = t.document AND ot.locale = current_locale()
                           LEFT JOIN db.document_text    dt ON dt.document = t.document AND dt.locale = current_locale()

                          INNER JOIN db.type              y ON y.id = o.type
                           LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                          INNER JOIN db.client           cl ON t.client = cl.id
                           LEFT JOIN db.client_name      cn ON cn.client = cl.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()

                          INNER JOIN db.service          sd ON t.service = sd.id
                          INNER JOIN db.reference        sr ON sr.id = sd.reference
                           LEFT JOIN db.reference_text  srt ON srt.reference = sr.id AND srt.locale = current_locale()

                          INNER JOIN db.currency          c ON t.currency = c.id
                          INNER JOIN db.reference        cr ON c.reference = cr.id
                           LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()

                           LEFT JOIN db."order"           r ON t."order" = r.id
                           LEFT JOIN db.object_text     rot ON rot.object = r.id AND rot.locale = current_locale()
                           LEFT JOIN db.document_text   rdt ON rdt.document = r.id AND rdt.locale = current_locale()

                           LEFT JOIN db.device            j ON t.device = j.id
                           LEFT JOIN db.object_text     jot ON jot.object = j.id AND jot.locale = current_locale()
                           LEFT JOIN db.document_text   jdt ON jdt.document = j.id AND jdt.locale = current_locale()

                           LEFT JOIN db.tariff            f ON t.tariff = f.id
                           LEFT JOIN db.object_text     fot ON fot.object = f.id AND fot.locale = current_locale()
                           LEFT JOIN db.document_text   fdt ON fdt.document = f.id AND fdt.locale = current_locale()

                           LEFT JOIN db.subscription      s ON t.subscription = s.id
                           LEFT JOIN db.invoice           i ON t.invoice = i.id;

GRANT SELECT ON Transaction TO administrator;

--------------------------------------------------------------------------------
-- AccessTransaction -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessTransaction
AS
WITH _membergroup AS (
  SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
) SELECT object
    FROM db.transaction t INNER JOIN db.aou         a ON a.object = t.id
                          INNER JOIN _membergroup   m ON a.userid = m.userid
   WHERE a.mask = B'100'
   GROUP BY object;

GRANT SELECT ON AccessTransaction TO administrator;

--------------------------------------------------------------------------------
-- ObjectTransaction------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectTransaction (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Client, ClientCode, ClientName,
  Service, ServiceCode, ServiceName, ServiceDescription, ServiceValue,
  Currency, CurrencyCode, CurrencyDigital, CurrencyName, CurrencyDescription,
  "order", OrderCode, OrderName, OrderDescription,
  Device, Identifier, DeviceName, DeviceDescription,
  Tariff, TariffName, TariffDescription,
  Subscription, SubscriptionCode, SubscriptionStateCode, SubscriptionStateLabel,
  Invoice, InvoiceCode, InvoiceStateCode, InvoiceStateLabel,
  TransactionId, Code, Label, Description,
  Price, Volume, Amount, Commission, Tax,
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
         t.client, cl.code, cn.name,
         t.service, sr.code, srt.name, srt.description, sd.value,
         t.currency, cr.code, c.digital, crt.name, crt.description,
         t."order", r.code, rot.label, rdt.description,
         t.device, j.identifier, jot.label, jdt.description,
         t.tariff, fot.label, fdt.description,
         t.subscription, b.code, bs.code, bst.label,
         t.invoice, i.code, iss.code, ist.label,
         t.transactionid, t.code, ot.label, dt.description,
         t.price, t.volume, t.amount, t.commission, t.tax,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.transaction t INNER JOIN db.document          d ON t.document = d.id
                           LEFT JOIN db.document_text    dt ON dt.document = d.id AND dt.locale = current_locale()

                          INNER JOIN db.object            o ON t.document = o.id
                           LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()

                          INNER JOIN db.entity            e ON o.entity = e.id
                           LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()

                          INNER JOIN db.class_tree       ct ON o.class = ct.id
                           LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                          INNER JOIN db.type              y ON o.type = y.id
                           LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                          INNER JOIN db.client           cl ON t.client = cl.id
                           LEFT JOIN db.client_name      cn ON cn.client = cl.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()

                          INNER JOIN db.service          sd ON t.service = sd.id
                          INNER JOIN db.reference        sr ON sr.id = sd.reference
                           LEFT JOIN db.reference_text  srt ON srt.reference = sr.id AND srt.locale = current_locale()

                          INNER JOIN db.currency          c ON t.currency = c.id
                          INNER JOIN db.reference        cr ON c.reference = cr.id
                           LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()

                           LEFT JOIN db."order"           r ON t."order" = r.id
                           LEFT JOIN db.object_text     rot ON rot.object = r.id AND rot.locale = current_locale()
                           LEFT JOIN db.document_text   rdt ON rdt.document = r.id AND rdt.locale = current_locale()

                           LEFT JOIN db.device            j ON t.device = j.id
                           LEFT JOIN db.object_text     jot ON jot.object = j.id AND jot.locale = current_locale()
                           LEFT JOIN db.document_text   jdt ON jdt.document = j.id AND jdt.locale = current_locale()

                           LEFT JOIN db.tariff            f ON t.tariff = f.id
                           LEFT JOIN db.object_text     fot ON fot.object = f.id AND fot.locale = current_locale()
                           LEFT JOIN db.document_text   fdt ON fdt.document = f.id AND fdt.locale = current_locale()

                           LEFT JOIN db.subscription      b ON t.subscription = b.id
                           LEFT JOIN db.object           bo ON b.document = bo.id
                           LEFT JOIN db.state            bs ON bo.state = bs.id
                           LEFT JOIN db.state_text      bst ON bst.state = bs.id AND bst.locale = current_locale()

                           LEFT JOIN db.invoice           i ON t.invoice = i.id
                           LEFT JOIN db.object           io ON i.document = io.id
                           LEFT JOIN db.state           iss ON io.state = iss.id
                           LEFT JOIN db.state_text      ist ON ist.state = iss.id AND ist.locale = current_locale()

                          INNER JOIN db.state_type       st ON o.state_type = st.id
                           LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                          INNER JOIN db.state             s ON o.state = s.id
                           LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                          INNER JOIN db.user              w ON o.owner = w.id
                          INNER JOIN db.user              u ON o.oper = u.id

                          INNER JOIN DocumentAreaTree     a ON d.area = a.id
                          INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectTransaction TO administrator;
