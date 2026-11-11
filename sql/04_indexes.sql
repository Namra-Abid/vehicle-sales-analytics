-- Speeds up looking up sales by a car's VIN (B-tree index, the default type)
CREATE INDEX IF NOT EXISTS idx_fact_sales_vin ON analytics.fact_sales (vin);
