build:
	duckdb insurance_dw/insurance.duckdb < sql/staging_load.sql
	duckdb insurance_dw/insurance.duckdb < sql/transformation_logic.sql

dq:
	duckdb insurance_dw/insurance.duckdb < sql/reconciliation_checks.sql
