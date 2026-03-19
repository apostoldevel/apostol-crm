--------------------------------------------------------------------------------
-- Subscription ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Subscription
AS
  SELECT t.id, t.document,
         o.type, y.code AS TypeCode, ty.name AS TypeName, ty.description AS TypeDescription,
         o.state_type AS StateType, st.code AS StateTypeCode, stt.name AS StateTypeName,
         o.state, s.code AS StateCode, sst.label AS StateLabel,
         t.client, cl.code AS ClientCode, cn.name AS ClientName, t.customer,
         p.product, pr.code AS ProductCode, pr.name AS ProductName, prot.label AS ProductLabel, prdt.description AS ProductDescription,
         t.price, p.code AS PriceCode, pot.label AS PriceLabel, pdt.description AS PriceDescription,
         p.currency, cr.code AS CurrencyCode, crt.name AS CurrencyName, crt.description AS CurrencyDescription,
         c.decimal AS CurrencyDecimal, c.digital AS CurrencyDigital,
         t.code, ot.label, dt.description, t.period_start, t.period_end, t.metadata, current
    FROM db.subscription t INNER JOIN db.object            o ON o.id = t.document
                            LEFT JOIN db.object_text      ot ON ot.object = t.document AND ot.locale = current_locale()
                            LEFT JOIN db.document_text    dt ON dt.document = t.document AND dt.locale = current_locale()

                           INNER JOIN db.type              y ON y.id = o.type
                            LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                            INNER JOIN db.state_type       st ON o.state_type = st.id
                             LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                            INNER JOIN db.state             s ON o.state = s.id
                             LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                            LEFT JOIN db.client           cl ON t.client = cl.id
                            LEFT JOIN db.client_name      cn ON cn.client = cl.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()

                           INNER JOIN db.price             p ON t.price = p.id
                           INNER JOIN db.document         pd ON p.document = pd.id
                            LEFT JOIN db.object_text     pot ON pot.object = pd.id AND pot.locale = current_locale()
                            LEFT JOIN db.document_text   pdt ON pdt.document = pd.id AND pdt.locale = current_locale()

                           INNER JOIN db.product          pr ON p.product = pr.id
                           INNER JOIN db.document        prd ON pr.document = prd.id
                            LEFT JOIN db.object_text    prot ON prot.object = prd.id AND prot.locale = current_locale()
                            LEFT JOIN db.document_text  prdt ON prdt.document = prd.id AND prdt.locale = current_locale()

                           INNER JOIN db.currency          c ON p.currency = c.id
                           INNER JOIN db.reference        cr ON c.reference = cr.id
                            LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale();

GRANT SELECT ON Subscription TO administrator;

--------------------------------------------------------------------------------
-- AccessSubscription ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessSubscription
AS
WITH _membergroup AS (
  SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
) SELECT object
    FROM db.subscription t INNER JOIN db.aou         a ON a.object = t.id
                           INNER JOIN _membergroup   m ON a.userid = m.userid
   WHERE a.mask = B'100'
   GROUP BY object;

GRANT SELECT ON AccessSubscription TO administrator;

--------------------------------------------------------------------------------
-- ObjectSubscription ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectSubscription (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Client, ClientCode, ClientName, Customer,
  Product, ProductCode, ProductName, ProductLabel, ProductDescription,
  Price, PriceCode, PriceLabel, PriceDescription,
  Currency, CurrencyCode, CurrencyName, CurrencyDescription, CurrencyDecimal, CurrencyDigital,
  Code, Label, Description, PeriodStart, PeriodEnd, MetaData, Current,
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
         t.client, cl.code, cn.name, t.customer,
         p.product, pr.code, pr.name, prot.label, prdt.description,
         t.price, p.code, pot.label, pdt.description,
         p.currency, cr.code, crt.name, crt.description, c.decimal, c.digital,
         t.code, ot.label, dt.description, t.period_start, t.period_end, t.metadata, t.current,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.subscription t INNER JOIN db.document          d ON t.document = d.id
                            LEFT JOIN db.document_text    dt ON dt.document = d.id AND dt.locale = current_locale()

                           INNER JOIN db.object            o ON t.document = o.id
                            LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()

                           INNER JOIN db.entity            e ON o.entity = e.id
                            LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()

                           INNER JOIN db.class_tree       ct ON o.class = ct.id
                            LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                           INNER JOIN db.type              y ON o.type = y.id
                            LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                            LEFT JOIN db.client           cl ON t.client = cl.id
                            LEFT JOIN db.client_name      cn ON cn.client = cl.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()

                           INNER JOIN db.price             p ON t.price = p.id
                           INNER JOIN db.document         pd ON p.document = pd.id
                            LEFT JOIN db.object_text     pot ON pot.object = pd.id AND pot.locale = current_locale()
                            LEFT JOIN db.document_text   pdt ON pdt.document = pd.id AND pdt.locale = current_locale()

                           INNER JOIN db.product          pr ON p.product = pr.id
                           INNER JOIN db.document        prd ON pr.document = prd.id
                            LEFT JOIN db.object_text    prot ON prot.object = prd.id AND prot.locale = current_locale()
                            LEFT JOIN db.document_text  prdt ON prdt.document = prd.id AND prdt.locale = current_locale()

                           INNER JOIN db.currency          c ON p.currency = c.id
                           INNER JOIN db.reference        cr ON c.reference = cr.id
                            LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()

                           INNER JOIN db.state_type       st ON o.state_type = st.id
                            LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                           INNER JOIN db.state             s ON o.state = s.id
                            LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                           INNER JOIN db.user              w ON o.owner = w.id
                           INNER JOIN db.user              u ON o.oper = u.id

                           INNER JOIN DocumentAreaTree     a ON d.area = a.id
                           INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectSubscription TO administrator;
