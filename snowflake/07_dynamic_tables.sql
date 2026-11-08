-- 07_dynamic_tables.sql
-- Self-refreshing Gold summary: daily confirmed revenue by city.
-- Snowflake keeps it within TARGET_LAG of its sources; no dbt run or task needed.
-- Built on the CDC table (06) so new Snowpipe files flow through automatically.

USE ROLE TRANSFORMER;
USE WAREHOUSE ELT_WH;

CREATE OR REPLACE DYNAMIC TABLE RENTALS_DB.GOLD.DAILY_REVENUE_BY_CITY
  TARGET_LAG = '15 minutes'
  WAREHOUSE = ELT_WH
  REFRESH_MODE = AUTO
AS
SELECT
  b.booking_date,
  l.city,
  l.country,
  COUNT(*)            AS confirmed_bookings,
  SUM(b.total_amount) AS revenue
FROM RENTALS_DB.SILVER.BOOKINGS_CDC b
JOIN RENTALS_DB.SILVER.SILVER_LISTINGS l
  ON b.listing_id = l.listing_id
WHERE b.booking_status = 'confirmed'
GROUP BY b.booking_date, l.city, l.country;

-- Check: definition, lag and refresh mode
SHOW DYNAMIC TABLES LIKE 'DAILY_REVENUE_BY_CITY' IN SCHEMA RENTALS_DB.GOLD;

-- Refresh history
SELECT name, state, refresh_action, refresh_trigger, data_timestamp, state_message
FROM TABLE(RENTALS_DB.INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
  NAME => 'RENTALS_DB.GOLD.DAILY_REVENUE_BY_CITY'))
ORDER BY data_timestamp DESC LIMIT 5;

-- Result
SELECT * FROM RENTALS_DB.GOLD.DAILY_REVENUE_BY_CITY
ORDER BY booking_date DESC, revenue DESC LIMIT 10;

-- Suspend when not demoing, so refreshes don't wake the warehouse
-- ALTER DYNAMIC TABLE RENTALS_DB.GOLD.DAILY_REVENUE_BY_CITY SUSPEND;