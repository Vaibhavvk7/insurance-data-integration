# Data Lineage

## Source
- `insurance_dw/train.csv` (Allstate Claims Severity)
  - id → claim_id
  - loss → loss_amount
  - cat*/cont* → risk attributes (kept as-is)

## Staging / Source-System Simulation
- `claims_raw` ← train.csv
- `claims_enriched` ← claims_raw + derived fields (policy_id, incident_date, reported_date, claim_status)
- `policy_master` ← derived per policy_id using min/max incident_date windows (ensures coverage validity)
- `policy_coverage` ← policy_master + max observed loss per policy (sets realistic coverage_limit)
- `claim_payments` ← claims_enriched (1–3 payments; reconciles exactly to loss_amount)

## Target Warehouse
- `dim_policy` ← policy_master
- `fact_claim` ← claims_enriched
- `fact_claim_payment` ← claim_payments

## Data Quality Validation Layer
- `sql/reconciliation_checks.sql` validates:
  - referential integrity
  - coverage window validity
  - payment reconciliation
  - coverage threshold
  - uniqueness constraints