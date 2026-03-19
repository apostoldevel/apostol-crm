--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddCardEvents ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddCardEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Карта создана', 'EventCardCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Карта открыта', 'EventCardOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Карта изменёна', 'EventCardEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Карта сохранёна', 'EventCardSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Карта активирована', 'EventCardEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Карта заблокирована', 'EventCardDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Карта будет удалёна', 'EventCardDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Карта восстановлена', 'EventCardRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Карта будет уничтожена', 'EventCardDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassCard -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassCard (
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
  uClass := AddClass(pParent, pEntity, 'card', 'Card', false);
  PERFORM EditClassText(uClass, 'Карта', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Karte', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Carte', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Carta', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Tarjeta', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'rfid.card', 'RFID card', 'Plastic card with radio-frequency identification.');
  PERFORM EditTypeText(uType, 'RFID карта', 'Пластиковая карта c радиочастотной идентификацией.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'RFID-Karte', 'Plastikkarte mit Funkfrequenzidentifikation.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Carte RFID', 'Carte plastique avec identification par radiofréquence.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Carta RFID', 'Carta di plastica con identificazione a radiofrequenza.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Tarjeta RFID', 'Tarjeta de plástico con identificación por radiofrecuencia.', GetLocale('es'));

  uType := AddType(uClass, 'credit.card', 'Credit card', 'Card issued by a credit organization.');
  PERFORM EditTypeText(uType, 'Кредитная карта', 'Карта, выпущенная кредитной организацией.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Kreditkarte', 'Von einer Kreditorganisation ausgestellte Karte.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Carte de crédit', 'Carte émise par un organisme de crédit.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Carta di credito', 'Carta emessa da un istituto di credito.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Tarjeta de crédito', 'Tarjeta emitida por una organización de crédito.', GetLocale('es'));

  uType := AddType(uClass, 'plastic.card', 'Plastic card', 'Plastic card.');
  PERFORM EditTypeText(uType, 'Пластиковая карта', 'Пластиковая карта.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Plastikkarte', 'Plastikkarte.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Carte plastique', 'Carte plastique.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Carta di plastica', 'Carta di plastica.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Tarjeta de plástico', 'Tarjeta de plástico.', GetLocale('es'));

  -- Событие
  PERFORM AddCardEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass, ARRAY['Created', 'Active', 'Blocked', 'Deleted', 'Activate', 'Block', 'Delete'], ARRAY['Создана', 'Активна', 'Заблокирована', 'Удалена', 'Активировать', 'Заблокировать', 'Удалить']);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityCard ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityCard (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  nEntity       uuid;
BEGIN
  -- Сущность
  nEntity := AddEntity('card', 'Card');
  PERFORM EditEntityText(nEntity, 'Карта', null, GetLocale('ru'));
  PERFORM EditEntityText(nEntity, 'Karte', null, GetLocale('de'));
  PERFORM EditEntityText(nEntity, 'Carte', null, GetLocale('fr'));
  PERFORM EditEntityText(nEntity, 'Carta', null, GetLocale('it'));
  PERFORM EditEntityText(nEntity, 'Tarjeta', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassCard(pParent, nEntity);

  -- API
  PERFORM RegisterRoute('card', AddEndpoint('SELECT * FROM rest.card($1, $2);'));

  RETURN nEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
