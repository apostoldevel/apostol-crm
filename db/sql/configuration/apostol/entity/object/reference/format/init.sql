--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddFormatEvents -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddFormatEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Format created', 'EventFormatCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Format opened', 'EventFormatOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Format edited', 'EventFormatEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Format saved', 'EventFormatSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Format enabled', 'EventFormatEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Format disabled', 'EventFormatDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Format will be deleted', 'EventFormatDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Format restored', 'EventFormatRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Format will be destroyed', 'EventFormatDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassFormat -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassFormat (
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
  uClass := AddClass(pParent, pEntity, 'format', 'Format', false);
  PERFORM EditClassText(uClass, 'Формат', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Format', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Format', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Formato', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Formato', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'data.format', 'Data', 'Data format.');
  PERFORM EditTypeText(uType, 'Данные', 'Формат данных.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Daten', 'Datenformat.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Données', 'Format de données.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Dati', 'Formato dei dati.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Datos', 'Formato de datos.', GetLocale('es'));

  -- Событие
  PERFORM AddFormatEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityFormat ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityFormat (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('format', 'Format');
  PERFORM EditEntityText(uEntity, 'Формат', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Format', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Format', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Formato', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Formato', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassFormat(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('format', AddEndpoint('SELECT * FROM rest.format($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
