--------------------------------------------------------------------------------
-- Category --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Category (Id, Reference,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, t.reference,
         o.type, y.code, ty.name, ty.description,
         r.code, rt.name, ot.label, rt.description,
         r.scope, sc.code, sc.name, sc.description
    FROM db.category t INNER JOIN db.reference         r ON t.reference = r.id AND r.scope = current_scope()
                        LEFT JOIN db.reference_text   rt ON rt.reference = r.id AND rt.locale = current_locale()
                       INNER JOIN db.object            o ON t.reference = o.id
                        LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()
                       INNER JOIN db.type              y ON o.type = y.id
                        LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()
                       INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON Category TO administrator;

--------------------------------------------------------------------------------
-- AccessCategory --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessCategory
AS
WITH _access AS (
  WITH _membergroup AS (
    SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
  ) SELECT object
      FROM db.aou AS a INNER JOIN db.entity    e ON a.entity = e.id AND e.code = 'category'
                       INNER JOIN _membergroup m ON a.userid = m.userid
     GROUP BY object
     HAVING (bit_or(a.allow) & ~bit_or(a.deny)) & B'100' = B'100'
) SELECT o.* FROM db.category o INNER JOIN _access ac ON o.id = ac.object;

GRANT SELECT ON AccessCategory TO administrator;

--------------------------------------------------------------------------------
-- ObjectCategory --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectCategory (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, r.object, o.parent,
         o.entity, e.code, et.name,
         o.class, c.code, ct.label,
         o.type, y.code, ty.name, ty.description,
         r.code, rt.name, ot.label, rt.description,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         o.scope, sc.code, sc.name, sc.description
    FROM AccessCategory t INNER JOIN db.reference         r ON t.reference = r.id AND r.scope = current_scope()
                           LEFT JOIN db.reference_text   rt ON rt.reference = r.id AND rt.locale = current_locale()
                          INNER JOIN db.object            o ON t.reference = o.id
                           LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()
                          INNER JOIN db.entity            e ON o.entity = e.id
                           LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()
                          INNER JOIN db.class_tree        c ON o.class = c.id
                           LEFT JOIN db.class_text       ct ON ct.class = c.id AND ct.locale = current_locale()
                          INNER JOIN db.type              y ON o.type = y.id
                           LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()
                          INNER JOIN db.state_type       st ON o.state_type = st.id
                           LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()
                          INNER JOIN db.state             s ON o.state = s.id
                           LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()
                          INNER JOIN db.user              w ON o.owner = w.id
                          INNER JOIN db.user              u ON o.oper = u.id
                          INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectCategory TO administrator;
