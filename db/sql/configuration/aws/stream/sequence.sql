-- Последовательность для идентификаторов журнала событий потока.
CREATE SEQUENCE IF NOT EXISTS SEQUENCE_STREAM_LOG
 START WITH 1
 INCREMENT BY 1
 MINVALUE 1;
