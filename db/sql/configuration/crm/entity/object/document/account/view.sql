--------------------------------------------------------------------------------
-- Account ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Account
AS
  SELECT t.id, t.document,
         o.type, y.code AS TypeCode, ty.name AS TypeName, ty.description AS TypeDescription,
         t.currency, cr.code AS CurrencyCode, crt.name AS CurrencyName, crt.description AS CurrencyDescription,
         c.decimal AS CurrencyDecimal, c.digital AS CurrencyDigital,
         t.category, rc.code AS CategoryCode, rct.name AS CategoryName, rct.description AS CategoryDescription,
         t.client, cl.code AS ClientCode, cn.name AS ClientName,
         t.code, ot.label, dt.description, b.amount
    FROM db.account t INNER JOIN db.object            o ON o.id = t.document
                       LEFT JOIN db.object_text      ot ON ot.object = t.document AND ot.locale = current_locale()
                       LEFT JOIN db.document_text    dt ON dt.document = t.document AND dt.locale = current_locale()

                      INNER JOIN db.type              y ON y.id = o.type
                       LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                      INNER JOIN db.currency          c ON t.currency = c.id
                      INNER JOIN db.reference        cr ON c.reference = cr.id
                       LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()

                       LEFT JOIN db.reference        rc ON t.category = rc.id
                       LEFT JOIN db.reference_text  rct ON rct.reference = rc.id AND rct.locale = current_locale()

                      INNER JOIN db.client           cl ON t.client = cl.id
                       LEFT JOIN db.client_name      cn ON cn.client = cl.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()

                       LEFT JOIN db.balance           b ON t.id = b.account AND b.type = 1 AND b.validFromDate <= oper_date() AND b.validToDate > oper_date();

GRANT SELECT ON Account TO administrator;

--------------------------------------------------------------------------------
-- AccessAccount ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessAccount
AS
WITH _access AS (
  WITH _membergroup AS (
    SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
  ) SELECT object
      FROM db.aou AS a INNER JOIN db.entity    e ON a.entity = e.id AND e.code = 'account'
                       INNER JOIN _membergroup m ON a.userid = m.userid
     GROUP BY object
     HAVING (bit_or(a.allow) & ~bit_or(a.deny)) & B'100' = B'100'
) SELECT o.* FROM db.account o INNER JOIN _access ac ON o.id = ac.object;

GRANT SELECT ON AccessAccount TO administrator;

--------------------------------------------------------------------------------
-- ObjectAccount ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectAccount (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Currency, CurrencyCode, CurrencyDigital, CurrencyName, CurrencyDescription,
  Category, CategoryCode, CategoryName, CategoryDescription,
  Client, ClientCode, ClientName,
  Code, Label, Description, Balance,
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
         t.currency, crr.code, cr.digital, crt.name, crt.description,
         t.category, ar.code, art.name, art.description,
         t.client, c.code, cn.name,
         t.code, ot.label, dt.description, b.amount,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM AccessAccount t INNER JOIN db.document          d ON t.document = d.id
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

                         INNER JOIN db.currency         cr ON t.currency = cr.id
                         INNER JOIN db.reference       crr ON cr.reference = crr.id
                          LEFT JOIN db.reference_text  crt ON crt.reference = crr.id AND crt.locale = current_locale()

                          LEFT JOIN db.reference        ar ON t.category = ar.id
                          LEFT JOIN db.reference_text  art ON art.reference = ar.id AND art.locale = current_locale()

                         INNER JOIN db.client            c ON t.client = c.id
                          LEFT JOIN db.client_name      cn ON cn.client = c.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()

                          LEFT JOIN db.balance           b ON b.account = t.id AND b.type = 1 AND b.validFromDate <= oper_date() AND b.validToDate > oper_date()

                         INNER JOIN db.state_type       st ON o.state_type = st.id
                          LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                         INNER JOIN db.state             s ON o.state = s.id
                          LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                         INNER JOIN db.user              w ON o.owner = w.id
                         INNER JOIN db.user              u ON o.oper = u.id

                         INNER JOIN db.area              a ON d.area = a.id
                         INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectAccount TO administrator;
