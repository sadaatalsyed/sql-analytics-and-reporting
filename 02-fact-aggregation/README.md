# Multi-Grain Fact Aggregation

## Purpose

Four stored procedures that each pre-aggregate the staging table (`SA_SalesDataDump`, see [`../01-staging-etl`](../01-staging-etl)) to a **different reporting grain**, feeding Power BI dashboards and an SSAS cube directly.

| Procedure | Grain | Extra dimensions joined |
|---|---|---|
| [`sp_fact_overall.sql`](./sp_fact_overall.sql) | Distribution × OrderBooker | Region hierarchy, Channel |
| [`sp_fact_brand.sql`](./sp_fact_brand.sql) | + Brand | Type, Category, Brand |
| [`sp_fact_sku.sql`](./sp_fact_sku.sql) | + full SKU | Type, Category, Brand, Segment, Variant |
| [`sp_fact_sku_segment.sql`](./sp_fact_sku_segment.sql) | Segment (no OrderBooker) | Type, Category, Brand, Segment |

## Why four tables instead of one

This is a deliberate performance/scalability trade-off rather than duplication:

- Power BI dashboards and cube measures rarely need the lowest grain (individual SKU) for every visual — a regional summary chart querying a **small, pre-aggregated table** is far faster than aggregating millions of staging rows live.
- Each table is sized to the questions it answers: an "Overall performance by distributor" dashboard hits `SA_OB_Overall` (small, fast); a "SKU-level discount leakage" report hits `SA_OB_SKU` (larger, but only when that depth is actually needed).
- This mirrors the classic **star-schema fact-table-per-grain** pattern used in enterprise data warehousing, applied here at the stored-procedure level rather than through a dedicated ETL tool.

## Shared pattern across all four

Each procedure follows the same shape:

1. Delete existing rows for the current month/year (idempotent re-run for the current period)
2. Join the staging table to dimension tables (`Distribution`, `Product`, `Customer`, hierarchy levels, `Brand`/`Category`/`Segment`/`Variant` as relevant to the grain)
3. Aggregate volume (pieces, cases, kg, tons), value (net amount, tax), and all discount categories
4. Filter to settled sales (`NetAmount > 0.9`) plus all returns, so returns always net against sales regardless of settlement status
5. Insert into the grain-specific fact table with a `[Month]`/`[Year]` stamp for fast time-based filtering downstream

## Engineering notes

- Discount category columns (`RentalDiscount`, `WholesaleDiscount`, `LoyaltyProgramDiscount`, `TradeOfferDiscount`, off-invoice discount types) are anonymized/genericized from client-specific promotion names — logic is unchanged.
- Unit conversions (pieces → cases via `UnitPerCarton`, pieces → kg/tons via `UnitWeight` and `TonnageFactor`) are computed consistently across all four procedures so downstream reports never show conflicting totals depending on which grain they query.
- All four are scheduled to run back-to-back immediately after the staging load completes.
