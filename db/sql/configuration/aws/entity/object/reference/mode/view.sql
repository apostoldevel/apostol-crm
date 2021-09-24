--------------------------------------------------------------------------------
-- Mode ------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Mode (Id, Reference, Code, Name, Description)
AS
  SELECT c.id, c.reference, r.code, r.name, r.description
    FROM db.mode c INNER JOIN Reference r ON r.id = c.reference;

GRANT SELECT ON Mode TO administrator;

--------------------------------------------------------------------------------
-- AccessMode ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessMode
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('mode'), current_userid())
  )
  SELECT m.* FROM Mode m INNER JOIN access ac ON m.id = ac.object;

GRANT SELECT ON AccessMode TO administrator;

--------------------------------------------------------------------------------
-- ObjectMode ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectMode (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate
)
AS
  SELECT m.id, r.object, o.parent,
         o.entity, o.entitycode, o.entityname,
         o.class, o.classcode, o.classlabel,
         o.type, o.typecode, o.typename, o.typedescription,
         r.code, r.name, o.label, r.description,
         o.statetype, o.statetypecode, o.statetypename,
         o.state, o.statecode, o.statelabel, o.lastupdate,
         o.owner, o.ownercode, o.ownername, o.created,
         o.oper, o.opercode, o.opername, o.operdate
    FROM AccessMode m INNER JOIN Reference r ON m.reference = r.id
                      INNER JOIN Object    o ON m.reference = o.id;

GRANT SELECT ON ObjectMode TO administrator;
