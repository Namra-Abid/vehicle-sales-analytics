-- Same answer, read from the precomputed materialized view
EXPLAIN ANALYZE
SELECT month, make, sales, avg_price, avg_diff_vs_market
FROM analytics.mv_monthly_make_sales;
