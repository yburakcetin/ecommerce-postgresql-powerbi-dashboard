-- =====================================================
-- EXPORT CLEAN DATASET FOR POWER BI / GITHUB
-- PostgreSQL Version
-- =====================================================
-- Purpose:
-- Export the final cleaned table so recruiters can inspect the cleaned dataset
-- without connecting to your local PostgreSQL database.
--
-- Option 1, pgAdmin:
-- Right-click ecommerce_clean -> Import/Export Data -> Export.
-- Save as ecommerce_clean_export.csv with Header enabled.
--
-- Option 2, psql:
-- Update the file path below to match your computer, then run the command.

SET search_path TO ecommerce_portfolio_project;

-- Preview final export columns.
SELECT
    source_row_id,
    order_id,
    customer_name,
    product_name,
    product_category,
    customer_segment,
    country,
    quantity,
    unit_price,
    discount_percentage,
    shipping_fee,
    gross_sales,
    sales_amount,
    order_date
FROM ecommerce_clean
ORDER BY order_date, order_id
LIMIT 100;

-- psql export command example:
-- \copy (
--     SELECT
--         source_row_id,
--         order_id,
--         customer_name,
--         product_name,
--         product_category,
--         customer_segment,
--         country,
--         quantity,
--         unit_price,
--         discount_percentage,
--         shipping_fee,
--         gross_sales,
--         sales_amount,
--         order_date
--     FROM ecommerce_portfolio_project.ecommerce_clean
--     ORDER BY order_date, order_id
-- ) TO 'C:/Users/PC/Desktop/Ecommerce SQL Data Cleaning Project/ecommerce_clean_export.csv' WITH CSV HEADER;
