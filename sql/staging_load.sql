-- sql/staging_load.sql
-- Run from repo root:
-- duckdb insurance_dw/insurance.duckdb < sql/staging_load.sql

-- 1) Raw claims source (Allstate train.csv)
CREATE OR REPLACE TABLE claims_raw AS
SELECT * FROM read_csv_auto('insurance_dw/train.csv');

-- 2) Enriched claims table to simulate an enterprise claims system
-- Adds: claim_id, policy_id, dates, and claim_status
CREATE OR REPLACE TABLE claims_enriched AS
SELECT
  CAST(id AS VARCHAR) AS claim_id,
  (id % 50000)::VARCHAR AS policy_id,
  loss AS loss_amount,
  DATE '2025-01-01' + (id % 365) * INTERVAL '1 day' AS incident_date,
  DATE '2025-01-01' + (id % 365) * INTERVAL '1 day' + (id % 30) * INTERVAL '1 day' AS reported_date,
  CASE (id % 5)
    WHEN 0 THEN 'OPEN'
    WHEN 1 THEN 'IN_REVIEW'
    WHEN 2 THEN 'APPROVED'
    WHEN 3 THEN 'PAID'
    ELSE 'CLOSED'
  END AS claim_status,
  * EXCLUDE (id, loss)
FROM claims_raw;

-- Quick sanity checks
-- SELECT COUNT(*) AS n_claims FROM claims_raw;
-- SELECT COUNT(*) AS n_claims_enriched FROM claims_enriched;