-- 03_file_formats.sql
-- One named file format per source type, owned by LOADER in RAW.
-- Reused by COPY INTO (04) and Snowpipe (05).

USE ROLE LOADER;
USE WAREHOUSE ELT_WH;

-- CSV: read the header row so columns can be loaded by name
CREATE OR REPLACE FILE FORMAT RENTALS_DB.RAW.CSV_FF
  TYPE = CSV
  PARSE_HEADER = TRUE
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL')
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- JSON: the file is one big array, so split it into one row per element
CREATE OR REPLACE FILE FORMAT RENTALS_DB.RAW.JSON_FF
  TYPE = JSON
  STRIP_OUTER_ARRAY = TRUE;

-- Parquet: self-describing, column names and types come from the file
CREATE OR REPLACE FILE FORMAT RENTALS_DB.RAW.PARQUET_FF
  TYPE = PARQUET;

-- Verify all three exist
SHOW FILE FORMATS IN SCHEMA RENTALS_DB.RAW;

-- Check: read JSON and Parquet straight from the stage
SELECT $1 FROM @RENTALS_DB.RAW.S3_RAW_STAGE/json/listings/
  (FILE_FORMAT => 'RENTALS_DB.RAW.JSON_FF') LIMIT 3;

SELECT $1:listing_id::NUMBER       AS listing_id,
       $1:address.city::VARCHAR    AS city,
       $1:address.country::VARCHAR AS country
FROM @RENTALS_DB.RAW.S3_RAW_STAGE/json/listings/
  (FILE_FORMAT => 'RENTALS_DB.RAW.JSON_FF') LIMIT 3;

SELECT $1 FROM @RENTALS_DB.RAW.S3_RAW_STAGE/parquet/hosts/
  (FILE_FORMAT => 'RENTALS_DB.RAW.PARQUET_FF') LIMIT 3;