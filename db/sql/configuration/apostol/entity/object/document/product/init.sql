--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddProductEvents ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddProductEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Продукт создан', 'EventProductCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Продукт открыт', 'EventProductOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Продукт изменён', 'EventProductEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Продукт сохранён', 'EventProductSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Продукт доступен', 'EventProductEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Продукт недоступен', 'EventProductDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Продукт будет удалён', 'EventProductDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Продукт восстановлен', 'EventProductRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Продукт будет уничтожен', 'EventProductDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassProduct ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassProduct (
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
  uClass := AddClass(pParent, pEntity, 'product', 'Product', false);
  PERFORM EditClassText(uClass, 'Продукт', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Produkt', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Produit', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Prodotto', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Producto', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'unknown.product', 'Unknown', 'Unknown.');
  PERFORM EditTypeText(uType, 'Неизвестно', 'Неизвестно.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Unbekannt', 'Unbekannt.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Inconnu', 'Inconnu.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Sconosciuto', 'Sconosciuto.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Desconocido', 'Desconocido.', GetLocale('es'));

  uType := AddType(uClass, 'service.product', 'Service', 'Service.');
  PERFORM EditTypeText(uType, 'Услуга', 'Услуга.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Dienstleistung', 'Dienstleistung.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Service', 'Service.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Servizio', 'Servizio.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Servicio', 'Servicio.', GetLocale('es'));

  -- Событие
  PERFORM AddProductEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass, ARRAY['Created', 'Active', 'Closed', 'Deleted', 'Activate', 'Close', 'Delete'], ARRAY['Создан', 'Активен', 'Закрыт', 'Удалён', 'Открыть', 'Закрыть', 'Удалить']);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityProduct ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityProduct (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('product', 'Product');
  PERFORM EditEntityText(uEntity, 'Продукт', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Produkt', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Produit', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Prodotto', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Producto', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassProduct(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('product', AddEndpoint('SELECT * FROM rest.product($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
