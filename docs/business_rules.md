# Business Rules (Insurance Data Integration)

## Entities
- **Policy**: coverage contract for a customer (effective_date → expiration_date)
- **Claim**: loss event tied to a policy
- **Coverage**: deductible + limit for a policy (simplified as one coverage row per policy)
- **Payment**: one or more disbursements tied to a claim

## Core Business Rules
1. **Policy-Claim Relationship**
   - Each claim must map to exactly one policy_id.
2. **Coverage Window**
   - claim.incident_date must fall within policy.effective_date and policy.expiration_date.
3. **Financial Reconciliation**
   - SUM(claim_payments.payment_amount) must equal claim.loss_amount (to the cent).
4. **Coverage Threshold**
   - claim.loss_amount should not exceed coverage.coverage_limit (flag exceptions if it does).
5. **Dimensional Integrity**
   - policy_id must be unique in the policy dimension to avoid inconsistent joins and incorrect validation.