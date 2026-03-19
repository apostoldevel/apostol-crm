--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddModelEvents --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddModelEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Model created', 'EventModelCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Model opened', 'EventModelOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Model edited', 'EventModelEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Model saved', 'EventModelSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Model enabled', 'EventModelEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Model disabled', 'EventModelDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Model will be deleted', 'EventModelDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Model restored', 'EventModelRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Model will be destroyed', 'EventModelDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassModel ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassModel (
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
  uClass := AddClass(pParent, pEntity, 'model', 'Model', false);
  PERFORM EditClassText(uClass, 'Модель', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Modell', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Modèle', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Modello', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Modelo', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'device.model', 'Device', 'Device model.');
  PERFORM EditTypeText(uType, 'Устройство', 'Модель устройства.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Gerät', 'Gerätemodell.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Appareil', 'Modèle d''appareil.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Dispositivo', 'Modello del dispositivo.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Dispositivo', 'Modelo del dispositivo.', GetLocale('es'));

  -- Событие
  PERFORM AddModelEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass, ARRAY['Created', 'Opened', 'Closed', 'Deleted', 'Open', 'Close', 'Delete'], ARRAY['Создана', 'Открыта', 'Закрыта', 'Удалена', 'Открыть', 'Закрыть', 'Удалить']);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityModel -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityModel (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('model', 'Model');
  PERFORM EditEntityText(uEntity, 'Модель', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Modell', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Modèle', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Modello', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Modelo', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassModel(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('model', AddEndpoint('SELECT * FROM rest.model($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
