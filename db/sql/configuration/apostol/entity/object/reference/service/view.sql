--------------------------------------------------------------------------------
-- Service ---------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Service reference view with type, scope, state, and localized text.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW Service
AS
  SELECT t.id, o.parent, t.reference,
         o.class, ct.code AS ClassCode, ctt.label AS ClassLabel,
         o.type, y.code AS TypeCode, ty.name AS TypeName, ty.description AS TypeDescription,
         o.state_type AS StateType, st.code AS StateTypeCode, stt.name AS StateTypeName,
         o.state, s.code AS StateCode, sst.label AS StateLabel,
         t.category, rc.code AS CategoryCode, rct.name AS CategoryName, rct.description AS CategoryDescription,
         t.measure, rm.code AS MeasureCode, rmt.name AS MeasureName, rmt.description AS MeasureDescription,
         o.pdate AS Created, o.udate AS LastUpdate, o.ldate AS OperDate,
         r.code, rt.name, ot.label, rt.description,
         r.scope, sc.code AS ScopeCode, sc.name AS ScopeName, sc.description AS ScopeDescription
    FROM db.service t INNER JOIN db.reference         r ON t.reference = r.id AND r.scope = current_scope()
                       LEFT JOIN db.reference_text   rt ON rt.reference = r.id AND rt.locale = current_locale()

                      INNER JOIN db.object            o ON o.id = r.object
                       LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()

                      INNER JOIN db.class_tree       ct ON o.class = ct.id
                       LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                      INNER JOIN db.type              y ON y.id = o.type
                       LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                      INNER JOIN db.state_type       st ON o.state_type = st.id
                       LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                      INNER JOIN db.state             s ON o.state = s.id
                       LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                      INNER JOIN db.reference        rc ON t.category = rc.id
                       LEFT JOIN db.reference_text  rct ON rct.reference = rc.id AND rct.locale = current_locale()

                      INNER JOIN db.reference        rm ON t.measure = rm.id
                       LEFT JOIN db.reference_text  rmt ON rmt.reference = rm.id AND rmt.locale = current_locale()

                      INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON Service TO administrator;

--------------------------------------------------------------------------------
-- AccessService ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Access control view for service (RLS). Returns object IDs accessible to the current user.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW AccessService
AS
WITH _membergroup AS (
  SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
) SELECT object
	FROM db.service t INNER JOIN db.aou         a ON a.object = t.id
                      INNER JOIN _membergroup   m ON a.userid = m.userid
   WHERE a.mask = B'100'
   GROUP BY object;

GRANT SELECT ON AccessService TO administrator;

--------------------------------------------------------------------------------
-- ObjectService ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Full service object view with entity, class, type, state, owner, and scope details.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW ObjectService (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel,
  Category, CategoryCode, CategoryName, CategoryDescription,
  Measure, MeasureCode, MeasureName, MeasureDescription,
  Code, Name, Label, Description, Value,
  Created, LastUpdate, OperDate,
  Owner, OwnerCode, OwnerName,
  Oper, OperCode, OperName,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, r.object, o.parent,
         o.entity, e.code, et.name,
         o.class, c.code, ct.label,
         o.type, y.code, ty.name, ty.description,
         t.category, rc.code, rct.name, rct.description,
         t.measure, rm.code, rmt.name, rmt.description,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label,
         r.code, rt.name, ot.label, rt.description, t.value,
         o.pdate, o.udate, o.ldate,
         o.owner, w.username, w.name,
         o.oper, u.username, u.name,
         o.scope, sc.code, sc.name, sc.description
    FROM db.service    t INNER JOIN db.reference         r ON t.reference = r.id AND r.scope = current_scope()
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

                         INNER JOIN db.reference        rc ON t.category = rc.id
                          LEFT JOIN db.reference_text  rct ON rct.reference = rc.id AND rct.locale = current_locale()

                         INNER JOIN db.reference        rm ON t.measure = rm.id
                          LEFT JOIN db.reference_text  rmt ON rmt.reference = rm.id AND rmt.locale = current_locale()

                         INNER JOIN db.user              w ON o.owner = w.id
                         INNER JOIN db.user              u ON o.oper = u.id

                         INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectService TO administrator;
