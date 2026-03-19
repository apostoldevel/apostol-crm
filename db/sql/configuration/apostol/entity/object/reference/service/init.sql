--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddServiceEvents ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddServiceEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Service created', 'EventServiceCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Service opened', 'EventServiceOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Service edited', 'EventServiceEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Service saved', 'EventServiceSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Service enabled', 'EventServiceEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Service disabled', 'EventServiceDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Service will be deleted', 'EventServiceDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Service restored', 'EventServiceRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Service will be destroyed', 'EventServiceDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassService ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassService (
  pParent       uuid,
  pEntity       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uClass        uuid;
  uType         uuid;
BEGIN
  -- Класс
  uClass := AddClass(pParent, pEntity, 'service', 'Service', false);
  PERFORM EditClassText(uClass, 'Услуга', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Dienstleistung', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Service', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Servizio', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Servicio', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'rent.service', 'Rent', 'Equipment rental.');
  PERFORM EditTypeText(uType, 'Аренда', 'Аренда оборудования.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Miete', 'Gerätevermietung.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Location', 'Location d''équipement.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Noleggio', 'Noleggio di attrezzature.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Alquiler', 'Alquiler de equipos.', GetLocale('es'));

  -- Событие
  PERFORM AddServiceEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass, ARRAY['Created', 'Active', 'Closed', 'Deleted', 'Activate', 'Close', 'Delete'], ARRAY['Создана', 'Активна', 'Закрыта', 'Удалена', 'Открыть', 'Закрыть', 'Удалить']);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityService ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityService (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('service', 'Service');
  PERFORM EditEntityText(uEntity, 'Услуга', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Dienstleistung', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Service', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Servizio', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Servicio', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassService(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('service', AddEndpoint('SELECT * FROM rest.service($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
