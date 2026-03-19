--------------------------------------------------------------------------------
-- Payment ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Payment
AS
  SELECT t.id, o.parent, t.document,
         o.class, ct.code AS ClassCode, ctt.label AS ClassLabel,
         o.type, y.code AS TypeCode, ty.name AS TypeName, ty.description AS TypeDescription,
         o.state_type AS StateType, st.code AS StateTypeCode, stt.name AS StateTypeName,
         o.state, s.code AS StateCode, sst.label AS StateLabel,
         t.currency, cr.code AS CurrencyCode, crt.name AS CurrencyName, crt.description AS CurrencyDescription,
         t.client, l.code AS ClientCode, cn.name AS ClientName,
         t.card, cd.code AS CardCode,
         t.invoice, i.code AS InvoiceCode,
         t."order", od.code AS OrderCode,
         o.pdate AS Created, o.udate AS LastUpdate, o.ldate AS OperDate,
         t.code, ot.label AS Name, ot.label, dt.description,
         t.amount, t.payment_id AS PaymentId, t.metadata
    FROM db.payment t INNER JOIN db.object            o ON o.id = t.document
                       LEFT JOIN db.object_text      ot ON ot.object = t.document AND ot.locale = current_locale()
                       LEFT JOIN db.document_text    dt ON dt.document = t.document AND dt.locale = current_locale()

                      INNER JOIN db.class_tree       ct ON o.class = ct.id
                       LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                      INNER JOIN db.type              y ON y.id = o.type
                       LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                      INNER JOIN db.state_type       st ON o.state_type = st.id
                       LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                      INNER JOIN db.state             s ON o.state = s.id
                       LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                      INNER JOIN db.currency          c ON t.currency = c.id
                      INNER JOIN db.reference        cr ON c.reference = cr.id
                       LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()

                      INNER JOIN db.client            l ON l.id = t.client
                       LEFT JOIN db.client_name      cn ON cn.client = l.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()

                       LEFT JOIN db.card             cd ON cd.id = t.card
                       LEFT JOIN db.invoice           i ON i.id = t.invoice
                       LEFT JOIN db.order            od ON od.id = t."order";

GRANT SELECT ON Payment TO administrator;

--------------------------------------------------------------------------------
-- AccessPayment ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessPayment
AS
WITH _access AS (
   WITH _membergroup AS (
     SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
   ) SELECT object
       FROM db.aou AS a INNER JOIN db.entity    e ON a.entity = e.id AND e.code = 'payment'
                        INNER JOIN _membergroup m ON a.userid = m.userid
      GROUP BY object
      HAVING (bit_or(a.allow) & ~bit_or(a.deny)) & B'100' = B'100'
) SELECT t.* FROM db.payment t INNER JOIN _access ac ON t.id = ac.object;

GRANT SELECT ON AccessPayment TO administrator;

--------------------------------------------------------------------------------
-- ObjectPayment ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectPayment (Id, Object, Parent,
	Entity, EntityCode, EntityName,
	Class, ClassCode, ClassLabel,
	Type, TypeCode, TypeName, TypeDescription,
	StateType, StateTypeCode, StateTypeName,
	State, StateCode, StateLabel,
	Created, LastUpdate, OperDate,
	Code, Name, Label, Description,
	Amount, PaymentId, Metadata,
	Currency, CurrencyCode, CurrencyName, CurrencyDescription,
	Client, ClientCode, ClientName,
	Card, CardCode,
	Invoice, InvoiceCode, InvoiceStateCode, InvoiceStateLabel,
	"Order", OrderCode, OrderStateCode, OrderStateLabel,
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
         t.code, ot.label, ot.label, dt.description,
         t.amount, t.payment_id, t.metadata,
         t.currency, c.code, rct.name, rct.description,
         t.client, l.code, cn.name,
         t.card, cd.code,
         t.invoice, i.code, iss.code, ist.label,
         t."order", od.code, ods.code, odst.label,
         d.priority, p.code, pt.name, pt.description,
         o.owner, w.username, w.name,
         o.oper, u.username, u.name,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.payment t    INNER JOIN db.document          d ON t.document = d.id
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

                         INNER JOIN db.reference         c ON c.id = t.currency
                         INNER JOIN db.reference_text  rct ON rct.reference = c.id AND rct.locale = current_locale()

                         INNER JOIN db.client            l ON l.id = t.client
                          LEFT JOIN db.client_name      cn ON cn.client = l.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()

                          LEFT JOIN db.card             cd ON cd.id = t.card

                          LEFT JOIN db.invoice           i ON t.invoice = i.id
                          LEFT JOIN db.object           io ON i.document = io.id
                          LEFT JOIN db.state           iss ON io.state = iss.id
                          LEFT JOIN db.state_text      ist ON ist.state = iss.id AND ist.locale = current_locale()

                          LEFT JOIN db.order            od ON od.id = t."order"
                          LEFT JOIN db.object          odo ON od.document = odo.id
                          LEFT JOIN db.state           ods ON odo.state = ods.id
                          LEFT JOIN db.state_text     odst ON odst.state = ods.id AND odst.locale = current_locale()

                         INNER JOIN db.user              w ON o.owner = w.id
                         INNER JOIN db.user              u ON o.oper = u.id

                         INNER JOIN DocumentAreaTree     a ON d.area = a.id

                         INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectPayment TO administrator;
