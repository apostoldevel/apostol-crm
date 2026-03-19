--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddMeasureEvents ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddMeasureEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Measure created', 'EventMeasureCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Measure opened', 'EventMeasureOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Measure edited', 'EventMeasureEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Measure saved', 'EventMeasureSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Measure enabled', 'EventMeasureEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Measure disabled', 'EventMeasureDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Measure will be deleted', 'EventMeasureDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Measure restored', 'EventMeasureRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Measure will be destroyed', 'EventMeasureDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassMeasure ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassMeasure (
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
  uClass := AddClass(pParent, pEntity, 'measure', 'Measure', false);
  PERFORM EditClassText(uClass, 'Единица измерения', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Maßeinheit', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Unité de mesure', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Unità di misura', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Unidad de medida', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'time.measure', 'Time', 'Units of time.');
  PERFORM EditTypeText(uType, 'Время', 'Единицы времени.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Zeit', 'Zeiteinheiten.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Temps', 'Unités de temps.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Tempo', 'Unità di tempo.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Tiempo', 'Unidades de tiempo.', GetLocale('es'));

  uType := AddType(uClass, 'length.measure', 'Length', 'Units of length.');
  PERFORM EditTypeText(uType, 'Длина', 'Единицы длины.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Länge', 'Längeneinheiten.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Longueur', 'Unités de longueur.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Lunghezza', 'Unità di lunghezza.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Longitud', 'Unidades de longitud.', GetLocale('es'));

  uType := AddType(uClass, 'weight.measure', 'Weight', 'Units of weight.');
  PERFORM EditTypeText(uType, 'Масса', 'Единицы массы.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Gewicht', 'Gewichtseinheiten.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Poids', 'Unités de poids.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Peso', 'Unità di peso.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Peso', 'Unidades de peso.', GetLocale('es'));

  uType := AddType(uClass, 'volume.measure', 'Volume', 'Units of volume.');
  PERFORM EditTypeText(uType, 'Объём', 'Единицы объёма.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Volumen', 'Volumeneinheiten.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Volume', 'Unités de volume.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Volume', 'Unità di volume.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Volumen', 'Unidades de volumen.', GetLocale('es'));

  uType := AddType(uClass, 'area.measure', 'Area', 'Units of area.');
  PERFORM EditTypeText(uType, 'Площадь', 'Единицы площади.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Fläche', 'Flächeneinheiten.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Superficie', 'Unités de superficie.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Superficie', 'Unità di superficie.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Área', 'Unidades de área.', GetLocale('es'));

  uType := AddType(uClass, 'technical.measure', 'Technical', 'Technical units.');
  PERFORM EditTypeText(uType, 'Технические', 'Технические единицы.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Technisch', 'Technische Einheiten.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Technique', 'Unités techniques.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Tecnico', 'Unità tecniche.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Técnico', 'Unidades técnicas.', GetLocale('es'));

  uType := AddType(uClass, 'economic.measure', 'Economic', 'Economic units.');
  PERFORM EditTypeText(uType, 'Экономические', 'Экономические единицы.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Wirtschaftlich', 'Wirtschaftliche Einheiten.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Économique', 'Unités économiques.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Economico', 'Unità economiche.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Económico', 'Unidades económicas.', GetLocale('es'));

  -- Событие
  PERFORM AddMeasureEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass, ARRAY['Created', 'Opened', 'Closed', 'Deleted', 'Open', 'Close', 'Delete'], ARRAY['Создана', 'Открыта', 'Закрыта', 'Удалена', 'Открыть', 'Закрыть', 'Удалить']);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityMeasure ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityMeasure (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('measure', 'Measure');
  PERFORM EditEntityText(uEntity, 'Единица измерения', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Maßeinheit', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Unité de mesure', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Unità di misura', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Unidad de medida', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassMeasure(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('measure', AddEndpoint('SELECT * FROM rest.measure($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- InitMeasure -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitMeasure()
RETURNS         void
AS $$
BEGIN
  PERFORM CreateMeasure(null, GetType('length.measure'), '003', 'мм', 'Миллиметр');
  PERFORM CreateMeasure(null, GetType('length.measure'), '004', 'см', 'Сантиметр');
  PERFORM CreateMeasure(null, GetType('length.measure'), '005', 'дм', 'Дециметр');
  PERFORM CreateMeasure(null, GetType('length.measure'), '006', 'м', 'Метр');
  PERFORM CreateMeasure(null, GetType('length.measure'), '008', 'км', 'Километр');
  PERFORM CreateMeasure(null, GetType('length.measure'), '009', 'Мм', 'Мегаметр');
  PERFORM CreateMeasure(null, GetType('length.measure'), '039', 'дюйм', 'Дюйм (25,4 мм)');
  PERFORM CreateMeasure(null, GetType('length.measure'), '041', 'фут', 'Фут (0,3048 м)');
  PERFORM CreateMeasure(null, GetType('length.measure'), '043', 'ярд', 'Ярд (0,9144 м)');
  PERFORM CreateMeasure(null, GetType('length.measure'), '047', 'миля', 'Морская миля (1852 м)');

  PERFORM CreateMeasure(null, GetType('area.measure'), '055', 'кв. м.', 'Квадратный метр');
  PERFORM CreateMeasure(null, GetType('area.measure'), '061', 'кв. км.', 'Квадратный километр');

  PERFORM CreateMeasure(null, GetType('volume.measure'), '111', 'см3', 'Кубический сантиметр');
  PERFORM CreateMeasure(null, GetType('volume.measure'), '112', 'л', 'Литр');
  PERFORM CreateMeasure(null, GetType('volume.measure'), '113', 'куб. м.', 'Кубический метр');

  PERFORM CreateMeasure(null, GetType('weight.measure'), '161', 'мг', 'Миллиграмм');
  PERFORM CreateMeasure(null, GetType('weight.measure'), '163', 'г', 'Грамм');
  PERFORM CreateMeasure(null, GetType('weight.measure'), '166', 'кг', 'Килограмм');
  PERFORM CreateMeasure(null, GetType('weight.measure'), '168', 'т', 'Тонна');
  PERFORM CreateMeasure(null, GetType('weight.measure'), '206', 'ц', 'Центнер');
  PERFORM CreateMeasure(null, GetType('weight.measure'), '185', 'т грп', 'Грузоподъемность в метрических тоннах');

  PERFORM CreateMeasure(null, GetType('technical.measure'), '212', 'Вт', 'Ватт');
  PERFORM CreateMeasure(null, GetType('technical.measure'), '214', 'кВт', 'Киловатт');
  PERFORM CreateMeasure(null, GetType('technical.measure'), '215', 'МВт', 'Мегаватт');

  PERFORM CreateMeasure(null, GetType('technical.measure'), '222', 'В', 'Вольт');
  PERFORM CreateMeasure(null, GetType('technical.measure'), '223', 'кВ', 'Киловольт');

  PERFORM CreateMeasure(null, GetType('technical.measure'), '233', 'Гкал', 'Гигакалория');

  PERFORM CreateMeasure(null, GetType('technical.measure'), '243', 'Вт.ч', 'Ватт-час');
  PERFORM CreateMeasure(null, GetType('technical.measure'), '245', 'кВ.ч', 'Киловатт-час');

  PERFORM CreateMeasure(null, GetType('technical.measure'), '255', 'байт', 'Байт');
  PERFORM CreateMeasure(null, GetType('technical.measure'), '256', 'кбайт', 'Килобайт');
  PERFORM CreateMeasure(null, GetType('technical.measure'), '257', 'Мбайт', 'Мегабайт');

  PERFORM CreateMeasure(null, GetType('technical.measure'), '260', 'А', 'Ампер');

  PERFORM CreateMeasure(null, GetType('technical.measure'), '327', 'уз', 'Узел (миля/ч)');
  PERFORM CreateMeasure(null, GetType('technical.measure'), '328', 'м/с', 'Метр в секунду');

  PERFORM CreateMeasure(null, GetType('technical.measure'), '2355', 'градус', 'Градус (плоского угла)');

  PERFORM CreateMeasure(null, GetType('time.measure'), '354', 'с', 'Секунда');
  PERFORM CreateMeasure(null, GetType('time.measure'), '355', 'мин', 'Минута');
  PERFORM CreateMeasure(null, GetType('time.measure'), '356', 'ч', 'Час');
  PERFORM CreateMeasure(null, GetType('time.measure'), '359', 'дн', 'День');
  PERFORM CreateMeasure(null, GetType('time.measure'), '360', 'нед', 'Неделя');
  PERFORM CreateMeasure(null, GetType('time.measure'), '361', 'дек', 'Декада');
  PERFORM CreateMeasure(null, GetType('time.measure'), '362', 'мес', 'Месяц');
  PERFORM CreateMeasure(null, GetType('time.measure'), '364', 'кварт', 'Квартал');
  PERFORM CreateMeasure(null, GetType('time.measure'), '365', 'полгода', 'Полугодие');
  PERFORM CreateMeasure(null, GetType('time.measure'), '366', 'г', 'Год');

  PERFORM CreateMeasure(null, GetType('economic.measure'), '616', 'боб', 'Бобина');
  PERFORM CreateMeasure(null, GetType('economic.measure'), '625', 'л.', 'Лист');
  PERFORM CreateMeasure(null, GetType('economic.measure'), '744', '%', 'Процент');
  PERFORM CreateMeasure(null, GetType('economic.measure'), '796', 'шт', 'Штука');
  PERFORM CreateMeasure(null, GetType('economic.measure'), '876', 'усл. ед', 'Условная единица');
  PERFORM CreateMeasure(null, GetType('economic.measure'), '923', 'слово', 'Слово');
  PERFORM CreateMeasure(null, GetType('economic.measure'), '7923', 'аб-т', 'Абонент');
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
