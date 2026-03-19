--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddSubscriptionMethods ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddSubscriptionMethods (
  pClass        uuid
)
RETURNS void
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

      uState := SetState(null, pClass, rec_type.id, 'incomplete', 'Incomplete');
      PERFORM EditStateText(uState, 'Не завершена', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Unvollständig', GetLocale('de'));
      PERFORM EditStateText(uState, 'Incomplète', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Incompleto', GetLocale('it'));
      PERFORM EditStateText(uState, 'Incompleta', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('pay'), null, 'Pay', null, false);
        PERFORM EditMethodText(uMethod, 'Оплатить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Bezahlen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Payer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Pagare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Pagar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Trial', null, false);
        PERFORM EditMethodText(uMethod, 'Пробный период', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Testphase', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Essai', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Prova', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Prueba', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('expire'), null, 'Expire', null, false);
        PERFORM EditMethodText(uMethod, 'Истекла', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Abgelaufen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Expirée', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Scaduta', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Expirada', GetLocale('es'));

    WHEN 'enabled' THEN

      uState := SetState(null, pClass, rec_type.id, 'trialing', 'Trialing');
      PERFORM EditStateText(uState, 'Пробный период', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Testphase', GetLocale('de'));
      PERFORM EditStateText(uState, 'Essai', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Periodo di prova', GetLocale('it'));
      PERFORM EditStateText(uState, 'Período de prueba', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('pay'), null, 'Pay', null, false);
        PERFORM EditMethodText(uMethod, 'Оплатить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Bezahlen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Payer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Pagare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Pagar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('cancel'), null, 'Cancel');
        PERFORM EditMethodText(uMethod, 'Отменить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Stornieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Annuler', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Annullare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Cancelar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('stop'), null, 'Past due', null, false);
        PERFORM EditMethodText(uMethod, 'Просрочена', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Überfällig', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'En retard', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Scaduta', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Vencida', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('fail'), null, 'Unpaid', null, false);
        PERFORM EditMethodText(uMethod, 'Не оплачена', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Unbezahlt', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Non payée', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Non pagata', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'No pagada', GetLocale('es'));

      uState := SetState(null, pClass, rec_type.id, 'active', 'Active');
      PERFORM EditStateText(uState, 'Активна', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Aktiv', GetLocale('de'));
      PERFORM EditStateText(uState, 'Active', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Attiva', GetLocale('it'));
      PERFORM EditStateText(uState, 'Activa', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('cancel'), null, 'Cancel');
        PERFORM EditMethodText(uMethod, 'Отменить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Stornieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Annuler', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Annullare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Cancelar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('stop'), null, 'Past due', null, false);
        PERFORM EditMethodText(uMethod, 'Просрочена', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Überfällig', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'En retard', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Scaduta', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Vencida', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('fail'), null, 'Unpaid', null, false);
        PERFORM EditMethodText(uMethod, 'Не оплачена', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Unbezahlt', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Non payée', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Non pagata', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'No pagada', GetLocale('es'));

    WHEN 'disabled' THEN

      uState := SetState(null, pClass, rec_type.id, 'past_due', 'Past due');
      PERFORM EditStateText(uState, 'Просрочена', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Überfällig', GetLocale('de'));
      PERFORM EditStateText(uState, 'En retard', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Scaduta', GetLocale('it'));
      PERFORM EditStateText(uState, 'Vencida', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('pay'), null, 'Pay', null, false);
        PERFORM EditMethodText(uMethod, 'Оплатить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Bezahlen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Payer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Pagare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Pagar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('cancel'), null, 'Cancel');
        PERFORM EditMethodText(uMethod, 'Отменить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Stornieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Annuler', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Annullare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Cancelar', GetLocale('es'));

      uState := SetState(null, pClass, rec_type.id, 'unpaid', 'Unpaid');
      PERFORM EditStateText(uState, 'Не оплачена', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Unbezahlt', GetLocale('de'));
      PERFORM EditStateText(uState, 'Non payée', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Non pagata', GetLocale('it'));
      PERFORM EditStateText(uState, 'No pagada', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('pay'), null, 'Pay', null, false);
        PERFORM EditMethodText(uMethod, 'Оплатить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Bezahlen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Payer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Pagare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Pagar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('cancel'), null, 'Cancel');
        PERFORM EditMethodText(uMethod, 'Отменить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Stornieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Annuler', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Annullare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Cancelar', GetLocale('es'));

    WHEN 'deleted' THEN

      uState := SetState(null, pClass, rec_type.id, 'incomplete_expired', 'Expired');
      PERFORM EditStateText(uState, 'Истекла', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Abgelaufen', GetLocale('de'));
      PERFORM EditStateText(uState, 'Expirée', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Scaduta', GetLocale('it'));
      PERFORM EditStateText(uState, 'Expirada', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('restore'), null, 'Restore', null, false);
        PERFORM EditMethodText(uMethod, 'Восстановить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Wiederherstellen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Restaurer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Ripristinare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Restaurar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('drop'), null, 'Drop');
        PERFORM EditMethodText(uMethod, 'Уничтожить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Vernichten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Détruire', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Distruggere', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Destruir', GetLocale('es'));

      uState := SetState(null, pClass, rec_type.id, 'canceled', 'Cancelled');
      PERFORM EditStateText(uState, 'Отменена', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Storniert', GetLocale('de'));
      PERFORM EditStateText(uState, 'Annulée', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Annullata', GetLocale('it'));
      PERFORM EditStateText(uState, 'Cancelada', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('restore'), null, 'Restore', null, false);
        PERFORM EditMethodText(uMethod, 'Восстановить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Wiederherstellen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Restaurer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Ripristinare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Restaurar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('drop'), null, 'Drop');
        PERFORM EditMethodText(uMethod, 'Уничтожить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Vernichten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Détruire', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Distruggere', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Destruir', GetLocale('es'));

    END CASE;

  END LOOP;

  PERFORM DefaultTransition(pClass);

  UPDATE db.transition SET newstate = GetState(GetClass('subscription'), 'incomplete') WHERE method = GetMethod(GetClass('subscription'), GetAction('create'));

  FOR rec_state IN SELECT * FROM State WHERE class = pClass
  LOOP
    CASE rec_state.code
    WHEN 'incomplete' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'pay' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'active'));
        END IF;

        IF rec_method.actioncode = 'enable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'trialing'));
        END IF;

        IF rec_method.actioncode = 'expire' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'incomplete_expired'));
        END IF;
      END LOOP;

    WHEN 'trialing' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'pay' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'active'));
        END IF;

        IF rec_method.actioncode = 'cancel' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'canceled'));
        END IF;

        IF rec_method.actioncode = 'stop' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'past_due'));
        END IF;

        IF rec_method.actioncode = 'fail' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'unpaid'));
        END IF;
      END LOOP;

    WHEN 'active' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'cancel' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'canceled'));
        END IF;

        IF rec_method.actioncode = 'stop' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'past_due'));
        END IF;

        IF rec_method.actioncode = 'fail' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'unpaid'));
        END IF;
      END LOOP;

    WHEN 'past_due' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'pay' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'active'));
        END IF;

        IF rec_method.actioncode = 'cancel' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'canceled'));
        END IF;
      END LOOP;

    WHEN 'unpaid' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'pay' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'active'));
        END IF;

        IF rec_method.actioncode = 'cancel' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'canceled'));
        END IF;
      END LOOP;

    WHEN 'incomplete_expired' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'restore' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'incomplete'));
        END IF;
      END LOOP;

    WHEN 'canceled' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'restore' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'incomplete'));
        END IF;
      END LOOP;
    END CASE;
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- AddSubscriptionEvents -------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddSubscriptionEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подписка создана', 'EventSubscriptionCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подписка открыта', 'EventSubscriptionOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подписка изменена', 'EventSubscriptionEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подписка сохранена', 'EventSubscriptionSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Пробная подписка', 'EventSubscriptionEnable();');
    END IF;

    IF r.code = 'pay' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подписка оплачена', 'EventSubscriptionPay();');
    END IF;

    IF r.code = 'expire' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подписка истекла', 'EventSubscriptionExpire();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

    IF r.code = 'cancel' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подписка отменена', 'EventSubscriptionCancel();');
    END IF;

    IF r.code = 'stop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подписка остановлена', 'EventSubscriptionStop();');
    END IF;

    IF r.code = 'fail' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Проблемы с оплатой подписки', 'EventSubscriptionFail();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подписка отключена', 'EventSubscriptionDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подписка удалена', 'EventSubscriptionDelete();');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подписка восстановлена', 'EventSubscriptionRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подписка будет уничтожена', 'EventSubscriptionDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassSubscription -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassSubscription (
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
  uClass := AddClass(pParent, pEntity, 'subscription', 'Subscription', false);
  PERFORM EditClassText(uClass, 'Подписка', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Abonnement', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Abonnement', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Abbonamento', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Suscripción', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'charge_automatically.subscription', 'Charge automatically', 'Charge automatically.');
  PERFORM EditTypeText(uType, 'Автоматическая', 'Автоматическая.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Automatisch', 'Automatisch.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Automatique', 'Automatique.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Automatico', 'Automatico.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Automático', 'Automático.', GetLocale('es'));

  uType := AddType(uClass, 'send_invoice.subscription', 'Send invoice', 'Send invoice.');
  PERFORM EditTypeText(uType, 'По счёту', 'По счёту.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Rechnung senden', 'Rechnung senden.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Envoyer facture', 'Envoyer facture.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Inviare fattura', 'Inviare fattura.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Enviar factura', 'Enviar factura.', GetLocale('es'));

  -- Событие
  PERFORM AddSubscriptionEvents(uClass);

  -- Метод
  PERFORM AddSubscriptionMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntitySubscription ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntitySubscription (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('subscription', 'Subscription');
  PERFORM EditEntityText(uEntity, 'Подписка', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Abonnement', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Abonnement', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Abbonamento', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Suscripción', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassSubscription(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('subscription', AddEndpoint('SELECT * FROM rest.subscription($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
