-- 02_storage_integration_and_stage.sql
-- External stage on s3://rentals-elt-raw/raw/ (bookings/, hosts/, listings/).
-- Note: the AWS account's organization policy (SCP) blocks cross-account role
-- access, so a storage integration can't be used here. The stage uses a
-- dedicated IAM user with a read-only policy scoped to the raw/ prefix.
-- In production, use a storage integration instead of keys.
-- Never commit real keys: fill them in only in the Snowflake worksheet.

USE ROLE LOADER;
USE WAREHOUSE ELT_WH;

CREATE OR REPLACE STAGE RENTALS_DB.RAW.S3_RAW_STAGE
  URL = 's3://rentals-elt-raw/raw/'
  CREDENTIALS = (AWS_KEY_ID = '<access key id>' AWS_SECRET_KEY = '<secret access key>');

LIST @RENTALS_DB.RAW.S3_RAW_STAGE;