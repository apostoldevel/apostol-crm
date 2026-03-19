--------------------------------------------------------------------------------
-- Card ------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Card
AS
  SELECT * FROM db.card;

GRANT SELECT ON Card TO administrator;

--------------------------------------------------------------------------------
-- AccessCard ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessCard
AS
WITH _access AS (
   WITH _membergroup AS (
	 SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
   ) SELECT object
       FROM db.aou AS a INNER JOIN db.entity    e ON a.entity = e.id AND e.code = 'card'
                        INNER JOIN _membergroup m ON a.userid = m.userid
      GROUP BY object
      HAVING (bit_or(a.allow) & ~bit_or(a.deny)) & B'100' = B'100'
)
  SELECT t.* FROM db.card t INNER JOIN _access ac ON t.id = ac.object;

GRANT SELECT ON AccessCard TO administrator;

--------------------------------------------------------------------------------
-- ObjectCard ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectCard (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Label, Description,
  Client, ClientCode, FullName, ShortName, LastName, FirstName, MiddleName,
  Name, Expiry, Binding, Sequence,
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
         t.code, ot.label, dt.description,
         t.client, c.code, cn.name, cn.short, cn.last, cn.first, cn.middle,
         t.name, t.expiry, t.binding, t.sequence,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.card    t INNER JOIN db.document          d ON t.document = d.id
                       LEFT JOIN db.document_text    dt ON dt.document = d.id AND dt.locale = current_locale()

                      INNER JOIN db.object            o ON t.document = o.id
                       LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()

                      INNER JOIN db.entity            e ON o.entity = e.id
                       LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()

                      INNER JOIN db.class_tree       ct ON o.class = ct.id
                       LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                      INNER JOIN db.type              y ON o.type = y.id
                       LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                       LEFT JOIN db.client            c ON t.client = c.id
                       LEFT JOIN db.client_name      cn ON cn.client = c.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()

                      INNER JOIN db.state_type       st ON o.state_type = st.id
                       LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                      INNER JOIN db.state             s ON o.state = s.id
                       LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                      INNER JOIN db.user              w ON o.owner = w.id
                      INNER JOIN db.user              u ON o.oper = u.id

                      INNER JOIN DocumentAreaTree     a ON d.area = a.id

                      INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectCard TO administrator;
