--------------------------------------------------------------------------------
-- Order -----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW "Order"
AS
  SELECT t.id, o.parent, t.document,
         o.class, ct.code AS ClassCode, ctt.label AS ClassLabel,
         o.type, y.code AS TypeCode, ty.name AS TypeName, ty.description AS TypeDescription,
         o.state_type AS StateType, st.code AS StateTypeCode, stt.name AS StateTypeName,
         o.state, s.code AS StateCode, sst.label AS StateLabel,
         t.currency, cr.code AS CurrencyCode, crt.name AS CurrencyName, crt.description AS CurrencyDescription,
         c.decimal AS CurrencyDecimal, c.digital AS CurrencyDigital,
         t.debit, ad.code AS DebitCode, adot.label AS DebitLabel, addt.description AS DebitDescription,
         t.credit, ac.code AS CreditCode, acot.label AS CreditLabel, acdt.description AS CreditDescription,
         ad.client AS Payer, cld.code AS PayerCode, cnd.name AS PayerName,
         ac.client AS Payee, clc.code AS PayeeCode, cnc.name AS PayeeName,
         o.pdate AS Created, o.udate AS LastUpdate, o.ldate AS OperDate,
         t.code, ot.label AS name, ot.label, dt.description, t.amount
    FROM db.order t INNER JOIN db.object            o ON o.id = t.document
                     LEFT JOIN db.object_text      ot ON ot.object = t.document AND ot.locale = current_locale()
                     LEFT JOIN db.document_text    dt ON dt.document = t.document AND dt.locale = current_locale()

                    INNER JOIN db.class_tree       ct ON o.class = ct.id
                     LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                    INNER JOIN db.type              y ON o.type = y.id
                     LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                    INNER JOIN db.state_type       st ON o.state_type = st.id
                     LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                    INNER JOIN db.state             s ON o.state = s.id
                     LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                    INNER JOIN db.currency          c ON t.currency = c.id
                    INNER JOIN db.reference        cr ON c.reference = cr.id
                     LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()

                    INNER JOIN db.account          ad ON t.debit = ad.id
                    INNER JOIN db.document        add ON ad.document = add.id
                     LEFT JOIN db.object_text    adot ON adot.object = add.id AND adot.locale = current_locale()
                     LEFT JOIN db.document_text  addt ON addt.document = add.id AND addt.locale = current_locale()

                    INNER JOIN db.client          cld ON ad.client = cld.id
                     LEFT JOIN db.client_name     cnd ON cnd.client = cld.id AND cnd.locale = current_locale() AND cnd.validFromDate <= oper_date() AND cnd.validToDate > oper_date()

                    INNER JOIN db.account          ac ON t.credit = ac.id
                    INNER JOIN db.document        acd ON ac.document = acd.id
                     LEFT JOIN db.object_text    acot ON acot.object = acd.id AND acot.locale = current_locale()
                     LEFT JOIN db.document_text  acdt ON acdt.document = acd.id AND acdt.locale = current_locale()

                    INNER JOIN db.client          clc ON ac.client = clc.id
                     LEFT JOIN db.client_name     cnc ON cnc.client = clc.id AND cnc.locale = current_locale() AND cnc.validFromDate <= oper_date() AND cnc.validToDate > oper_date();

GRANT SELECT ON "Order" TO administrator;

--------------------------------------------------------------------------------
-- AccessOrder -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessOrder
AS
WITH _access AS (
  WITH _membergroup AS (
    SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
  ) SELECT object
      FROM db.aou AS a INNER JOIN db.entity    e ON a.entity = e.id AND e.code = 'order'
                       INNER JOIN _membergroup m ON a.userid = m.userid
     GROUP BY object
     HAVING (bit_or(a.allow) & ~bit_or(a.deny)) & B'100' = B'100'
) SELECT t.* FROM db.order t INNER JOIN _access ac ON t.id = ac.object;

GRANT SELECT ON AccessOrder TO administrator;

--------------------------------------------------------------------------------
-- ObjectOrder -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectOrder (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel,
  Created, LastUpdate, OperDate,
  Code, Name, Label, Description, Amount,
  Currency, CurrencyCode, CurrencyName, CurrencyDescription, CurrencyDecimal, CurrencyDigital,
  Debit, DebitCode, DebitLabel, DebitDescription,
  Credit, CreditCode, CreditLabel, CreditDescription,
  Payer, PayerCode, PayerName,
  Payee, PayeeCode, PayeeName,
  Priority, PriorityCode, PriorityName, PriorityDescription,
  Owner, OwnerCode, OwnerName,
  Oper, OperCode, OperName,
  Area, AreaCode, AreaName, AreaDescription,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, d.object, o.parent,
         o.entity, e.code, et.name,
         o.class, ct.code, ctt.label,
         o.type, y.code, ty.name, ty.description,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label,
         o.pdate, o.udate, o.ldate,
         t.code, ot.label, ot.label, dt.description, t.amount,
         t.currency, cr.code, crt.name, crt.description, c.decimal, c.digital,
         t.debit, ad.code, adot.label, addt.description,
         t.credit, ac.code, acot.label, acdt.description,
         ad.client, cld.code, cnd.name,
         ac.client, clc.code, cnc.name,
         d.priority, p.code, pt.name, pt.description,
         o.owner, w.username, w.name,
         o.oper, u.username, u.name,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.order t    INNER JOIN db.document          d ON t.document = d.id
                        LEFT JOIN db.document_text    dt ON dt.document = d.id AND dt.locale = current_locale()

                       INNER JOIN db.object            o ON t.document = o.id
                        LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()

                       INNER JOIN db.entity            e ON o.entity = e.id
                        LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()

                       INNER JOIN db.class_tree       ct ON o.class = ct.id
                        LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                       INNER JOIN db.type              y ON o.type = y.id
                        LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                       INNER JOIN db.state_type       st ON o.state_type = st.id
                        LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                       INNER JOIN db.state             s ON o.state = s.id
                        LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                       INNER JOIN db.priority          p ON d.priority = p.id
                        LEFT JOIN db.priority_text    pt ON pt.priority = p.id AND pt.locale = current_locale()

                       INNER JOIN db.currency          c ON t.currency = c.id
                       INNER JOIN db.reference        cr ON c.reference = cr.id
                        LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()

                       INNER JOIN db.account          ad ON t.debit = ad.id
                       INNER JOIN db.document        add ON ad.document = add.id
                        LEFT JOIN db.object_text    adot ON adot.object = add.id AND adot.locale = current_locale()
                        LEFT JOIN db.document_text  addt ON addt.document = add.id AND addt.locale = current_locale()

                       INNER JOIN db.client          cld ON ad.client = cld.id
                        LEFT JOIN db.client_name     cnd ON cnd.client = cld.id AND cnd.locale = current_locale() AND cnd.validFromDate <= oper_date() AND cnd.validToDate > oper_date()

                       INNER JOIN db.account          ac ON t.credit = ac.id
                       INNER JOIN db.document        acd ON ac.document = acd.id
                        LEFT JOIN db.object_text    acot ON acot.object = acd.id AND acot.locale = current_locale()
                        LEFT JOIN db.document_text  acdt ON acdt.document = acd.id AND acdt.locale = current_locale()

                       INNER JOIN db.client          clc ON ac.client = clc.id
                        LEFT JOIN db.client_name     cnc ON cnc.client = clc.id AND cnc.locale = current_locale() AND cnc.validFromDate <= oper_date() AND cnc.validToDate > oper_date()

                       INNER JOIN db.user              w ON o.owner = w.id
                       INNER JOIN db.user              u ON o.oper = u.id

                       INNER JOIN DocumentAreaTree     a ON d.area = a.id

                       INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectOrder TO administrator;
