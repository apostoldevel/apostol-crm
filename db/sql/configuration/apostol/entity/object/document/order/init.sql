--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddOrderMethods -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddOrderMethods (
  pClass        uuid
)
RETURNS         void
AS $$
DECLARE
  uState        uuid;
  uMethod       uuid;

  rec_type      record;
  rec_state     record;
  rec_method    record;
BEGIN

  -- Операции (без учёта состояния)

  PERFORM DefaultMethods(pClass);

  -- Операции (с учётом состояния)

  FOR rec_type IN SELECT * FROM StateType
  LOOP

    CASE rec_type.code
    WHEN 'created' THEN

      uState := SetState(null, pClass, rec_type.id, rec_type.code, 'Created');
      PERFORM EditStateText(uState, 'Создан', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Erstellt', GetLocale('de'));
      PERFORM EditStateText(uState, 'Créé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Creato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Creado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Processing');
        PERFORM EditMethodText(uMethod, 'Обработать', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Verarbeiten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Traiter', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Elaborare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Procesar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('delete'), null, 'Delete');
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

    WHEN 'enabled' THEN

      uState := SetState(null, pClass, rec_type.id, 'processing', 'Processing');
      PERFORM EditStateText(uState, 'Обработка', GetLocale('ru'));
      PERFORM EditStateText(uState, 'In Bearbeitung', GetLocale('de'));
      PERFORM EditStateText(uState, 'En traitement', GetLocale('fr'));
      PERFORM EditStateText(uState, 'In elaborazione', GetLocale('it'));
      PERFORM EditStateText(uState, 'En proceso', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('disable'), null, 'Complete');
        PERFORM EditMethodText(uMethod, 'Завершить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Abschließen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Terminer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Completare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Completar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('cancel'), null, 'Cancel');
        PERFORM EditMethodText(uMethod, 'Отменить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Stornieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Annuler', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Annullare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Cancelar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('delete'), null, 'Delete', null, false);
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

    WHEN 'disabled' THEN

      uState := SetState(null, pClass, rec_type.id, 'succeeded', 'Succeeded');
      PERFORM EditStateText(uState, 'Завершён', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Erfolgreich', GetLocale('de'));
      PERFORM EditStateText(uState, 'Réussi', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Riuscito', GetLocale('it'));
      PERFORM EditStateText(uState, 'Exitoso', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('refund'), null, 'Refund');
        PERFORM EditMethodText(uMethod, 'Вернуть', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Erstatten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Rembourser', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Rimborsare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Reembolsar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('delete'), null, 'Delete', null, false);
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

    WHEN 'deleted' THEN

      uState := SetState(null, pClass, rec_type.id, rec_type.code, 'Deleted');
      PERFORM EditStateText(uState, 'Удалён', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Gelöscht', GetLocale('de'));
      PERFORM EditStateText(uState, 'Supprimé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Eliminato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Eliminado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('restore'), null, 'Restore');
        PERFORM EditMethodText(uMethod, 'Восстановить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Wiederherstellen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Restaurer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Ripristinare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Restaurar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('drop'), null, 'Drop', null, false);
        PERFORM EditMethodText(uMethod, 'Уничтожить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Vernichten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Détruire', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Distruggere', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Destruir', GetLocale('es'));

      uState := SetState(null, pClass, rec_type.id, 'refunded', 'Refunded');
      PERFORM EditStateText(uState, 'Возвращён', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Erstattet', GetLocale('de'));
      PERFORM EditStateText(uState, 'Remboursé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Rimborsato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Reembolsado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('restore'), null, 'Restore', null, false);
        PERFORM EditMethodText(uMethod, 'Восстановить', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('drop'), null, 'Drop', null, false);
        PERFORM EditMethodText(uMethod, 'Уничтожить', GetLocale('ru'));

      uState := SetState(null, pClass, rec_type.id, 'canceled', 'Canceled');
      PERFORM EditStateText(uState, 'Отменён', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Storniert', GetLocale('de'));
      PERFORM EditStateText(uState, 'Annulé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Annullato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Cancelado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('restore'), null, 'Restore', null, false);
        PERFORM EditMethodText(uMethod, 'Восстановить', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('drop'), null, 'Drop', null, false);
        PERFORM EditMethodText(uMethod, 'Уничтожить', GetLocale('ru'));

    END CASE;

  END LOOP;

  PERFORM DefaultTransition(pClass);

  FOR rec_state IN SELECT * FROM State WHERE class = pClass
  LOOP
    CASE rec_state.code
    WHEN 'created' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'enable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'processing'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'processing' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'disable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'succeeded'));
        END IF;

        IF rec_method.actioncode = 'cancel' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'canceled'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'succeeded' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'refund' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'refunded'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'deleted' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'restore' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'created'));
        END IF;
      END LOOP;

    WHEN 'refunded' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'restore' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'created'));
        END IF;
      END LOOP;

    WHEN 'canceled' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'restore' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'created'));
        END IF;
      END LOOP;
    END CASE;
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- AddOrderEvents --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddOrderEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер создан', 'EventOrderCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер открыт', 'EventOrderOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер изменён', 'EventOrderEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер сохранён', 'EventOrderSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер обработан', 'EventOrderEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер завершён', 'EventOrderDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер будет удалён', 'EventOrderDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер восстановлен', 'EventOrderRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер будет уничтожен', 'EventOrderDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'cancel' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер будет отменён', 'EventOrderCancel();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

    IF r.code = 'refund' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер будет возвращён', 'EventOrderRefund();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassOrder ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassOrder (
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
  uClass := AddClass(pParent, pEntity, 'order', 'Order', false);
  PERFORM EditClassText(uClass, 'Ордер', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Bestellung', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Commande', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Ordine', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Pedido', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'memo.order', 'Memo order', 'Memorial order.');
  PERFORM EditTypeText(uType, 'Ордер', 'Мемориальный ордер.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Gedenkauftrag', 'Gedenkauftrag.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Ordre mémoriel', 'Ordre mémoriel.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Ordine memoriale', 'Ordine memoriale.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Orden memorial', 'Orden memorial.', GetLocale('es'));

  -- Событие
  PERFORM AddOrderEvents(uClass);

  -- Метод
  PERFORM AddOrderMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityOrder -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityOrder (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('order', 'Order');
  PERFORM EditEntityText(uEntity, 'Ордер', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Bestellung', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Commande', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Ordine', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Pedido', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassOrder(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('order', AddEndpoint('SELECT * FROM rest.order($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
