# Sales Staging ETL — `sp_SalesDataDump`

## Purpose

Populates a rolling, incremental **staging fact table** (`SA_SalesDataDump`) that unifies sales invoices and sales returns from multiple source tables into a single, analysis-ready grain: **one row per invoice-line / product / batch**.

This table is the single source of truth feeding:
- 4 downstream pre-aggregated fact tables (see [`../02-fact-aggregation`](../02-fact-aggregation))
- An SSAS OLAP cube
- Multiple Power BI dashboards

## Why a staging layer exists

Rather than have every downstream report or cube query the live transactional tables (`SaleInvoice`, `SaleInvoiceDetail`, `SaleInvoiceReturn`, ...), this procedure pre-joins and pre-shapes the data once per run into a flat, denormalized table. This:

- Avoids repeating a ~15-table join across every downstream consumer
- Gives Power BI and the SSAS cube a stable, query-friendly schema
- Makes incremental refresh cheap — only the current delivery window is touched

## How it works

1. **Incremental window**: `@DeliveryDateFrom` / `@DeliveryDateTo` are derived from the current date, covering month-to-date. The procedure deletes existing rows in that window and re-inserts, making it safely re-runnable (idempotent) for the current period.
2. **Three UNION ALL branches**, each representing a different transaction shape:
   - **Sales** — settled invoices with `NetAmount > 0.9` (filters out zero/near-zero noise rows)
   - **Matched returns** — returns linked back to an original sale invoice
   - **Unmatched returns** — returns with no matching sale invoice (e.g. return-only transactions), inserted with reversed signs
3. **Discount proration**: Promotional discounts are captured at the invoice level but need to be spread across product lines. This is done via a **ratio-based allocation**:
   ```
   line_discount = invoice_level_discount × (line_pieces / invoice_total_pieces)
   ```
   This ensures each product line carries its fair share of bill-level discounts rather than double-counting or dropping them.
4. **Discount categorization**: A `Tags`-driven `CASE WHEN` pattern buckets each promotion into named discount types (rental discounts, wholesale discounts, loyalty-program discounts, trade-offer discounts, off-invoice discounts, etc.) so downstream reports can break down *why* a sale was discounted, not just *how much*.

## Engineering notes

- Column and discount-category names in this script have been **anonymized/genericized** for public portfolio use (e.g. `RentalDiscount`, `WholesaleDiscount`, `TradeOfferDiscount`) — the original production version uses client-specific promotion naming. Logic and structure are otherwise unchanged.
- Sign-flipping (`* -1`) on the return branches lets the fact table be summed directly without needing separate sales/return handling downstream.
- Scheduled to run on an incremental daily basis via SQL Agent.

## File

- [`sp_SalesDataDump.sql`](./sp_SalesDataDump.sql)
