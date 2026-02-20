# Data Quality Rules

## Integrity Checks
- **Claims → Policies referential integrity**
  - 0 claims without a matching policy_id in dim_policy.
- **Unique keys**
  - claim_id unique in fact_claim
  - policy_id unique in dim_policy

## Validity Checks
- **Coverage window validity**
  - incident_date must be within [effective_date, expiration_date].
- **Coverage threshold**
  - loss_amount <= coverage_limit

## Reconciliation Checks
- **Payments reconcile to loss**
  - ROUND(SUM(payment_amount),2) == ROUND(loss_amount,2)

## Remediation Strategy (Documented)
- If a validation fails:
  - Identify whether issue is due to keying/join logic (dimension duplicates) vs. true business exception
  - Correct deterministic key generation and rebuild dimensions
  - Ensure financial splits reconcile (adjust last payment to eliminate rounding drift)