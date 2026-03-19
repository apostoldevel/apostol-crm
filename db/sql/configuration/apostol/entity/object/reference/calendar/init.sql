--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddCalendarEvents -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddCalendarEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Calendar created', 'EventCalendarCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Calendar opened', 'EventCalendarOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Calendar edited', 'EventCalendarEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Calendar saved', 'EventCalendarSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Calendar enabled', 'EventCalendarEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Calendar disabled', 'EventCalendarDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Calendar will be deleted', 'EventCalendarDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Calendar restored', 'EventCalendarRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Calendar will be destroyed', 'EventCalendarDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassCalendar ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassCalendar (
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
  uClass := AddClass(pParent, pEntity, 'calendar', 'Calendar', false);
  PERFORM EditClassText(uClass, 'Календарь', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Kalender', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Calendrier', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Calendario', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Calendario', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'workday.calendar', 'Workday', 'Workday calendar.');
  PERFORM EditTypeText(uType, 'Рабочий', 'Календарь рабочих дней.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Arbeitstag', 'Arbeitstagskalender.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Ouvrable', 'Calendrier des jours ouvrables.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Lavorativo', 'Calendario dei giorni lavorativi.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Laboral', 'Calendario de días laborables.', GetLocale('es'));

  -- Событие
  PERFORM AddCalendarEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityCalendar --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityCalendar (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('calendar', 'Calendar');
  PERFORM EditEntityText(uEntity, 'Календарь', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Kalender', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Calendrier', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Calendario', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Calendario', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassCalendar(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('calendar', AddEndpoint('SELECT * FROM rest.calendar($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
