# insurance-data-integration

Enterprise-style insurance data integration & mapping project using DuckDB SQL, Source-to-Target Mapping (STTM), and data quality validation.

## Dataset
Uses the **Allstate Claims Severity** Kaggle dataset (`train.csv`) as the claims source.
- id → claim_id
- loss → loss_amount
- cat*/cont* → risk attributes

## What this project simulates
A simplified insurance enterprise environment:
- Policy Administration (policy_master)
- Coverage (policy_coverage)
- Claims (claims_enriched)
- Claim payments (claim_payments)
- Target warehouse model (dim_policy, fact_claim, fact_claim_payment)
- Data profiling + validation + reconciliation checks

## Repo Structure
- `insurance_dw/` : DuckDB database + raw CSVs
- `sql/` : load, transformation, and reconciliation scripts
- `mappings/` : Source-to-Target Mapping (STTM) documents to document transformation logic, business definitions, and validation rules.
- `docs/` : business rules, lineage, and DQ rules

## How to run (from repo root)
1) Install DuckDB:
```bash
brew install duckdb
```
2) Run Makefile:
```bash
make build
make dq
```
## Key Data Quality Controls
- Claims must map to a valid policy (referential integrity)
- Claim incident date must fall within policy coverage window
- Sum of payments must reconcile to loss amount (rounded to cents)
- Loss must not exceed coverage limit (or be flagged)
- Dimension keys are unique (prevents incorrect joins)

