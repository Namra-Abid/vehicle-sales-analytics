-- Build clean star-schema tables from raw.car_prices.
-- BEGIN...COMMIT = all or nothing: if anything fails, nothing is half-built.
BEGIN;

-- A separate folder (schema) for the clean tables
CREATE SCHEMA IF NOT EXISTS analytics;

-- Start fresh if this script is run again (fact first, because it points to the others)
DROP TABLE IF EXISTS analytics.fact_sales;
DROP TABLE IF EXISTS analytics.dim_vehicle;
DROP TABLE IF EXISTS analytics.dim_seller;

-- 1. A temporary cleaned copy of the raw data (disappears when the script ends)
CREATE TEMP TABLE clean_sales AS
SELECT
    year::int                                                   AS model_year,
    COALESCE(NULLIF(upper(btrim(make)), ''), 'UNKNOWN')         AS make,
    COALESCE(NULLIF(btrim(model), ''), 'unknown')               AS model,
    COALESCE(NULLIF(btrim("trim"), ''), 'unknown')              AS trim_level,
    COALESCE(NULLIF(lower(btrim(body)), ''), 'unknown')         AS body_type,
    COALESCE(NULLIF(lower(btrim(transmission)), ''), 'unknown') AS transmission,
    COALESCE(NULLIF(lower(btrim(seller)), ''), 'unknown')       AS seller_name,
    lower(btrim(vin))                                           AS vin,
    upper(btrim(state))                                         AS state,
    CASE WHEN condition ~ '^\d+(\.\d+)?$' THEN condition::numeric END AS condition,
    CASE WHEN odometer  ~ '^\d+$'         THEN odometer::int      END AS odometer,
    NULLIF(NULLIF(lower(btrim(color)), ''), '—')                AS color,
    NULLIF(NULLIF(lower(btrim(interior)), ''), '—')             AS interior,
    CASE WHEN mmr ~ '^\d+(\.\d+)?$' THEN round(mmr::numeric)::int END AS mmr,
    sellingprice::int                                           AS selling_price,
    to_date(substr(saledate, 5, 11), 'Mon DD YYYY')             AS sale_date
FROM raw.car_prices
-- keep only rows whose key columns look valid (skips the broken, shifted rows)
WHERE year ~ '^\d{4}$'
  AND sellingprice ~ '^\d+$'
  AND saledate ~ '^[A-Z][a-z]{2} [A-Z][a-z]{2} \d{2} \d{4}';

-- 2. Dimension: each unique car type, stored once
CREATE TABLE analytics.dim_vehicle (
    vehicle_id   serial PRIMARY KEY,
    model_year   int  NOT NULL,
    make         text NOT NULL,
    model        text NOT NULL,
    trim_level   text NOT NULL,
    body_type    text NOT NULL,
    transmission text NOT NULL,
    UNIQUE (model_year, make, model, trim_level, body_type, transmission)
);

INSERT INTO analytics.dim_vehicle (model_year, make, model, trim_level, body_type, transmission)
SELECT DISTINCT model_year, make, model, trim_level, body_type, transmission
FROM clean_sales;

-- 3. Dimension: each unique seller, stored once
CREATE TABLE analytics.dim_seller (
    seller_id   serial PRIMARY KEY,
    seller_name text NOT NULL UNIQUE
);

INSERT INTO analytics.dim_seller (seller_name)
SELECT DISTINCT seller_name
FROM clean_sales;

-- 4. Fact: one row per sale, pointing to its vehicle and seller by ID
--    (No extra indexes on purpose: we add them in the performance step.)
CREATE TABLE analytics.fact_sales (
    sale_id       bigserial PRIMARY KEY,
    vehicle_id    int  NOT NULL REFERENCES analytics.dim_vehicle,
    seller_id     int  NOT NULL REFERENCES analytics.dim_seller,
    sale_date     date NOT NULL,
    state         text,
    vin           text,
    condition     numeric,
    odometer      int,
    color         text,
    interior      text,
    mmr           int,
    selling_price int  NOT NULL
);

INSERT INTO analytics.fact_sales
    (vehicle_id, seller_id, sale_date, state, vin, condition,
     odometer, color, interior, mmr, selling_price)
SELECT v.vehicle_id, s.seller_id, c.sale_date, c.state, c.vin, c.condition,
       c.odometer, c.color, c.interior, c.mmr, c.selling_price
FROM clean_sales c
JOIN analytics.dim_vehicle v
  USING (model_year, make, model, trim_level, body_type, transmission)
JOIN analytics.dim_seller s
  USING (seller_name);

COMMIT;

-- Update Postgres's statistics about the new tables (helps it plan queries well)
ANALYZE analytics.dim_vehicle;
ANALYZE analytics.dim_seller;
ANALYZE analytics.fact_sales;
