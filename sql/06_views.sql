-- One flat view joining the star schema, for Superset charts.
-- A normal (non-materialized) view: no data is copied; it's always up to date.
CREATE OR REPLACE VIEW analytics.v_sales AS
SELECT f.sale_id,
       f.sale_date,
       v.model_year,
       v.make,
       v.model,
       v.trim_level,
       v.body_type,
       v.transmission,
       s.seller_name,
       f.state,
       f.condition,
       f.odometer,
       f.color,
       f.mmr,
       f.selling_price,
       f.selling_price - f.mmr AS price_vs_market
FROM analytics.fact_sales f
JOIN analytics.dim_vehicle v USING (vehicle_id)
JOIN analytics.dim_seller  s USING (seller_id);
