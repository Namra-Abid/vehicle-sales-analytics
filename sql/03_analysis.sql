\echo '=== Q1: Top 10 makes by number of sales ==='
SELECT v.make,
       count(*)                     AS sales,
       round(avg(f.selling_price))  AS avg_price
FROM analytics.fact_sales f
JOIN analytics.dim_vehicle v USING (vehicle_id)
GROUP BY v.make
ORDER BY sales DESC
LIMIT 10;

\echo '=== Q2: Selling price vs market value (MMR), makes with 1000+ sales ==='
SELECT v.make,
       count(*)                                                     AS sales,
       round(avg(f.selling_price - f.mmr))                          AS avg_diff_vs_market,
       round(100.0 * avg(f.selling_price - f.mmr) / avg(f.mmr), 1)  AS pct_vs_market
FROM analytics.fact_sales f
JOIN analytics.dim_vehicle v USING (vehicle_id)
WHERE f.mmr > 0
GROUP BY v.make
HAVING count(*) >= 1000
ORDER BY pct_vs_market
LIMIT 10;

\echo '=== Q3: Sales and average price per month ==='
SELECT date_trunc('month', f.sale_date)::date  AS month,
       count(*)                                AS sales,
       round(avg(f.selling_price))             AS avg_price
FROM analytics.fact_sales f
GROUP BY 1
ORDER BY 1;
