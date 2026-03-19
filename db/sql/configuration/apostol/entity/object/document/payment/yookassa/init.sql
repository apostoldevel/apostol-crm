--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddYooKassaMethods ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddYooKassaMethods (
  pClass	uuid
)
RETURNS void
AS $$
DECLARE
  uState        uuid;

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

      uState := SetState(null, pClass, rec_type.id, rec_type.code, 'Created');
      PERFORM EditStateText(uState, 'Создан', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Erstellt', GetLocale('de'));
      PERFORM EditStateText(uState, 'Créé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Creato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Creado', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('pay'), null, 'Оплатить');
        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

    WHEN 'enabled' THEN

      uState := SetState(null, pClass, rec_type.id, 'pending', 'Pending...');
      PERFORM EditStateText(uState, 'Оплата...', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Ausstehend...', GetLocale('de'));
      PERFORM EditStateText(uState, 'En attente...', GetLocale('fr'));
      PERFORM EditStateText(uState, 'In attesa...', GetLocale('it'));
      PERFORM EditStateText(uState, 'Pendiente...', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('done'), pVisible => false);
        PERFORM AddMethod(null, pClass, uState, GetAction('fail'), pVisible => false);
        PERFORM AddMethod(null, pClass, uState, GetAction('expire'), pVisible => false);

        PERFORM AddMethod(null, pClass, uState, GetAction('continue'), pVisible => false);
        PERFORM AddMethod(null, pClass, uState, GetAction('cancel'), pVisible => false);
        PERFORM AddMethod(null, pClass, uState, GetAction('reject'), pVisible => false);

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

      uState := SetState(null, pClass, rec_type.id, 'waiting_for_capture', 'Waiting for capture');
      PERFORM EditStateText(uState, 'Ожидает подтверждения', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Wartet auf Bestätigung', GetLocale('de'));
      PERFORM EditStateText(uState, 'En attente de confirmation', GetLocale('fr'));
      PERFORM EditStateText(uState, 'In attesa di conferma', GetLocale('it'));
      PERFORM EditStateText(uState, 'Esperando confirmación', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('confirm'));
        PERFORM AddMethod(null, pClass, uState, GetAction('cancel'));
        PERFORM AddMethod(null, pClass, uState, GetAction('reject'), pVisible => false);

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'), pVisible => false);

      uState := SetState(null, pClass, rec_type.id, 'confirming', 'Confirming...');
      PERFORM EditStateText(uState, 'Подтверждение...', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Bestätigung...', GetLocale('de'));
      PERFORM EditStateText(uState, 'Confirmation...', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Conferma...', GetLocale('it'));
      PERFORM EditStateText(uState, 'Confirmando...', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('done'), pVisible => false);
        PERFORM AddMethod(null, pClass, uState, GetAction('fail'), pVisible => false);
        PERFORM AddMethod(null, pClass, uState, GetAction('expire'), pVisible => false);

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

      uState := SetState(null, pClass, rec_type.id, 'canceling', 'Canceling...');
      PERFORM EditStateText(uState, 'Отмена...', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Stornierung...', GetLocale('de'));
      PERFORM EditStateText(uState, 'Annulation...', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Annullamento...', GetLocale('it'));
      PERFORM EditStateText(uState, 'Cancelando...', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('done'), pVisible => false);
        PERFORM AddMethod(null, pClass, uState, GetAction('fail'), pVisible => false);
        PERFORM AddMethod(null, pClass, uState, GetAction('expire'), pVisible => false);

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

      uState := SetState(null, pClass, rec_type.id, 'refunding', 'Refunding...');
      PERFORM EditStateText(uState, 'Возврат...', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Erstattung...', GetLocale('de'));
      PERFORM EditStateText(uState, 'Remboursement...', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Rimborso...', GetLocale('it'));
      PERFORM EditStateText(uState, 'Reembolsando...', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('done'), pVisible => false);
        PERFORM AddMethod(null, pClass, uState, GetAction('fail'), pVisible => false);
        PERFORM AddMethod(null, pClass, uState, GetAction('expire'), pVisible => false);

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

    WHEN 'disabled' THEN

      uState := SetState(null, pClass, rec_type.id, 'succeeded', 'Succeeded');
      PERFORM EditStateText(uState, 'Оплачен', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Erfolgreich', GetLocale('de'));
      PERFORM EditStateText(uState, 'Réussi', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Riuscito', GetLocale('it'));
      PERFORM EditStateText(uState, 'Exitoso', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('refund'));
        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

      uState := SetState(null, pClass, rec_type.id, 'refunded', 'Refunded');
      PERFORM EditStateText(uState, 'Возвращён', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Erstattet', GetLocale('de'));
      PERFORM EditStateText(uState, 'Remboursé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Rimborsato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Reembolsado', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

      uState := SetState(null, pClass, rec_type.id, 'partial_refunded', 'Partially refunded');
      PERFORM EditStateText(uState, 'Частично возвращён', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Teilweise erstattet', GetLocale('de'));
      PERFORM EditStateText(uState, 'Partiellement remboursé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Parzialmente rimborsato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Parcialmente reembolsado', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('refund'));
        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

      uState := SetState(null, pClass, rec_type.id, 'canceled', 'Canceled');
      PERFORM EditStateText(uState, 'Отменён', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Storniert', GetLocale('de'));
      PERFORM EditStateText(uState, 'Annulé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Annullato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Cancelado', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

      uState := SetState(null, pClass, rec_type.id, 'expired', 'Expired');
      PERFORM EditStateText(uState, 'Истёк', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Abgelaufen', GetLocale('de'));
      PERFORM EditStateText(uState, 'Expiré', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Scaduto', GetLocale('it'));
      PERFORM EditStateText(uState, 'Expirado', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

      uState := SetState(null, pClass, rec_type.id, 'failed', 'Failed');
      PERFORM EditStateText(uState, 'Ошибка', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Fehlgeschlagen', GetLocale('de'));
      PERFORM EditStateText(uState, 'Échoué', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Fallito', GetLocale('it'));
      PERFORM EditStateText(uState, 'Fallido', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

    WHEN 'deleted' THEN

      uState := SetState(null, pClass, rec_type.id, rec_type.code, 'Deleted');
      PERFORM EditStateText(uState, 'Удалён', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Gelöscht', GetLocale('de'));
      PERFORM EditStateText(uState, 'Supprimé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Eliminato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Eliminado', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('restore'));
        PERFORM AddMethod(null, pClass, uState, GetAction('drop'));

    END CASE;

  END LOOP;

  PERFORM DefaultTransition(pClass);

  FOR rec_state IN SELECT * FROM State WHERE class = pClass
  LOOP
    CASE rec_state.code
    WHEN 'created' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'pay' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'pending'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'pending' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'done' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'succeeded'));
        END IF;

        IF rec_method.actioncode = 'fail' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'failed'));
        END IF;

        IF rec_method.actioncode = 'expire' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'expired'));
        END IF;

        IF rec_method.actioncode = 'continue' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'waiting_for_capture'));
        END IF;

        IF rec_method.actioncode = 'cancel' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'canceling'));
        END IF;

        IF rec_method.actioncode = 'reject' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'canceled'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'waiting_for_capture' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'confirm' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'confirming'));
        END IF;

        IF rec_method.actioncode = 'cancel' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'canceling'));
        END IF;

        IF rec_method.actioncode = 'reject' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'canceled'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'confirming' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'done' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'succeeded'));
        END IF;

        IF rec_method.actioncode = 'fail' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'failed'));
        END IF;

        IF rec_method.actioncode = 'expire' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'expired'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'canceling' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'done' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'canceled'));
        END IF;

        IF rec_method.actioncode = 'fail' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'failed'));
        END IF;

        IF rec_method.actioncode = 'expire' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'expired'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'refunding' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'done' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'refunded'));
        END IF;

        IF rec_method.actioncode = 'fail' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'failed'));
        END IF;

        IF rec_method.actioncode = 'expire' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'expired'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'succeeded' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'refund' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'refunding'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'refunded' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'partial_refunded' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'refund' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'refunding'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'canceled' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'expired' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'failed' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
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
-- AddYooKassaEvents -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddYooKassaEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер создан', 'EventYooKassaCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер будет удалён', 'EventYooKassaDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'done' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

    IF r.code = 'fail' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

    IF r.code = 'continue' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

    IF r.code = 'expire' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер просрочен', 'EventYooKassaExpire();');
    END IF;

    IF r.code = 'pay' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Оплатить ордер', 'EventYooKassaPay();');
    END IF;

    IF r.code = 'confirm' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подтвердить', 'EventYooKassaConfirm();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

    IF r.code = 'refund' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Вернуть', 'EventYooKassaRefund();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

    IF r.code = 'cancel' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Отменить', 'EventYooKassaCancel();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

    IF r.code = 'reject' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Ордер отклонён', 'EventYooKassaReject();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassYooKassa ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassYooKassa (
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
  uClass := AddClass(pParent, pEntity, 'yookassa', 'YooKassa', false);
  PERFORM EditClassText(uClass, 'ЮKassa', GetLocale('ru'));

  -- Тип
  uType := AddType(uClass, 'reserve.yookassa', 'Reserve (YooKassa)', 'Order reservation in YooKassa payment system.');
  PERFORM EditTypeText(uType, 'Резерв (ЮKassa)', 'Резервирование заказа в платёжной системе ЮKassa.', GetLocale('ru'));

  uType := AddType(uClass, 'smart_payment.yookassa', 'Smart payment (YooKassa)', 'Smart payment in YooKassa payment system.');
  PERFORM EditTypeText(uType, 'Умный платёж (ЮKassa)', 'Умный платёж в платёжной системе ЮKassa.', GetLocale('ru'));

  uType := AddType(uClass, 'payment.yookassa', 'Payment (YooKassa)', 'Payment in YooKassa payment system.');
  PERFORM EditTypeText(uType, 'Платёж (ЮKassa)', 'Платёж в платёжной системе ЮKassa.', GetLocale('ru'));

  uType := AddType(uClass, 'validation.yookassa', 'Validation (YooKassa)', 'Card validation in YooKassa payment system.');
  PERFORM EditTypeText(uType, 'Проверка (ЮKassa)', 'Проверка карты в платёжной системе ЮKassa.', GetLocale('ru'));

  -- Событие
  PERFORM AddYooKassaEvents(uClass);

  -- Метод
  PERFORM AddYooKassaMethods(uClass);

  -- Маршрут
  PERFORM RegisterRoute('yookassa', AddEndpoint('SELECT * FROM rest.yookassa($1, $2);'));

  -- Агент
  PERFORM CreateAgent(null, GetType('api.agent'), GetVendor('system.vendor'), 'yookassa.agent', 'ЮKassa', 'Агент интернет-эквайринга от ЮKassa.');

  -- Настройки
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\Service\YooKassa\API', 'URL', 'https://api.yookassa.ru');
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\Service\YooKassa\Shop', 'Id', current_setting('yookassa.shop.id'));
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\Service\YooKassa\Shop', 'Key', current_setting('yookassa.shop.key'));

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
