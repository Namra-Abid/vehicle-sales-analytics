

## Performance: query tuning results

All timings come from `EXPLAIN ANALYZE` in PostgreSQL 17, running in Docker on a
GitHub Codespace (4 cores, 16 GB RAM). `fact_sales` has 558,799 rows.
Each query was run 3 times; the table shows the **median**.

| # | Query | Before | After | Change | Speed-up |
|---|-------|--------|-------|--------|----------|
| 1 | Look up a car's sales by VIN | 25.819 ms (Parallel Seq Scan) | 0.059 ms (Index Scan) | B-tree index on `fact_sales(vin)` | ~440× |

**Why it worked:** without an index, PostgreSQL read all ~558,800 rows to find one VIN.
With a B-tree index, it jumps straight to the matching row.

**How "before" was measured:** the index was kept, and index scans were switched off
for that session only (`SET enable_indexscan = off; SET enable_bitmapscan = off;`),
so both runs use the same data and the same query.

**Raw `EXPLAIN ANALYZE` output (proof):**
- [Before: sequential scan](docs/perf/01_vin_lookup_before.txt)
- [After: index scan](docs/perf/01_vin_lookup_after.txt)
- Index definition: [`sql/04_indexes.sql`](sql/04_indexes.sql)
