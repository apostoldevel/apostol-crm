--------------------------------------------------------------------------------
-- Price -----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Price
AS
  SELECT t.id, t.document,
         o.type, y.code AS TypeCode, ty.name AS TypeName, ty.description AS TypeDescription,
         t.currency, cr.code AS CurrencyCode, crt.name AS CurrencyName, crt.description AS CurrencyDescription,
         c.decimal AS CurrencyDecimal, c.digital AS CurrencyDigital,
         t.product, p.code AS ProductCode, p.name AS ProductName, pot.label AS ProductLabel, pdt.description AS ProductDescription,
         t.code, ot.label, dt.description,
         t.amount, t.payment_link AS PaymentLink, t.metadata
    FROM db.price t INNER JOIN db.object            o ON o.id = t.document
                     LEFT JOIN db.object_text      ot ON ot.object = t.document AND ot.locale = current_locale()
                     LEFT JOIN db.document_text    dt ON dt.document = t.document AND dt.locale = current_locale()

                    INNER JOIN db.type              y ON y.id = o.type
                     LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                    INNER JOIN db.currency          c ON t.currency = c.id
                    INNER JOIN db.reference        cr ON c.reference = cr.id
                     LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()

                    INNER JOIN db.product           p ON t.product = p.id
                    INNER JOIN db.document         pd ON p.document = pd.id
                     LEFT JOIN db.object_text     pot ON pot.object = pd.id AND pot.locale = current_locale()
                     LEFT JOIN db.document_text   pdt ON pdt.document = pd.id AND pdt.locale = current_locale();

GRANT SELECT ON Price TO administrator;

--------------------------------------------------------------------------------
-- AccessPrice -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessPrice
AS
WITH _membergroup AS (
  SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
) SELECT object
    FROM db.price t INNER JOIN db.aou         a ON a.object = t.id
                    INNER JOIN _membergroup   m ON a.userid = m.userid
   WHERE a.mask = B'100'
   GROUP BY object;

GRANT SELECT ON AccessPrice TO administrator;

--------------------------------------------------------------------------------
-- ObjectPrice -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectPrice (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Currency, CurrencyCode, CurrencyName, CurrencyDescription, CurrencyDecimal, CurrencyDigital,
  Product, ProductCode, ProductName, ProductLabel, ProductDescription,
  Code, Label, Description,
  Amount, PaymentLink, MetaData,
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
         t.product, p.code, p.name, pot.label, pdt.description,
         t.code, ot.label, dt.description,
         t.amount, t.payment_link, t.metadata,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.price t INNER JOIN db.document          d ON t.document = d.id
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

                    INNER JOIN db.product           p ON t.product = p.id
                    INNER JOIN db.document         pd ON p.document = pd.id
                     LEFT JOIN db.object_text     pot ON pot.object = pd.id AND pot.locale = current_locale()
                     LEFT JOIN db.document_text   pdt ON pdt.document = pd.id AND pdt.locale = current_locale()

                    INNER JOIN db.state_type       st ON o.state_type = st.id
                     LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                    INNER JOIN db.state             s ON o.state = s.id
                     LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                    INNER JOIN db.user              w ON o.owner = w.id
                    INNER JOIN db.user              u ON o.oper = u.id

                    INNER JOIN DocumentAreaTree     a ON d.area = a.id
                    INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectPrice TO administrator;
