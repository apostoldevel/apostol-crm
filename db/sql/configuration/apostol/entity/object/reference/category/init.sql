--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddCategoryEvents -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddCategoryEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Category created', 'EventCategoryCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Category opened', 'EventCategoryOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Category edited', 'EventCategoryEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Category saved', 'EventCategorySave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Category enabled', 'EventCategoryEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Category disabled', 'EventCategoryDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Category will be deleted', 'EventCategoryDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Category restored', 'EventCategoryRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Category will be destroyed', 'EventCategoryDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassCategory ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassCategory (
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
  uClass := AddClass(pParent, pEntity, 'category', 'Category', false);
  PERFORM EditClassText(uClass, 'Категория', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Kategorie', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Catégorie', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Categoria', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Categoría', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'service.category', 'Service', 'Service provision category.');
  PERFORM EditTypeText(uType, 'Услуга', 'Категория предоставления услуг.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Dienstleistung', 'Kategorie der Dienstleistungen.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Service', 'Catégorie de prestation de services.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Servizio', 'Categoria di prestazione dei servizi.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Servicio', 'Categoría de prestación de servicios.', GetLocale('es'));

  uType := AddType(uClass, 'account.category', 'Account', 'Account category.');
  PERFORM EditTypeText(uType, 'Лицевой счёт', 'Категория лицевых счетов.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Konto', 'Kontokategorie.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Compte', 'Catégorie de comptes.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Conto', 'Categoria dei conti.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Cuenta', 'Categoría de cuentas.', GetLocale('es'));

  -- Событие
  PERFORM AddCategoryEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass, ARRAY['Created', 'Opened', 'Closed', 'Deleted', 'Open', 'Close', 'Delete'], ARRAY['Создана', 'Открыта', 'Закрыта', 'Удалена', 'Открыть', 'Закрыть', 'Удалить']);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityCategory --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityCategory (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('category', 'Category');
  PERFORM EditEntityText(uEntity, 'Категория', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Kategorie', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Catégorie', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Categoria', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Categoría', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassCategory(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('category', AddEndpoint('SELECT * FROM rest.category($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
