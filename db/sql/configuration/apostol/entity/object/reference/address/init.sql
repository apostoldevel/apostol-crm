--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddAddressEvents ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddAddressEvents (
  pClass        uuid
)
RETURNS         void
AS $$
DECLARE
  r             record;

  uParent       uuid;
  uEvent        uuid;
BEGIN
  uParent := GetEventType('parent');
  uEvent := GetEventType('event');

  FOR r IN SELECT * FROM Action
  LOOP

    IF r.code = 'create' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Address created', 'EventAddressCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Address opened', 'EventAddressOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Address edited', 'EventAddressEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Address saved', 'EventAddressSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Change state for all children', 'ExecuteMethodForAllChild();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Address enabled', 'EventAddressEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Change state for all children', 'ExecuteMethodForAllChild();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Address disabled', 'EventAddressDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Address will be deleted', 'EventAddressDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Address restored', 'EventAddressRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Address will be destroyed', 'EventAddressDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassAddress ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassAddress (
  pParent       uuid,
  pEntity       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uType         uuid;
  uClass        uuid;
BEGIN
  -- Класс
  uClass := AddClass(pParent, pEntity, 'address', 'Address', false);
  PERFORM EditClassText(uClass, 'Адрес', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Adresse', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Adresse', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Indirizzo', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Dirección', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'post.address', 'Postal', 'Postal address.');
  PERFORM EditTypeText(uType, 'Почтовый', 'Почтовый адрес.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Postanschrift', 'Postadresse.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Postal', 'Adresse postale.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Postale', 'Indirizzo postale.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Postal', 'Dirección postal.', GetLocale('es'));

  uType := AddType(uClass, 'actual.address', 'Actual', 'Actual address.');
  PERFORM EditTypeText(uType, 'Фактический', 'Фактический адрес.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Tatsächlich', 'Tatsächliche Adresse.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Réel', 'Adresse réelle.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Effettivo', 'Indirizzo effettivo.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Real', 'Dirección real.', GetLocale('es'));

  uType := AddType(uClass, 'legal.address', 'Legal', 'Legal address.');
  PERFORM EditTypeText(uType, 'Юридический', 'Юридический адрес.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Rechtlich', 'Juristische Adresse.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Juridique', 'Adresse juridique.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Legale', 'Indirizzo legale.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Legal', 'Dirección legal.', GetLocale('es'));

  -- Событие
  PERFORM AddAddressEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityAddress ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityAddress (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('address', 'Address');
  PERFORM EditEntityText(uEntity, 'Адрес', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Adresse', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Adresse', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Indirizzo', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Dirección', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassAddress(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('address', AddEndpoint('SELECT * FROM rest.address($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
