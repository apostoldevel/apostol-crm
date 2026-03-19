--------------------------------------------------------------------------------
-- Company ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Company
AS
  SELECT t.id, t.document, t.root, t.node,
         o.type, y.code AS TypeCode, ty.name AS TypeName, ty.description AS TypeDescription,
         t.code, ot.label AS Name, ot.label, dt.description, t.level, t.sequence,
         o.scope, sc.code AS ScopeCode, sc.name AS ScopeName, sc.description AS ScopeDescription
    FROM db.company t INNER JOIN db.object            o ON o.id = t.document
                       LEFT JOIN db.object_text      ot ON ot.object = t.document AND ot.locale = current_locale()
                       LEFT JOIN db.document_text    dt ON dt.document = t.document AND dt.locale = current_locale()

                      INNER JOIN db.type              y ON y.id = o.type
                       LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                      INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON Company TO administrator;

--------------------------------------------------------------------------------
-- AccessCompany ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessCompany
AS
WITH _membergroup AS (
  SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
) SELECT object
    FROM db.company t INNER JOIN db.aou         a ON a.object = t.id
                      INNER JOIN _membergroup   m ON a.userid = m.userid
   WHERE a.mask = B'100'
   GROUP BY object;

GRANT SELECT ON AccessCompany TO administrator;

--------------------------------------------------------------------------------
-- ObjectCompany----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectCompany (Id, Object, Parent, Root, Node,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description, Level, Sequence,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Area, AreaCode, AreaName, AreaDescription,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, d.object, o.parent, t.root, t.node,
         o.entity, e.code, et.name,
         o.class, ct.code, ctt.label,
         o.type, y.code, ty.name, ty.description,
         t.code, ot.label, ot.label, dt.description, t.level, t.sequence,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.company t INNER JOIN db.document          d ON t.document = d.id
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

                      INNER JOIN db.user              w ON o.owner = w.id
                      INNER JOIN db.user              u ON o.oper = u.id

                      INNER JOIN DocumentAreaTree     a ON d.area = a.id
                      INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectCompany TO administrator;
