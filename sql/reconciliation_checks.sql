-- sql/reconciliation_checks.sql
-- Run:
-- duckdb insurance_dw/insurance.duckdb < sql/reconciliation_checks.sql

-- 1) Referential integrity: every claim must map to a policy
SELECT COUNT(*) AS claims_without_policy
FROM fact_claim fc
LEFT JOIN dim_policy dp ON fc.policy_id = dp.policy_id
WHERE dp.policy_id IS NULL;

-- 2) Coverage window validation: incident date must fall within policy effective/expiration
SELECT COUNT(*) AS claims_outside_coverage
FROM fact_claim fc
JOIN dim_policy dp ON fc.policy_id = dp.policy_id
WHERE fc.incident_date < dp.effective_date
   OR fc.incident_date > dp.expiration_date;

-- 3) Payment reconciliation: sum(payments) must equal loss_amount (rounded to cents)
SELECT COUNT(*) AS payment_mismatches
FROM (
  SELECT
    fc.claim_id,
    ROUND(fc.loss_amount, 2) AS loss_amount,
    ROUND(SUM(fp.payment_amount), 2) AS total_paid
  FROM fact_claim fc
  JOIN fact_claim_payment fp ON fc.claim_id = fp.claim_id
  GROUP BY 1,2
)
WHERE loss_amount <> total_paid;

-- 4) Coverage threshold rule: loss must not exceed policy coverage limit
SELECT COUNT(*) AS claims_exceeding_coverage
FROM fact_claim fc
JOIN policy_coverage pc ON fc.policy_id = pc.policy_id
WHERE fc.loss_amount > pc.coverage_limit;

-- 5) Uniqueness: claim_id unique in fact
SELECT COUNT(*) AS duplicate_claim_ids
FROM (
  SELECT claim_id, COUNT(*) c
  FROM fact_claim
  GROUP BY 1
  HAVING COUNT(*) > 1
);