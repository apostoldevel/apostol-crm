--------------------------------------------------------------------------------
-- InitConfigurationEntity -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitConfigurationEntity()
RETURNS     void
AS $$
DECLARE
  uDocument		uuid;
  uReference	uuid;
BEGIN
  -- Документ

  uDocument := GetClass('document');

	-- Счёт

	PERFORM CreateEntityAccount(uDocument);

	-- Адрес

	PERFORM CreateEntityAddress(uDocument);

	-- Клиент

	PERFORM CreateEntityClient(uDocument);

	-- Устройство

	PERFORM CreateEntityDevice(uDocument);

  -- Справочник

  uReference := GetClass('reference');

	-- Календарь

	PERFORM CreateEntityCalendar(uReference);

	-- Категория

	PERFORM CreateEntityCategory(uReference);

	-- Валюта

	PERFORM CreateEntityCurrency(uReference);

	-- Мера

	PERFORM CreateEntityMeasure(uReference);

    -- Режим

    PERFORM CreateEntityMode(uReference);

	-- Модель

	PERFORM CreateEntityModel(uReference);

	-- Свойство

	PERFORM CreateEntityProperty(uReference);

END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
