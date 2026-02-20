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

