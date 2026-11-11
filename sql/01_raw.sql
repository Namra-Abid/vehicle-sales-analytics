-- 1. A folder (schema) for raw, uncleaned data
CREATE SCHEMA IF NOT EXISTS raw;

-- 2. Start fresh if this script is run again
DROP TABLE IF EXISTS raw.car_prices;

-- 3. Same columns as the CSV; all text, so messy values can't break the load
CREATE TABLE raw.car_prices (
    year          text,
    make          text,
    model         text,
    trim          text,
    body          text,
    transmission  text,
    vin           text,
    state         text,
    condition     text,
    odometer      text,
    color         text,
    interior      text,
    seller        text,
    mmr           text,
    sellingprice  text,
    saledate      text
);

-- 4. Copy all rows from the CSV file into the table
COPY raw.car_prices FROM '/data/car_prices.csv' WITH (FORMAT csv, HEADER true);
