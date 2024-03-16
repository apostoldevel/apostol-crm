--------------------------------------------------------------------------------
-- Country ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Country (Id, Reference,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  Alpha2, Alpha3, Digital, Flag,
  Scope, ScopeCode, ScopeName, ScopeDescription
) AS
  SELECT t.id, t.reference,
         o.type, y.code, ty.name, ty.description,
         r.code, rt.name, ot.label, rt.description,
         t.alpha2, t.alpha3, t.digital, t.flag,
         r.scope, sc.code, sc.name, sc.description
    FROM db.country t INNER JOIN db.reference         r ON t.reference = r.id AND r.scope = current_scope()
                       LEFT JOIN db.reference_text   rt ON rt.reference = r.id AND rt.locale = current_locale()
                      INNER JOIN db.object            o ON t.reference = o.id
                       LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()
                      INNER JOIN db.type              y ON o.type = y.id
                       LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()
                      INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON Country TO administrator;

--------------------------------------------------------------------------------
-- AccessCountry ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessCountry
AS
WITH _access AS (
  WITH _membergroup AS (
    SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
  ) SELECT object
      FROM db.aou AS a INNER JOIN db.entity    e ON a.entity = e.id AND e.code = 'country'
                       INNER JOIN _membergroup m ON a.userid = m.userid
     GROUP BY object
     HAVING (bit_or(a.allow) & ~bit_or(a.deny)) & B'100' = B'100'
) SELECT o.* FROM db.country o INNER JOIN _access ac ON o.id = ac.object;

GRANT SELECT ON AccessCountry TO administrator;

--------------------------------------------------------------------------------
-- ObjectCountry ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectCountry (Id, Object, Parent,
  Event, EventCode, EventName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  Alpha2, Alpha3, Digital, Flag,
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
         t.alpha2, t.alpha3, t.digital, t.flag,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         o.scope, sc.code, sc.name, sc.description
    FROM AccessCountry t INNER JOIN db.reference         r ON t.reference = r.id AND r.scope = current_scope()
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

GRANT SELECT ON ObjectCountry TO administrator;
