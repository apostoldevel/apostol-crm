--------------------------------------------------------------------------------
-- CONFIRMATION ----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.confirmation ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief API view for payment confirmations
 * @field {uuid} id - Confirmation record identifier
 * @field {uuid} agent - Payment agent identifier
 * @field {uuid} order - Payment (order) identifier
 * @field {uuid} client - Client identifier
 * @field {uuid} card - Card identifier
 * @field {uuid} invoice - Invoice identifier
 * @field {jsonb} Confirmation - Confirmation data from provider
 * @see Confirmation (kernel view)
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.confirmation
AS
  SELECT * FROM Confirmation;

GRANT SELECT ON api.confirmation TO administrator;
