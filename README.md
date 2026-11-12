

## Performance: query tuning results

All timings come from `EXPLAIN ANALYZE` in PostgreSQL 17, running in Docker on a
GitHub Codespace (4 cores, 16 GB RAM). `fact_sales` has 558,799 rows.
Each query was run 3 times; the table shows the **median**.

| # | Query | Before | After | Change | Speed-up |
|---|-------|--------|-------|--------|----------|
| 1 | Look up a car's sales by VIN | 25.819 ms (Parallel Seq Scan) | 0.059 ms (Index Scan) | B-tree index on `fact_sales(vin)` | ~440× |
| 2 | Monthly sales and average price per make (dashboard summary) | 194.964 ms (aggregates all 558,799 rows) | 0.094 ms (reads 436 precomputed rows) | Materialized view `analytics.mv_monthly_make_sales` | ~2,070× |

**Why it worked:** without an index, PostgreSQL read all ~558,800 rows to find one VIN.
With a B-tree index, it jumps straight to the matching row.

**How "before" was measured:** the index was kept, and index scans were switched off
for that session only (`SET enable_indexscan = off; SET enable_bitmapscan = off;`),
so both runs use the same data and the same query.

**Raw `EXPLAIN ANALYZE` output (proof):**
- [Before: sequential scan](docs/perf/01_vin_lookup_before.txt)
- [After: index scan](docs/perf/01_vin_lookup_after.txt)
- Index definition: [`sql/04_indexes.sql`](sql/04_indexes.sql)

### Materialized view trade-off

- The materialized view stores **436 rows** (one per make per month) instead of
  re-aggregating 558,799 sales on every dashboard load.
- It must be refreshed when new data arrives:
  `REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.mv_monthly_make_sales;`
  took **181 ms** (single run). The heavy calculation is paid once per refresh,
  not once per dashboard view.
- A unique index on `(month, make)` makes `CONCURRENTLY` possible, so dashboards
  can keep reading while it refreshes.

**Raw `EXPLAIN ANALYZE` output (proof):**
- [Before: full aggregation](docs/perf/02_monthly_summary_before.txt)
- [After: read from materialized view](docs/perf/02_monthly_summary_after.txt)
- Definition: [`sql/05_materialized_views.sql`](sql/05_materialized_views.sql)

## Superset dashboard

![Vehicle Sales Overview dashboard](docs/images/dashboard.png)

Dashboard, charts and datasets exported from Superset: [`superset/exports/`](superset/exports/)
(import via Superset → Dashboards → Import).
