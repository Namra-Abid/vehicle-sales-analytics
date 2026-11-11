-- Precomputed monthly sales per make, for dashboards.
-- Refresh after new data arrives:
--   REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.mv_monthly_make_sales;
DROP MATERIALIZED VIEW IF EXISTS analytics.mv_monthly_make_sales;

CREATE MATERIALIZED VIEW analytics.mv_monthly_make_sales AS
SELECT date_trunc('month', f.sale_date)::date      AS month,
       v.make,
       count(*)                                     AS sales,
       round(avg(f.selling_price))                  AS avg_price,
       round(avg(f.selling_price - f.mmr))          AS avg_diff_vs_market
FROM analytics.fact_sales f
JOIN analytics.dim_vehicle v USING (vehicle_id)
GROUP BY 1, 2;

-- A unique index lets us refresh it without blocking readers (CONCURRENTLY)
CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_monthly_make_sales
    ON analytics.mv_monthly_make_sales (month, make);

ANALYZE analytics.mv_monthly_make_sales;
