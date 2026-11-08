-- 04_raw_tables_and_copy.sql
-- RAW landing tables (owned by LOADER) loaded from S3 with COPY INTO.
-- Each table keeps the source file name and load time for lineage.
-- Requires the file formats from 03_file_formats.sql.

USE ROLE LOADER;
USE WAREHOUSE ELT_WH;

-- 1. Bookings: CSV, typed columns
CREATE OR REPLACE TABLE RENTALS_DB.RAW.BOOKINGS (
  booking_id VARCHAR, listing_id NUMBER, booking_date DATE, nights_booked NUMBER,
  booking_amount NUMBER(10,2), cleaning_fee NUMBER(10,2), service_fee NUMBER(10,2),
  booking_status VARCHAR, created_at TIMESTAMP_NTZ,
  file_name VARCHAR, loaded_at TIMESTAMP_LTZ);

COPY INTO RENTALS_DB.RAW.BOOKINGS
  FROM @RENTALS_DB.RAW.S3_RAW_STAGE/bookings/
  FILE_FORMAT = (FORMAT_NAME = 'RENTALS_DB.RAW.CSV_FF')
  MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
  INCLUDE_METADATA = (file_name = METADATA$FILENAME, loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = 'CONTINUE';

-- 2. Hosts: Parquet, matched by column name
CREATE OR REPLACE TABLE RENTALS_DB.RAW.HOSTS (
  host_id NUMBER, host_name VARCHAR, host_since DATE, is_superhost BOOLEAN,
  response_rate NUMBER, created_at TIMESTAMP_NTZ,
  file_name VARCHAR, loaded_at TIMESTAMP_LTZ);

COPY INTO RENTALS_DB.RAW.HOSTS
  FROM @RENTALS_DB.RAW.S3_RAW_STAGE/parquet/hosts/
  FILE_FORMAT = (FORMAT_NAME = 'RENTALS_DB.RAW.PARQUET_FF')
  MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
  INCLUDE_METADATA = (file_name = METADATA$FILENAME, loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = 'CONTINUE';

-- 3. Listings: JSON kept whole in a VARIANT column, parsed later in Silver
CREATE OR REPLACE TABLE RENTALS_DB.RAW.LISTINGS_JSON (
  raw VARIANT, file_name VARCHAR, loaded_at TIMESTAMP_LTZ);

COPY INTO RENTALS_DB.RAW.LISTINGS_JSON (raw, file_name, loaded_at)
  FROM (
    SELECT $1, METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @RENTALS_DB.RAW.S3_RAW_STAGE/json/listings/
  )
  FILE_FORMAT = (FORMAT_NAME = 'RENTALS_DB.RAW.JSON_FF')
  ON_ERROR = 'CONTINUE';

-- 4. Let dbt (TRANSFORMER) read the RAW tables
GRANT USAGE  ON SCHEMA RENTALS_DB.RAW               TO ROLE TRANSFORMER;
GRANT SELECT ON ALL TABLES IN SCHEMA RENTALS_DB.RAW TO ROLE TRANSFORMER;

-- 5. Check what loaded
SELECT 'bookings' AS tbl, COUNT(*) AS row_count FROM RENTALS_DB.RAW.BOOKINGS
UNION ALL SELECT 'hosts', COUNT(*) FROM RENTALS_DB.RAW.HOSTS
UNION ALL SELECT 'listings_json', COUNT(*) FROM RENTALS_DB.RAW.LISTINGS_JSON;

-- 6. Load history: status and any errors per file (last hour)
SELECT table_name, file_name, status, row_count, row_parsed, first_error_message
FROM TABLE(RENTALS_DB.INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'RENTALS_DB.RAW.BOOKINGS',
  START_TIME => DATEADD(hour, -1, CURRENT_TIMESTAMP())))
UNION ALL
SELECT table_name, file_name, status, row_count, row_parsed, first_error_message
FROM TABLE(RENTALS_DB.INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'RENTALS_DB.RAW.HOSTS',
  START_TIME => DATEADD(hour, -1, CURRENT_TIMESTAMP())))
UNION ALL
SELECT table_name, file_name, status, row_count, row_parsed, first_error_message
FROM TABLE(RENTALS_DB.INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'RENTALS_DB.RAW.LISTINGS_JSON',
  START_TIME => DATEADD(hour, -1, CURRENT_TIMESTAMP())));