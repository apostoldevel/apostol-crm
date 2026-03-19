--------------------------------------------------------------------------------
-- db.preload ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.preload (
    file            uuid NOT NULL REFERENCES db.file(id) ON DELETE CASCADE,
    row             int NOT NULL,
    col             int NOT NULL,
    value           text,
    PRIMARY KEY (file, row, col)
);

COMMENT ON TABLE db.preload IS 'Staging area for file data import (row/column/value triples).';

COMMENT ON COLUMN db.preload.file IS 'Reference to the source file being imported.';
COMMENT ON COLUMN db.preload.row IS 'Row number in the source file.';
COMMENT ON COLUMN db.preload.col IS 'Column number in the source file.';

CREATE INDEX ON db.preload (file);
CREATE INDEX ON db.preload (file, row);
