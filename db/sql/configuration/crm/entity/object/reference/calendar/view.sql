--------------------------------------------------------------------------------
-- Calendar --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Calendar (Id, Reference,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  Week, DayOff, Holiday, WorkStart, WorkCount, RestStart, RestCount, Schedule,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, t.reference,
         o.type, y.code, ty.name, ty.description,
         r.code, rt.name, ot.label, rt.description,
         t.week, t.dayoff, t.holiday, t.work_start, t.work_count, t.rest_start, t.rest_count, t.schedule,
         r.scope, sc.code, sc.name, sc.description
    FROM db.calendar t INNER JOIN db.reference         r ON t.reference = r.id AND r.scope = current_scope()
                        LEFT JOIN db.reference_text   rt ON rt.reference = r.id AND rt.locale = current_locale()
                       INNER JOIN db.object            o ON t.reference = o.id
                        LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()
                       INNER JOIN db.type              y ON o.type = y.id
                        LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()
                       INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON Calendar TO administrator;

--------------------------------------------------------------------------------
-- AccessCalendar --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessCalendar
AS
WITH _access AS (
  WITH _membergroup AS (
    SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
  ) SELECT object
      FROM db.aou AS a INNER JOIN db.entity    e ON a.entity = e.id AND e.code = 'calendar'
                       INNER JOIN _membergroup m ON a.userid = m.userid
     GROUP BY object
     HAVING (bit_or(a.allow) & ~bit_or(a.deny)) & B'100' = B'100'
) SELECT o.* FROM db.calendar o INNER JOIN _access ac ON o.id = ac.object;

GRANT SELECT ON AccessCalendar TO administrator;

--------------------------------------------------------------------------------
-- ObjectCalendar --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectCalendar (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  Week, DayOff, Holiday, WorkStart, WorkCount, RestStart, RestCount, Schedule,
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
         t.week, t.dayoff, t.holiday, t.work_start, t.work_count, t.rest_start, t.rest_count, t.schedule,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         o.scope, sc.code, sc.name, sc.description
    FROM AccessCalendar t INNER JOIN db.reference         r ON t.reference = r.id AND r.scope = current_scope()
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

GRANT SELECT ON ObjectCalendar TO administrator;

--------------------------------------------------------------------------------
-- calendar_date ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW calendar_date (Id, Calendar, UserId, Date,
  Label, WorkStart, WorkStop, WorkCount, RestStart, RestCount, Schedule, Flag
)
AS
  SELECT id, calendar, userid, date,
         CASE
         WHEN flag & B'1000' = B'1000' THEN 'Сокращённый'
         WHEN flag & B'0100' = B'0100' THEN 'Праздничный'
         WHEN flag & B'0010' = B'0010' THEN 'Выходной'
         WHEN flag & B'0001' = B'0001' THEN 'Не рабочий'
         ELSE 'Рабочий'
         END,
         CASE
         WHEN flag & B'0001' = B'0001' THEN null
         ELSE
           work_start
         END,
         CASE
         WHEN flag & B'0001' = B'0001' THEN null
         WHEN flag & B'1000' = B'1000' THEN work_start + (work_count - interval '1 hour') + rest_count
         ELSE
           work_start + work_count + rest_count
         END,
         CASE
         WHEN flag & B'0001' = B'0001' THEN null
         WHEN flag & B'1000' = B'1000' THEN work_count - interval '1 hour'
         ELSE
           work_count
         END,
         CASE
         WHEN flag & B'0001' = B'0001' THEN null
         ELSE
           rest_start
         END,
         CASE
         WHEN flag & B'0001' = B'0001' THEN null
         ELSE
           rest_count
         END,
         schedule,
         flag
    FROM db.cdate;

--------------------------------------------------------------------------------
-- CalendarDate ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW CalendarDate
AS
  SELECT d.id, d.calendar, c.code AS calendarcode, c.name AS calendarname, c.description AS calendardesc,
         d.userid, u.username, u.name AS userfullname,
         d.date, d.label, d.workstart, d.workstop, d.workcount, d.reststart, d.restcount, d.schedule, d.flag
    FROM calendar_date d INNER JOIN Calendar c ON d.calendar = c.id
                          LEFT JOIN db.user u ON d.userid = u.id AND u.type = 'U';

GRANT SELECT ON CalendarDate TO administrator;
