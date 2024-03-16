--------------------------------------------------------------------------------
-- ClientName ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ClientName (Id, Client,
  Locale, LocaleCode, LocaleName, LocaleDescription,
  FullName, ShortName, LastName, FirstName, MiddleName,
  ValidFromDate, ValidToDate
)
AS
  SELECT n.id, n.client,
         n.locale, l.code, l.name, l.description,
         n.name, n.short, n.last, n.first, n.middle,
         n.validfromdate, n.validToDate
    FROM db.client_name n INNER JOIN db.locale l ON l.id = n.locale;

GRANT SELECT ON ClientName TO administrator;

--------------------------------------------------------------------------------
-- Client ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Client (Id, Document, Code, BirthDay, BirthPlace,
  UserId, UserName, FullName, ShortName, LastName, FirstName, MiddleName,
  Phone, Email, Info, EmailVerified, PhoneVerified, Picture,
  Locale, LocaleCode, LocaleName, LocaleDescription
)
AS
  SELECT c.id, c.document, c.code, c.birthday, c.birthplace,
         c.userid, u.username, n.name, n.short, n.last, n.first, n.middle,
         c.phone, c.email, c.info, p.email_verified, p.phone_verified, p.picture,
         n.locale, l.code, l.name, l.description
    FROM db.client c INNER JOIN db.locale      l ON l.id = current_locale()
                      LEFT JOIN db.client_name n ON c.id = n.client AND l.id = n.locale AND n.validFromDate <= oper_date() AND n.validToDate > oper_date()
                      LEFT JOIN db.user        u ON c.userid = u.id
                      LEFT JOIN db.profile     p ON c.userid = p.userid AND p.scope = current_scope();

GRANT SELECT ON Client TO administrator;

--------------------------------------------------------------------------------
-- AccessClient ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessClient
AS
WITH _access AS (
  WITH _membergroup AS (
    SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
  ) SELECT object
      FROM db.aou AS a INNER JOIN db.entity    e ON a.entity = e.id AND e.code = 'client'
                       INNER JOIN _membergroup m ON a.userid = m.userid
     GROUP BY object
     HAVING (bit_or(a.allow) & ~bit_or(a.deny)) & B'100' = B'100'
) SELECT o.* FROM db.client o INNER JOIN _access ac ON o.id = ac.object;

GRANT SELECT ON AccessClient TO administrator;

--------------------------------------------------------------------------------
-- ObjectClient ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectClient (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Label, Description, BirthDay, BirthPlace,
  UserId, UserName, FullName, ShortName, LastName, FirstName, MiddleName,
  Phone, Email, Info, EmailVerified, PhoneVerified, Picture,
  Locale, LocaleCode, LocaleName, LocaleDescription,
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
         t.code, ot.label, dt.description, t.birthday, t.birthplace,
         t.userid, cu.username, cn.name, cn.short, cn.last, cn.first, cn.middle,
         t.phone, t.email, t.info, p.email_verified, p.phone_verified, p.picture,
         cn.locale, l.code, l.name, l.description,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM AccessClient t INNER JOIN db.locale            l ON l.id = current_locale()
                         LEFT JOIN db.client_name      cn ON cn.client = t.id AND cn.locale = l.id AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()
                         LEFT JOIN db.user             cu ON t.userid = cu.id
                         LEFT JOIN db.profile           p ON cu.id = p.userid AND p.scope = current_scope()

                        INNER JOIN db.document          d ON t.document = d.id
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

                        INNER JOIN db.state_type       st ON o.state_type = st.id
                         LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                        INNER JOIN db.state             s ON o.state = s.id
                         LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                        INNER JOIN db.user              w ON o.owner = w.id
                        INNER JOIN db.user              u ON o.oper = u.id

                        INNER JOIN db.area              a ON d.area = a.id
                        INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectClient TO administrator;
