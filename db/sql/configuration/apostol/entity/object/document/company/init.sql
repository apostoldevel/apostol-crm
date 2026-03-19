--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddCompanyEvents ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddCompanyEvents (
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
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Компания добавлена', 'EventCompanyCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Компания открыта', 'EventCompanyOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Компания изменена', 'EventCompanyEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Компания сохранена', 'EventCompanySave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Компания активна', 'EventCompanyEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Компания неактивна', 'EventCompanyDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Компания будет удалена', 'EventCompanyDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Компания восстановлена', 'EventCompanyRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Компания будет уничтожена', 'EventCompanyDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassCompany ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassCompany (
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
  uClass := AddClass(pParent, pEntity, 'company', 'Company', false);
  PERFORM EditClassText(uClass, 'Компания', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Unternehmen', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Entreprise', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Azienda', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Empresa', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'all.company', 'All', 'All companies.');
  PERFORM EditTypeText(uType, 'Все', 'Все компании.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Alle', 'Alle Unternehmen.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Toutes', 'Toutes les entreprises.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Tutte', 'Tutte le aziende.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Todas', 'Todas las empresas.', GetLocale('es'));

  uType := AddType(uClass, 'main.company', 'Head office', 'Head office.');
  PERFORM EditTypeText(uType, 'Головной офис', 'Головной офис.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Hauptsitz', 'Hauptsitz.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Siège social', 'Siège social.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Sede centrale', 'Sede centrale.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Oficina central', 'Oficina central.', GetLocale('es'));

  uType := AddType(uClass, 'subsidiary.company', 'Subsidiary', 'Subsidiary.');
  PERFORM EditTypeText(uType, 'Дочернее предприятие', 'Дочернее предприятие.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Tochtergesellschaft', 'Tochtergesellschaft.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Filiale', 'Filiale.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Filiale', 'Filiale.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Filial', 'Filial.', GetLocale('es'));

  uType := AddType(uClass, 'mobile.company', 'Mobile division', 'Mobile division.');
  PERFORM EditTypeText(uType, 'Мобильное подразделение', 'Мобильное подразделение.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Mobile Abteilung', 'Mobile Abteilung.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Division mobile', 'Division mobile.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Divisione mobile', 'Divisione mobile.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'División móvil', 'División móvil.', GetLocale('es'));

  -- Событие
  PERFORM AddCompanyEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass, ARRAY['Created', 'Active', 'Closed', 'Deleted', 'Activate', 'Close', 'Delete'], ARRAY['Создана', 'Действует', 'Закрыта', 'Архив', 'Открыть', 'Закрыть', 'В архив']);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityCompany ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityCompany (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('company', 'Company');
  PERFORM EditEntityText(uEntity, 'Компания', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Unternehmen', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Entreprise', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Azienda', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Empresa', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassCompany(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('company', AddEndpoint('SELECT * FROM rest.company($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
