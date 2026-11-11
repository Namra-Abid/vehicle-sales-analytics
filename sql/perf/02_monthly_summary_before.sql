-- Monthly sales per make, calculated from all 558k rows every time
EXPLAIN ANALYZE
SELECT date_trunc('month', f.sale_date)::date      AS month,
       v.make,
       count(*)                                     AS sales,
       round(avg(f.selling_price))                  AS avg_price,
       round(avg(f.selling_price - f.mmr))          AS avg_diff_vs_market
FROM analytics.fact_sales f
JOIN analytics.dim_vehicle v USING (vehicle_id)
GROUP BY 1, 2;
