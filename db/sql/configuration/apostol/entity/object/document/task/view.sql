--------------------------------------------------------------------------------
-- Task ------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Task (Id, Document,
  Calendar, CalendarCode, CalendarName,
  Executor, ExecutorCode, ExecutorName,
  Read, Period, ValidFromDate, ValidToDate
)
AS
  SELECT t.id, t.document,
         t.calendar, rc.code, rc.name,
         t.executor, c.code, c.fullname,
         t.read, t.period, t.validFromDate, t.validToDate
    FROM db.task t INNER JOIN Calendar      rc ON t.calendar = rc.id
                   INNER JOIN Client         c ON t.executor = c.id;

GRANT SELECT ON Task TO administrator;

--------------------------------------------------------------------------------
-- AccessTask ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessTask
AS
WITH _membergroup AS (
  SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
) SELECT object
    FROM db.task t INNER JOIN db.aou         a ON a.object = t.id
                   INNER JOIN _membergroup   m ON a.userid = m.userid
   WHERE a.mask = B'100'
   GROUP BY object;

GRANT SELECT ON AccessTask TO administrator;

--------------------------------------------------------------------------------
-- ObjectTask ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectTask (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Calendar, CalendarCode, CalendarName,
  Executor, ExecutorCode, ExecutorName,
  Read, Period, ValidFromDate, ValidToDate,
  Label, Description,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Priority, PriorityCode, PriorityName, PriorityDescription,
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
         t.calendar, cr.code, crt.name,
         t.executor, c.code, cn.name,
         t.read, t.period, t.validFromDate, t.validToDate,
         ot.label, dt.description,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         d.priority, p.code, pt.name, pt.description,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.task t INNER JOIN db.document          d ON t.document = d.id
                    LEFT JOIN db.document_text    dt ON dt.document = d.id AND dt.locale = current_locale()

                   INNER JOIN db.priority          p ON d.priority = p.id
                    LEFT JOIN db.priority_text    pt ON pt.priority = p.id AND pt.locale = current_locale()

                   INNER JOIN db.object            o ON t.document = o.id
                    LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()

                   INNER JOIN db.entity            e ON o.entity = e.id
                    LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()

                   INNER JOIN db.class_tree       ct ON o.class = ct.id
                    LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                   INNER JOIN db.type              y ON o.type = y.id
                    LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                   INNER JOIN db.reference        cr ON t.calendar = cr.id
                    LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()

                   INNER JOIN db.client            c ON t.executor = c.id
                    LEFT JOIN db.client_name      cn ON cn.client = c.id AND cn.locale = current_locale() AND cn.validfromdate <= Now() AND cn.validtodate > Now()

                   INNER JOIN db.state_type       st ON o.state_type = st.id
                    LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                   INNER JOIN db.state             s ON o.state = s.id
                    LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                   INNER JOIN db.user              w ON o.owner = w.id
                   INNER JOIN db.user              u ON o.oper = u.id

                   INNER JOIN DocumentAreaTree     a ON d.area = a.id
                   INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectTask TO administrator;
