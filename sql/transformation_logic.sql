-- sql/transformation_logic.sql
-- Run:
-- duckdb insurance_dw/insurance.duckdb < sql/transformation_logic.sql

-- =========================
-- SOURCE SYSTEM SIMULATION
-- =========================

-- Policy Administration System: 1 row per policy_id, deterministic customer_id
CREATE OR REPLACE TABLE policy_master AS
WITH claim_policy AS (
  SELECT
    (id % 50000)::VARCHAR AS policy_id,
    MIN(DATE '2025-01-01' + (id % 365) * INTERVAL '1 day') AS min_incident_dt,
    MAX(DATE '2025-01-01' + (id % 365) * INTERVAL '1 day') AS max_incident_dt
  FROM claims_raw
  GROUP BY 1
)
SELECT
  policy_id,
  (CAST(policy_id AS BIGINT) % 20000)::VARCHAR AS customer_id,
  CASE (CAST(policy_id AS BIGINT) % 3)
    WHEN 0 THEN 'AUTO'
    WHEN 1 THEN 'HOME'
    ELSE 'PROPERTY'
  END AS policy_type,
  (min_incident_dt - INTERVAL '30 day')::DATE AS effective_date,
  (max_incident_dt + INTERVAL '30 day')::DATE AS expiration_date,
  ROUND(600 + (CAST(policy_id AS BIGINT) % 2400), 2) AS premium_amount,
  CASE (CAST(policy_id AS BIGINT) % 20)
    WHEN 0 THEN 'CANCELLED'
    WHEN 1 THEN 'LAPSED'
    ELSE 'ACTIVE'
  END AS policy_status
FROM claim_policy;

-- Coverage: set limit relative to observed claim severity to avoid unrealistic exceedances
CREATE OR REPLACE TABLE policy_coverage AS
WITH pol_loss AS (
  SELECT
    policy_id,
    MAX(loss_amount) AS max_loss
  FROM claims_enriched
  GROUP BY 1
)
SELECT
  'COV-' || pm.policy_id AS coverage_id,
  pm.policy_id,
  CASE (CAST(pm.policy_id AS BIGINT) % 3)
    WHEN 0 THEN 'LIABILITY'
    WHEN 1 THEN 'COLLISION'
    ELSE 'COMPREHENSIVE'
  END AS coverage_type,
  ROUND(GREATEST(25000, pl.max_loss * 1.25), 2) AS coverage_limit,
  ROUND(500 + (CAST(pm.policy_id AS BIGINT) % 5) * 250, 2) AS deductible
FROM policy_master pm
JOIN pol_loss pl ON pm.policy_id = pl.policy_id;

-- Claim payments: split loss into 1–3 payments and reconcile exactly (no rounding drift)
CREATE OR REPLACE TABLE claim_payments AS
WITH base AS (
  SELECT
    claim_id,
    ROUND(loss_amount, 2) AS loss_amount,
    incident_date,
    (CAST(claim_id AS BIGINT) % 3) + 1 AS n_payments
  FROM claims_enriched
  WHERE loss_amount IS NOT NULL
),
seq AS (
  SELECT
    b.*,
    s.i AS payment_seq
  FROM base b
  JOIN generate_series(1, 3) s(i)
    ON s.i <= b.n_payments
),
raw_alloc AS (
  SELECT
    claim_id,
    payment_seq,
    n_payments,
    loss_amount,
    incident_date,
    CASE
      WHEN n_payments = 1 THEN loss_amount
      WHEN n_payments = 2 THEN CASE WHEN payment_seq = 1 THEN loss_amount * 0.60 ELSE loss_amount * 0.40 END
      ELSE CASE
        WHEN payment_seq = 1 THEN loss_amount * 0.50
        WHEN payment_seq = 2 THEN loss_amount * 0.30
        ELSE loss_amount * 0.20
      END
    END AS alloc_amt
  FROM seq
),
rounded AS (
  SELECT
    *,
    ROUND(alloc_amt, 2) AS alloc_amt_rounded
  FROM raw_alloc
),
adjusted AS (
  SELECT
    r.*,
    CASE
      WHEN payment_seq < n_payments THEN alloc_amt_rounded
      ELSE ROUND(loss_amount - SUM(alloc_amt_rounded) OVER (
        PARTITION BY claim_id
        ORDER BY payment_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
      ), 2)
    END AS payment_amount_final
  FROM rounded r
)
SELECT
  'PMT-' || claim_id || '-' || payment_seq::VARCHAR AS payment_id,
  claim_id,
  (incident_date + payment_seq * INTERVAL '7 day')::DATE AS payment_date,
  payment_amount_final AS payment_amount,
  CASE
    WHEN payment_seq = 1 THEN 'INITIAL'
    WHEN payment_seq = 2 THEN 'SUPPLEMENTAL'
    ELSE 'FINAL'
  END AS payment_type
FROM adjusted;

-- =========================
-- WAREHOUSE MODEL (TARGET)
-- =========================

CREATE OR REPLACE TABLE dim_policy AS
SELECT
  policy_id,
  customer_id,
  policy_type,
  effective_date,
  expiration_date,
  premium_amount,
  policy_status
FROM policy_master;

CREATE OR REPLACE TABLE fact_claim AS
SELECT
  claim_id,
  policy_id,
  incident_date,
  reported_date,
  claim_status,
  loss_amount,
  CASE
    WHEN claim_status IN ('OPEN','IN_REVIEW') THEN 'OPEN'
    WHEN claim_status = 'APPROVED' THEN 'APPROVED'
    WHEN claim_status IN ('PAID','CLOSED') THEN 'SETTLED'
    ELSE 'UNKNOWN'
  END AS claim_stage,
  * EXCLUDE (claim_id, policy_id, incident_date, reported_date, claim_status, loss_amount)
FROM claims_enriched;

CREATE OR REPLACE TABLE fact_claim_payment AS
SELECT
  payment_id,
  claim_id,
  payment_date,
  payment_amount,
  payment_type
FROM claim_payments;