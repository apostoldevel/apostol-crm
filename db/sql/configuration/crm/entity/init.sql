--------------------------------------------------------------------------------
-- InitConfigurationEntity -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitConfigurationEntity()
RETURNS     void
AS $$
DECLARE
  uParent   uuid;
BEGIN
  -- Документ

  uParent := GetClass('document');

    -- Счёт

    PERFORM CreateEntityAccount(uParent);

    -- Клиент

    PERFORM CreateEntityClient(uParent);

    -- Устройство

    PERFORM CreateEntityDevice(uParent);

  -- Справочник

  uParent := GetClass('reference');

    -- Адрес

    PERFORM CreateEntityAddress(uParent);

    -- Календарь

    PERFORM CreateEntityCalendar(uParent);

    -- Категория

    PERFORM CreateEntityCategory(uParent);

    -- Страна

    PERFORM CreateEntityCountry(uParent);

    -- Валюта

    PERFORM CreateEntityCurrency(uParent);

    -- Мера

    PERFORM CreateEntityMeasure(uParent);

    -- Модель

    PERFORM CreateEntityModel(uParent);

    -- Свойство

    PERFORM CreateEntityProperty(uParent);

END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
