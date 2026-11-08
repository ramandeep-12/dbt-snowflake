-- 05_snowpipe.sql
-- Auto-ingest: new bookings files in s3://rentals-elt-raw/raw/bookings/
-- load into RAW.BOOKINGS within about a minute, using the same COPY as 04.

USE ROLE LOADER;
USE WAREHOUSE ELT_WH;

CREATE OR REPLACE PIPE RENTALS_DB.RAW.BOOKINGS_PIPE
  AUTO_INGEST = TRUE
AS
COPY INTO RENTALS_DB.RAW.BOOKINGS
  FROM @RENTALS_DB.RAW.S3_RAW_STAGE/bookings/
  FILE_FORMAT = (FORMAT_NAME = 'RENTALS_DB.RAW.CSV_FF')
  MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
  INCLUDE_METADATA = (file_name = METADATA$FILENAME, loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = 'CONTINUE';

-- Copy the notification_channel value (an SQS ARN) for the S3 event notification
SHOW PIPES LIKE 'BOOKINGS_PIPE' IN SCHEMA RENTALS_DB.RAW;

-- Check status after uploading a test file
SELECT SYSTEM$PIPE_STATUS('RENTALS_DB.RAW.BOOKINGS_PIPE');

-- Pause when not demoing, to avoid any background cost
-- ALTER PIPE RENTALS_DB.RAW.BOOKINGS_PIPE SET PIPE_EXECUTION_PAUSED = TRUE;