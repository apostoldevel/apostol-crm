-- Последовательность для идентификаторов статусов устройства.
CREATE SEQUENCE IF NOT EXISTS db.sequence_status
 START WITH 1
 INCREMENT BY 1
 MINVALUE 1;

-- Последовательность для идентификаторов транзакций устройства.
CREATE SEQUENCE IF NOT EXISTS db.sequence_transaction
 START WITH 1
 INCREMENT BY 1
 MINVALUE 1;
