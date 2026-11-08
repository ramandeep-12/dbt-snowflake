-- 08_masking_policy.sql
-- Masks host names (PII) for everyone except TRANSFORMER.
-- The policy lives in a separate GOVERNANCE schema, owned by an admin role;
-- dbt (TRANSFORMER) can only APPLY it, not change it.
-- Requires Snowflake Enterprise edition.

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE ELT_WH;

-- 1. Governance schema for policies
CREATE SCHEMA IF NOT EXISTS RENTALS_DB.GOVERNANCE;

-- 2. Masking policy: real value for TRANSFORMER (and admins above it), masked otherwise
CREATE OR REPLACE MASKING POLICY RENTALS_DB.GOVERNANCE.PII_NAME_MASK
  AS (val STRING) RETURNS STRING ->
  CASE
    WHEN IS_ROLE_IN_SESSION('TRANSFORMER') THEN val
    ELSE LEFT(val, 1) || '*****'
  END
  COMMENT = 'Masks personal names for non-engineering roles';

-- 3. Let dbt attach the policy to the tables it builds
GRANT USAGE ON SCHEMA RENTALS_DB.GOVERNANCE TO ROLE TRANSFORMER;
GRANT APPLY ON MASKING POLICY RENTALS_DB.GOVERNANCE.PII_NAME_MASK TO ROLE TRANSFORMER;

-- 4. Verify after dbt build: same query, two roles
USE ROLE TRANSFORMER;
USE SECONDARY ROLES NONE;
SELECT host_id, host_name FROM RENTALS_DB.GOLD.OBT LIMIT 5;      -- real names

USE ROLE ANALYST;
USE SECONDARY ROLES NONE;
SELECT host_id, host_name FROM RENTALS_DB.GOLD.OBT LIMIT 5;      -- masked
SELECT host_id, host_name FROM RENTALS_DB.GOLD.DIM_HOST LIMIT 5; -- masked

-- 5. See where the policy is attached
USE ROLE ACCOUNTADMIN;
SELECT * FROM TABLE(RENTALS_DB.INFORMATION_SCHEMA.POLICY_REFERENCES(
  POLICY_NAME => 'RENTALS_DB.GOVERNANCE.PII_NAME_MASK'));