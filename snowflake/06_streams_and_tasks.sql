-- 06_streams_and_tasks.sql
-- CDC: a stream tracks new rows in RAW.BOOKINGS, and a task MERGEs them into
-- SILVER.BOOKINGS_CDC every 5 minutes, but only when the stream has data.
-- The task owns BOOKINGS_CDC; dbt never writes to it.

-- 1. Enable change tracking on the source (only the table owner can do this)
USE ROLE LOADER;
ALTER TABLE RENTALS_DB.RAW.BOOKINGS SET CHANGE_TRACKING = TRUE;

-- 2. Allow TRANSFORMER to run tasks (account-level privilege)
USE ROLE ACCOUNTADMIN;
GRANT EXECUTE TASK ON ACCOUNT TO ROLE TRANSFORMER;

-- 3. Stream, target table and task, all owned by TRANSFORMER in SILVER
USE ROLE TRANSFORMER;
USE WAREHOUSE ELT_WH;

-- SHOW_INITIAL_ROWS = TRUE: the first read also returns existing rows (backfill)
CREATE OR REPLACE STREAM RENTALS_DB.SILVER.BOOKINGS_STREAM
  ON TABLE RENTALS_DB.RAW.BOOKINGS
  SHOW_INITIAL_ROWS = TRUE;

CREATE TABLE IF NOT EXISTS RENTALS_DB.SILVER.BOOKINGS_CDC (
  booking_id VARCHAR, listing_id NUMBER, booking_date DATE, nights_booked NUMBER,
  total_amount NUMBER(12,2), cleaning_fee NUMBER(10,2), service_fee NUMBER(10,2),
  booking_status VARCHAR, created_at TIMESTAMP_NTZ,
  source_file VARCHAR, updated_at TIMESTAMP_LTZ);

CREATE OR REPLACE TASK RENTALS_DB.SILVER.MERGE_BOOKINGS_CDC
  WAREHOUSE = ELT_WH
  SCHEDULE = '5 MINUTE'
  WHEN SYSTEM$STREAM_HAS_DATA('RENTALS_DB.SILVER.BOOKINGS_STREAM')
AS
MERGE INTO RENTALS_DB.SILVER.BOOKINGS_CDC t
USING (
  SELECT booking_id, listing_id, booking_date, nights_booked,
         ROUND(nights_booked * booking_amount, 2) AS total_amount,
         cleaning_fee, service_fee, booking_status, created_at,
         file_name AS source_file
  FROM RENTALS_DB.SILVER.BOOKINGS_STREAM
  WHERE METADATA$ACTION = 'INSERT'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY loaded_at DESC) = 1
) s
ON t.booking_id = s.booking_id
WHEN MATCHED THEN UPDATE SET
  listing_id = s.listing_id, booking_date = s.booking_date,
  nights_booked = s.nights_booked, total_amount = s.total_amount,
  cleaning_fee = s.cleaning_fee, service_fee = s.service_fee,
  booking_status = s.booking_status, created_at = s.created_at,
  source_file = s.source_file, updated_at = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN INSERT
  (booking_id, listing_id, booking_date, nights_booked, total_amount,
   cleaning_fee, service_fee, booking_status, created_at, source_file, updated_at)
VALUES
  (s.booking_id, s.listing_id, s.booking_date, s.nights_booked, s.total_amount,
   s.cleaning_fee, s.service_fee, s.booking_status, s.created_at, s.source_file,
   CURRENT_TIMESTAMP());

-- Tasks are created suspended; resume to start the schedule
ALTER TASK RENTALS_DB.SILVER.MERGE_BOOKINGS_CDC RESUME;

-- 4. Run once now instead of waiting 5 minutes
EXECUTE TASK RENTALS_DB.SILVER.MERGE_BOOKINGS_CDC;

-- 5. Check (wait about 30 seconds after EXECUTE TASK)
SELECT name, state, scheduled_time, completed_time, error_message
FROM TABLE(RENTALS_DB.INFORMATION_SCHEMA.TASK_HISTORY(
  TASK_NAME => 'MERGE_BOOKINGS_CDC'))
ORDER BY scheduled_time DESC LIMIT 5;

SELECT COUNT(*) FROM RENTALS_DB.SILVER.BOOKINGS_CDC;                   -- 5005
SELECT SYSTEM$STREAM_HAS_DATA('RENTALS_DB.SILVER.BOOKINGS_STREAM');    -- FALSE after the merge

-- 6. Suspend when not demoing, so the schedule doesn't wake the warehouse
-- ALTER TASK RENTALS_DB.SILVER.MERGE_BOOKINGS_CDC SUSPEND;

