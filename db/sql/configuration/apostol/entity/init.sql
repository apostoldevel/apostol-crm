--------------------------------------------------------------------------------
-- InitConfigurationEntity -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitConfigurationEntity()
RETURNS         void
AS $$
DECLARE
  uParent        uuid;
BEGIN
  -- Document

  uParent := GetClass('document');

    -- Account

    PERFORM CreateEntityAccount(uParent);

    -- Card

    PERFORM CreateEntityCard(uParent);

    -- Client

    PERFORM CreateEntityClient(uParent);

    -- Company

    PERFORM CreateEntityCompany(uParent);

    -- Device

    PERFORM CreateEntityDevice(uParent);

    -- Identity document

    PERFORM CreateEntityIdentity(uParent);

    -- Invoice

    PERFORM CreateEntityInvoice(uParent);

    -- Order

    PERFORM CreateEntityOrder(uParent);

    -- Payment

    PERFORM CreateEntityPayment(uParent);

    -- Price

    PERFORM CreateEntityPrice(uParent);

    -- Product

    PERFORM CreateEntityProduct(uParent);

    -- Subscription

    PERFORM CreateEntitySubscription(uParent);

    -- Tariff

    PERFORM CreateEntityTariff(uParent);

    -- Task

    PERFORM CreateEntityTask(uParent);

    -- Transaction

    PERFORM CreateEntityTransaction(uParent);

  -- Reference

  uParent := GetClass('reference');

    -- Address

    PERFORM CreateEntityAddress(uParent);

    -- Calendar

    PERFORM CreateEntityCalendar(uParent);

    -- Category

    PERFORM CreateEntityCategory(uParent);

    -- Country

    PERFORM CreateEntityCountry(uParent);

    -- Currency

    PERFORM CreateEntityCurrency(uParent);

    -- Format

    PERFORM CreateEntityFormat(uParent);

    -- Measure

    PERFORM CreateEntityMeasure(uParent);

    -- Model

    PERFORM CreateEntityModel(uParent);

    -- Property

    PERFORM CreateEntityProperty(uParent);

    -- Region

    PERFORM CreateEntityRegion(uParent);

    -- Service

    PERFORM CreateEntityService(uParent);

END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
