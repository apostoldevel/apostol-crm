--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddTaskMethods --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddTaskMethods (
  pClass            uuid
)
RETURNS             void
AS $$
DECLARE
  uState            uuid;
  uMethod           uuid;

  rec_type          record;
  rec_state         record;
  rec_method        record;
BEGIN
  -- Операции (без учёта состояния)

  PERFORM DefaultMethods(pClass);

  -- Операции (с учётом состояния)

  FOR rec_type IN SELECT * FROM StateType
  LOOP

    CASE rec_type.code
    WHEN 'created' THEN

      uState := AddState(pClass, rec_type.id, rec_type.code, 'New');
      PERFORM EditStateText(uState, 'Новая', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Neu', GetLocale('de'));
      PERFORM EditStateText(uState, 'Nouvelle', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Nuova', GetLocale('it'));
      PERFORM EditStateText(uState, 'Nueva', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Start');
        PERFORM EditMethodText(uMethod, 'Начать', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Starten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Démarrer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Iniziare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Iniciar', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('complete'));
		PERFORM AddMethod(null, pClass, uState, GetAction('plan'));
		PERFORM AddMethod(null, pClass, uState, GetAction('postpone'));
        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

    WHEN 'enabled' THEN

      uState := AddState(pClass, rec_type.id, rec_type.code, 'In progress');
      PERFORM EditStateText(uState, 'Текущая', GetLocale('ru'));
      PERFORM EditStateText(uState, 'In Bearbeitung', GetLocale('de'));
      PERFORM EditStateText(uState, 'En cours', GetLocale('fr'));
      PERFORM EditStateText(uState, 'In corso', GetLocale('it'));
      PERFORM EditStateText(uState, 'En progreso', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('complete'));
		PERFORM AddMethod(null, pClass, uState, GetAction('expire'), null, 'Просрочить', pVisible => false);
		PERFORM AddMethod(null, pClass, uState, GetAction('plan'), null, 'Планировать', pVisible => false);
		PERFORM AddMethod(null, pClass, uState, GetAction('postpone'));
        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

	  uState := AddState(pClass, rec_type.id, 'expired', 'Expired');
      PERFORM EditStateText(uState, 'Просрочена', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Abgelaufen', GetLocale('de'));
      PERFORM EditStateText(uState, 'Expirée', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Scaduta', GetLocale('it'));
      PERFORM EditStateText(uState, 'Expirada', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('complete'));
		uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Start');
        PERFORM EditMethodText(uMethod, 'Начать', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Starten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Démarrer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Iniziare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Iniciar', GetLocale('es'));
		PERFORM AddMethod(null, pClass, uState, GetAction('postpone'));
        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

	  uState := AddState(pClass, rec_type.id, 'planned', 'Planned');
      PERFORM EditStateText(uState, 'Планируется', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Geplant', GetLocale('de'));
      PERFORM EditStateText(uState, 'Planifiée', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Pianificata', GetLocale('it'));
      PERFORM EditStateText(uState, 'Planificada', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('complete'));
		uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Start');
        PERFORM EditMethodText(uMethod, 'Начать', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Starten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Démarrer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Iniziare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Iniciar', GetLocale('es'));
		PERFORM AddMethod(null, pClass, uState, GetAction('postpone'));
        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

	  uState := AddState(pClass, rec_type.id, 'postponed', 'Postponed');
      PERFORM EditStateText(uState, 'Отложена', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Verschoben', GetLocale('de'));
      PERFORM EditStateText(uState, 'Reportée', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Rimandata', GetLocale('it'));
      PERFORM EditStateText(uState, 'Pospuesta', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('complete'));
		uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Start');
        PERFORM EditMethodText(uMethod, 'Начать', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Starten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Démarrer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Iniziare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Iniciar', GetLocale('es'));
        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

    WHEN 'disabled' THEN

      uState := AddState(pClass, rec_type.id, 'completed', 'Completed');
      PERFORM EditStateText(uState, 'Исполнена', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Abgeschlossen', GetLocale('de'));
      PERFORM EditStateText(uState, 'Terminée', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Completata', GetLocale('it'));
      PERFORM EditStateText(uState, 'Completada', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('return'));
        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

    WHEN 'deleted' THEN

      uState := AddState(pClass, rec_type.id, rec_type.code, 'Deleted');
      PERFORM EditStateText(uState, 'Удалена', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Gelöscht', GetLocale('de'));
      PERFORM EditStateText(uState, 'Supprimée', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Eliminata', GetLocale('it'));
      PERFORM EditStateText(uState, 'Eliminada', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('restore'));
        PERFORM AddMethod(null, pClass, uState, GetAction('drop'));

    END CASE;

  END LOOP;

  PERFORM DefaultTransition(pClass);

  -- Переходы из состояния в состояние

  FOR rec_state IN SELECT * FROM State WHERE class = pClass
  LOOP
    CASE rec_state.code
    WHEN 'created' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'enable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'enabled'));
        END IF;

        IF rec_method.actioncode = 'complete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'completed'));
        END IF;

        IF rec_method.actioncode = 'plan' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'planned'));
        END IF;

        IF rec_method.actioncode = 'postpone' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'postponed'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'enabled' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'complete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'completed'));
        END IF;

        IF rec_method.actioncode = 'expire' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'expired'));
        END IF;

        IF rec_method.actioncode = 'plan' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'planned'));
        END IF;

        IF rec_method.actioncode = 'postpone' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'postponed'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'expired' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'enable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'enabled'));
        END IF;

        IF rec_method.actioncode = 'postpone' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'postponed'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'planned' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'enable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'enabled'));
        END IF;

        IF rec_method.actioncode = 'postpone' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'postponed'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'postponed' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'enable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'enabled'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'completed' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'return' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'enabled'));
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
-- AddTaskEvents ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddTaskEvents (
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
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача создана', 'EventTaskCreate();');
	END IF;

	IF r.code = 'open' THEN
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача открыта', 'EventTaskOpen();');
	END IF;

	IF r.code = 'edit' THEN
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача изменена', 'EventTaskEdit();');
	END IF;

	IF r.code = 'save' THEN
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача сохранена', 'EventTaskSave();');
	END IF;

	IF r.code = 'enable' THEN
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача в работе', 'EventTaskEnable();');
	END IF;

	IF r.code = 'disable' THEN
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача принята и завершена', 'EventTaskDisable();');
	END IF;

	IF r.code = 'delete' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача будет удалена', 'EventTaskDelete();');
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	END IF;

	IF r.code = 'restore' THEN
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача восстановлена', 'EventTaskRestore();');
	END IF;

	IF r.code = 'complete' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача исполнена', 'EventTaskComplete();');
	END IF;

	IF r.code = 'return' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача возвращена', 'EventTaskReturn();');
	END IF;

	IF r.code = 'expire' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача просрочена', 'EventTaskExpire();');
	END IF;

	IF r.code = 'plan' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача просрочена', 'EventTaskPlan();');
	END IF;

	IF r.code = 'postpone' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Задача отложена', 'EventTaskPostpone();');
	END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassTask -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassTask (
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
  uClass := AddClass(pParent, pEntity, 'task', 'Task', false);
  PERFORM EditClassText(uClass, 'Задача', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Aufgabe', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Tâche', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Attività', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Tarea', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'system.task', 'System', 'System task.');
  PERFORM EditTypeText(uType, 'Система', 'Системная задача.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'System', 'Systemaufgabe.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Système', 'Tâche système.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Sistema', 'Attività di sistema.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Sistema', 'Tarea del sistema.', GetLocale('es'));

  uType := AddType(uClass, 'user.task', 'User', 'User task.');
  PERFORM EditTypeText(uType, 'Пользователь', 'Пользовательская задача.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Benutzer', 'Benutzeraufgabe.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Utilisateur', 'Tâche utilisateur.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Utente', 'Attività utente.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Usuario', 'Tarea de usuario.', GetLocale('es'));

  -- Событие
  PERFORM AddTaskEvents(uClass);

  -- Метод
  PERFORM AddTaskMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityTask ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityTask (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('task', 'Task');
  PERFORM EditEntityText(uEntity, 'Задача', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Aufgabe', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Tâche', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Attività', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Tarea', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassTask(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('task', AddEndpoint('SELECT * FROM rest.task($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
