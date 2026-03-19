--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddPaymentMethods -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddPaymentMethods (
  pClass	uuid
)
RETURNS void
AS $$
DECLARE
  uState        uuid;
  uMethod       uuid;

  rec_type      record;
  rec_state     record;
  rec_method	record;
BEGIN
  -- Операции (без учёта состояния)

  PERFORM DefaultMethods(pClass);

  -- Операции (с учётом состояния)

  FOR rec_type IN SELECT * FROM StateType
  LOOP

    CASE rec_type.code
    WHEN 'created' THEN

      uState := SetState(null, pClass, rec_type.id, rec_type.code, 'New');
      PERFORM EditStateText(uState, 'Новый', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Neu', GetLocale('de'));
      PERFORM EditStateText(uState, 'Nouveau', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Nuovo', GetLocale('it'));
      PERFORM EditStateText(uState, 'Nuevo', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Send');
        PERFORM EditMethodText(uMethod, 'Отправить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Senden', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Envoyer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Inviare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Enviar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('disable'), null, 'Process');
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

      uState := SetState(null, pClass, rec_type.id, rec_type.code, 'Sent');
      PERFORM EditStateText(uState, 'Отправлен', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Gesendet', GetLocale('de'));
      PERFORM EditStateText(uState, 'Envoyé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Inviato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Enviado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('cancel'), null, 'Cancel');
        PERFORM EditMethodText(uMethod, 'Отменить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Stornieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Annuler', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Annullare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Cancelar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('disable'), null, 'Process');
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

    WHEN 'disabled' THEN

      uState := SetState(null, pClass, rec_type.id, rec_type.code, 'Processed');
      PERFORM EditStateText(uState, 'Обработан', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Verarbeitet', GetLocale('de'));
      PERFORM EditStateText(uState, 'Traité', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Elaborato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Procesado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('cancel'), null, 'Cancel');
        PERFORM EditMethodText(uMethod, 'Отменить', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('return'), null, 'Return');
        PERFORM EditMethodText(uMethod, 'Вернуть', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('delete'), null, 'Delete');
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));

    WHEN 'deleted' THEN

      uState := SetState(null, pClass, rec_type.id, rec_type.code, 'Deleted');
      PERFORM EditStateText(uState, 'Удалён', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Gelöscht', GetLocale('de'));
      PERFORM EditStateText(uState, 'Supprimé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Eliminato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Eliminado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('restore'), null, 'Restore');
        PERFORM EditMethodText(uMethod, 'Восстановить', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('drop'), null, 'Drop');
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
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'enabled'));
        END IF;

        IF rec_method.actioncode = 'disable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'disabled'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'enabled' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'cancel' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'created'));
        END IF;

        IF rec_method.actioncode = 'disable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'disabled'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'disabled' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'cancel' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'created'));
        END IF;

        IF rec_method.actioncode = 'return' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
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
    END CASE;
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- AddPaymentEvents ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddPaymentEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Платёж создан', 'EventPaymentCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Платёж открыт', 'EventPaymentOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Платёж изменён', 'EventPaymentEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Платёж сохранён', 'EventPaymentSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Платёж отправлен', 'EventPaymentEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Платёж принят', 'EventPaymentDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Платёж будет удалён', 'EventPaymentDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Платёж восстановлен', 'EventPaymentRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Платёж будет уничтожен', 'EventPaymentDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'cancel' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Платёж будет отменён', 'EventPaymentCancel();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

    IF r.code = 'return' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Платёж будет возвращён', 'EventPaymentReturn();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassPayment ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassPayment (
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
  uClass := AddClass(pParent, pEntity, 'payment', 'Payment', false);
  PERFORM EditClassText(uClass, 'Платёж', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Zahlung', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Paiement', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Pagamento', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Pago', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'reserve.payment', 'Reserve', 'Order reservation via payment system.');
  PERFORM EditTypeText(uType, 'Резерв', 'Резервирование заказа через платёжную систему.', GetLocale('ru'));

  uType := AddType(uClass, 'invoice.payment', 'Invoice payment', 'Invoice payment via payment system.');
  PERFORM EditTypeText(uType, 'Оплата', 'Оплата счёта через платёжную систему.', GetLocale('ru'));

  uType := AddType(uClass, 'validation.payment', 'Validation', 'Card validation.');
  PERFORM EditTypeText(uType, 'Проверка', 'Проверка карты.', GetLocale('ru'));

  uType := AddType(uClass, 'card.payment', 'Card', 'Card binding.');
  PERFORM EditTypeText(uType, 'Карта', 'Подключение карты.', GetLocale('ru'));

  -- Событие
  PERFORM AddPaymentEvents(uClass);

  -- Метод
  PERFORM AddPaymentMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityPayment ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityPayment (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
  uClass        uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('payment', 'Payment');
  PERFORM EditEntityText(uEntity, 'Платёж', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Zahlung', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Paiement', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Pagamento', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Pago', null, GetLocale('es'));

  -- Класс
  uClass := CreateClassPayment(pParent, uEntity);

  PERFORM CreateClassYooKassa(uClass, uEntity);
  PERFORM CreateClassCloudPayments(uClass, uEntity);

  -- Маршрут
  PERFORM RegisterRoute('payment', AddEndpoint('SELECT * FROM rest.payment($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
