--------------------------------------------------------------------------------
-- Confirmation ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Kernel view for payment confirmations with agent, payment, client, card, and invoice details
 * @field {uuid} id - Confirmation record identifier
 * @field {uuid} agent - Payment agent identifier
 * @field {text} AgentCode - Agent reference code
 * @field {text} AgentName - Agent localized name
 * @field {text} AgentDescription - Agent localized description
 * @field {uuid} order - Payment (order) identifier
 * @field {text} OrderCode - Payment (order) code
 * @field {text} OrderName - Payment localized label
 * @field {text} OrderDescription - Payment localized description
 * @field {uuid} client - Client identifier
 * @field {text} ClientCode - Client code
 * @field {text} ClientName - Client localized name
 * @field {uuid} card - Card identifier
 * @field {text} CardCode - Card code
 * @field {uuid} invoice - Invoice identifier
 * @field {text} InvoiceCode - Invoice code
 * @field {jsonb} Confirmation - Confirmation data from payment provider
 * @field {timestamptz} validfromdate - Validity start timestamp
 * @field {timestamptz} validtodate - Validity end timestamp
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW Confirmation
AS
  SELECT t.id,
         t.agent, a.code AS AgentCode, at.name AS AgentName, at.description AS AgentDescription,
         t.payment AS "order", p.code AS OrderCode, pot.label AS OrderName, pdt.description AS OrderDescription,
         p.client, c.code AS ClientCode, cn.name AS ClientName,
         p.card, d.code AS CardCode,
         p.invoice, i.code AS InvoiceCode,
         t.data AS Confirmation, t.validfromdate, t.validtodate
    FROM db.confirmation t INNER JOIN db.reference       a ON a.id = t.agent
                            LEFT JOIN db.reference_text at ON at.reference = a.id AND at.locale = current_locale()
                           INNER JOIN db.payment         p ON p.id = t.payment
                            LEFT JOIN db.object_text   pot ON pot.object = p.id AND pot.locale = current_locale()
                            LEFT JOIN db.document_text pdt ON pdt.document = p.id AND pdt.locale = current_locale()
                           INNER JOIN db.client          c ON c.id = p.client
                            LEFT JOIN db.client_name    cn ON cn.client = c.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()
                            LEFT JOIN db.card            d ON d.id = p.card
                            LEFT JOIN db.invoice         i ON i.id = p.invoice;

GRANT SELECT ON Confirmation TO administrator;
