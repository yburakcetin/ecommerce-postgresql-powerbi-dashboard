-- =====================================================
-- Ecommerce SQL Portfolio Project
-- PostgreSQL Database Setup and Raw Data Import
-- PostgreSQL / pgAdmin 4
-- =====================================================
-- PURPOSE:
-- 1. Create the project schema
-- 2. Create the raw source table
-- 3. Import the dirty CSV file into ecommerce_raw
--
-- IMPORTANT:
-- Keep ecommerce_raw unchanged. All cleaning work should happen
-- in staging and clean tables created by 02_data_cleaning.sql.
-- =====================================================

-- PostgreSQL uses schemas to organize objects inside a database.
-- Create a database manually first if you want a separate database,
-- for example: ecommerce_portfolio_project

CREATE SCHEMA IF NOT EXISTS ecommerce_portfolio_project;
SET search_path TO ecommerce_portfolio_project;

-- =====================================================
-- 1. Create raw source table
-- =====================================================
-- All columns are stored as VARCHAR because the source file is dirty.
-- Numeric and date fields are converted later during data cleaning.

DROP TABLE IF EXISTS ecommerce_raw;

CREATE TABLE ecommerce_raw (
    order_id VARCHAR(255),
    customer_name VARCHAR(255),
    product_name VARCHAR(255),
    product_category VARCHAR(255),
    customer_segment VARCHAR(255),
    country VARCHAR(255),
    quantity VARCHAR(255),
    unit_price VARCHAR(255),
    discount_percentage VARCHAR(255),
    shipping_fee VARCHAR(255),
    sales_amount VARCHAR(255),
    order_date VARCHAR(255)
);

-- =====================================================
-- 2. Import CSV data
-- =====================================================
-- OPTION A: Import with pgAdmin Import/Export Data
--
-- 1. In pgAdmin, open your database.
-- 2. Open Schemas > ecommerce_portfolio_project > Tables.
-- 3. Right-click ecommerce_raw.
-- 4. Choose Import/Export Data.
-- 5. Select ecommerce_portfolio_dirty_dataset.csv.
-- 6. Set Format to CSV.
-- 7. Turn Header on.
-- 8. Confirm delimiter is comma.
-- 9. Run the import.
--
-- OPTION B: Import with psql \copy
--
-- Run this from the psql terminal, not inside pgAdmin Query Tool.
-- Update the file path if your project folder is different.

-- \copy ecommerce_portfolio_project.ecommerce_raw (
--     order_id,
--     customer_name,
--     product_name,
--     product_category,
--     customer_segment,
--     country,
--     quantity,
--     unit_price,
--     discount_percentage,
--     shipping_fee,
--     sales_amount,
--     order_date
-- )
-- FROM 'C:/Users/PC/Desktop/Ecommerce SQL Data Cleaning Project/ecommerce_portfolio_dirty_dataset.csv'
-- WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"');

-- =====================================================
-- 3. Verify raw import
-- =====================================================

SELECT COUNT(*) AS raw_row_count
FROM ecommerce_raw;

SELECT *
FROM ecommerce_raw
LIMIT 10;

SELECT
    COUNT(*) AS total_rows,
    COUNT(order_id) AS non_null_order_ids,
    COUNT(customer_name) AS non_null_customer_names,
    COUNT(order_date) AS non_null_order_dates
FROM ecommerce_raw;
