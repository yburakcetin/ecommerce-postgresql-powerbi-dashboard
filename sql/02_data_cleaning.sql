-- =====================================================
-- Ecommerce SQL Data Cleaning Portfolio Project
-- PostgreSQL Version
-- =====================================================
-- Goal:
-- Clean raw ecommerce order data and create an analysis-ready table.
--
-- Cleaning workflow:
-- 1. Copy raw data into a staging table
-- 2. Trim text fields and standardize text case
-- 3. Convert blank values and fake NULL values into real NULLs
-- 4. Remove duplicate records
-- 5. Standardize country, product name, product category, and customer segment values
-- 6. Standardize product names
-- 7. Remove currency, comma, and percentage symbols from numeric text fields
-- 8. Convert text columns into correct PostgreSQL data types
-- 9. Remove rows missing critical business fields
-- 10. Create calculated fields and validate sales calculations
-- 11. Run final quality checks
-- =====================================================


-- This schema groups the project tables together.
CREATE SCHEMA IF NOT EXISTS ecommerce_portfolio_project;
SET search_path TO ecommerce_portfolio_project;

-- =====================================================
-- 1. Create staging table from raw data
-- =====================================================
-- Staging keeps all imported values as text so dirty values can be inspected
-- before converting columns to final data types.

DROP TABLE IF EXISTS ecommerce_staging;

CREATE TABLE ecommerce_staging (
    row_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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

INSERT INTO ecommerce_staging (
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
    sales_amount,
    order_date
)
SELECT
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
    sales_amount,
    order_date
FROM ecommerce_raw;

-- Confirm that all raw rows were copied into staging.
SELECT 'ecommerce_raw' AS table_name,
       COUNT(*) AS row_count
FROM ecommerce_raw

UNION ALL

SELECT 'ecommerce_staging' AS table_name,
       COUNT(*) AS row_count
FROM ecommerce_staging;

-- =====================================================
-- 2. Trim whitespace and standardize text case
-- =====================================================
-- TRIM removes extra spaces.
-- LOWER/UPPER makes later grouping and standardization more reliable.

UPDATE ecommerce_staging
SET
    order_id = UPPER(TRIM(order_id)),
    customer_name = INITCAP(TRIM(customer_name)),
    product_name = INITCAP(TRIM(product_name)),
    product_category = INITCAP(TRIM(product_category)),
    customer_segment = INITCAP(TRIM(customer_segment)),
    country = INITCAP(TRIM(country)),
    quantity = TRIM(quantity),
    unit_price = TRIM(unit_price),
    discount_percentage = TRIM(discount_percentage),
    shipping_fee = TRIM(shipping_fee),
    sales_amount = TRIM(sales_amount),
    order_date = TRIM(order_date);

-- Preview standardized staging rows.
SELECT *
FROM ecommerce_staging
LIMIT 100;

-- =====================================================
-- 3. Convert blanks and fake NULL values to real NULLs
-- =====================================================
-- Fake missing values such as '', 'null', 'unknown', and 'not available'
-- must become real SQL NULL values before type conversion.

-- Inspect frequent customer_name values to identify fake missing labels.
SELECT
    customer_name,
    COUNT(*) AS row_count
FROM ecommerce_staging
GROUP BY customer_name
ORDER BY row_count DESC;

UPDATE ecommerce_staging SET order_id = NULL WHERE order_id IN ('', 'NULL');
UPDATE ecommerce_staging SET customer_name = NULL WHERE LOWER(customer_name) IN ('', 'null', 'unknown');
UPDATE ecommerce_staging SET product_name = NULL WHERE LOWER(product_name) IN ('', 'null');
UPDATE ecommerce_staging SET product_category = NULL WHERE LOWER(product_category) IN ('', 'null');
UPDATE ecommerce_staging SET customer_segment = NULL WHERE LOWER(customer_segment) IN ('', 'null');
UPDATE ecommerce_staging SET country = NULL WHERE LOWER(country) IN ('', 'null');
UPDATE ecommerce_staging SET quantity = NULL WHERE LOWER(quantity) IN ('', 'null');
UPDATE ecommerce_staging SET unit_price = NULL WHERE LOWER(unit_price) IN ('', 'null');
UPDATE ecommerce_staging SET discount_percentage = NULL WHERE LOWER(discount_percentage) IN ('', 'null');
UPDATE ecommerce_staging SET shipping_fee = NULL WHERE LOWER(shipping_fee) IN ('', 'null');
UPDATE ecommerce_staging SET sales_amount = NULL WHERE LOWER(sales_amount) IN ('', 'null');
UPDATE ecommerce_staging SET order_date = NULL WHERE LOWER(order_date) IN ('', 'null', 'not available');

-- Verify that fake missing values were removed.
SELECT
    COUNT(*) FILTER (WHERE order_id IN ('', 'NULL')) AS bad_order_id,
    COUNT(*) FILTER (WHERE LOWER(customer_name) IN ('', 'null', 'unknown')) AS bad_customer_name,
    COUNT(*) FILTER (WHERE LOWER(product_name) IN ('', 'null')) AS bad_product_name,
    COUNT(*) FILTER (WHERE LOWER(product_category) IN ('', 'null')) AS bad_product_category,
    COUNT(*) FILTER (WHERE LOWER(customer_segment) IN ('', 'null')) AS bad_customer_segment,
    COUNT(*) FILTER (WHERE LOWER(country) IN ('', 'null')) AS bad_country,
    COUNT(*) FILTER (WHERE LOWER(quantity) IN ('', 'null')) AS bad_quantity,
    COUNT(*) FILTER (WHERE LOWER(unit_price) IN ('', 'null')) AS bad_unit_price,
    COUNT(*) FILTER (WHERE LOWER(discount_percentage) IN ('', 'null')) AS bad_discount_percentage,
    COUNT(*) FILTER (WHERE LOWER(shipping_fee) IN ('', 'null')) AS bad_shipping_fee,
    COUNT(*) FILTER (WHERE LOWER(sales_amount) IN ('', 'null')) AS bad_sales_amount,
    COUNT(*) FILTER (WHERE LOWER(order_date) IN ('', 'null', 'not available')) AS bad_order_date
FROM ecommerce_staging;

-- =====================================================
-- 4. Remove duplicate rows
-- =====================================================
-- Duplicate detection ignores row_id because row_id is only a staging identifier.
-- ROW_NUMBER keeps the first loaded version of each duplicated business record.

DROP TABLE IF EXISTS ecommerce_deduped;

CREATE TABLE ecommerce_deduped AS
SELECT
    row_id,
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
    sales_amount,
    order_date
FROM (
    SELECT
        es.*,
        ROW_NUMBER() OVER (
            PARTITION BY
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
                sales_amount,
                order_date
            ORDER BY row_id
        ) AS row_num
    FROM ecommerce_staging AS es
) AS ranked
WHERE row_num = 1;

-- Count how many duplicate rows were removed.
SELECT
    (SELECT COUNT(*) FROM ecommerce_staging) AS before_duplicate_removal,
    (SELECT COUNT(*) FROM ecommerce_deduped) AS after_duplicate_removal,
    (SELECT COUNT(*) FROM ecommerce_staging) - (SELECT COUNT(*) FROM ecommerce_deduped)
        AS duplicate_rows_removed;

-- =====================================================
-- 5. Standardize country values
-- =====================================================
-- Different spellings and abbreviations are mapped to one country name.

-- Verify country values.
SELECT
    country,
    COUNT(*) AS row_count
FROM ecommerce_deduped
GROUP BY country
ORDER BY country;

UPDATE ecommerce_deduped
SET country = CASE
    WHEN LOWER(country) IN ('usa', 'u.s.', 'us', 'united states', 'united states.') THEN 'United States'
    WHEN LOWER(country) IN ('uk', 'u.k.', 'great britain', 'united kingdom', 'united kingdom.') THEN 'United Kingdom'
    WHEN LOWER(country) IN ('türkiye', 'turkiye', 'turkey', 'turkey.', 'tr') THEN 'Turkey'
    WHEN LOWER(country) IN ('germany', 'germany.', 'de', 'deutschland') THEN 'Germany'
    WHEN LOWER(country) IN ('france', 'france.', 'fr') THEN 'France'
    WHEN LOWER(country) IN ('canada', 'canada.', 'ca') THEN 'Canada'
    WHEN LOWER(country) IN ('australia', 'australia.', 'au') THEN 'Australia'
    WHEN LOWER(country) IN ('india', 'india.', 'in') THEN 'India'
    WHEN LOWER(country) IN ('brasil', 'brazil', 'brazil.', 'br') THEN 'Brazil'
    WHEN LOWER(country) IN ('the netherlands', 'netherlands', 'netherlands.', 'nl') THEN 'Netherlands'
    ELSE country
END
WHERE country IS NOT NULL;


-- =====================================================
-- 6. Standardize product name values
-- =====================================================
-- Product variants are mapped to one reporting label so dashboard rankings
-- do not split the same product into multiple bars.

-- Verify product names before standardization.
SELECT
    product_name,
    COUNT(*) AS row_count
FROM ecommerce_deduped
GROUP BY product_name
ORDER BY product_name;

UPDATE ecommerce_deduped
SET product_name = CASE
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('air fryer') THEN 'Air Fryer'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('atomic habits') THEN 'Atomic Habits'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('blender', 'kitchen blender') THEN 'Blender'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('blocks set', 'building blocks set') THEN 'Building Blocks Set'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('book shelf', 'bookshelf') THEN 'Bookshelf'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('ceramic mug set', 'mug set') THEN 'Mug Set'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('coffee table') THEN 'Coffee Table'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('cotton t-shirt', 'cotton tshirt') THEN 'Cotton T-Shirt'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('denim jeans', 'jeans') THEN 'Denim Jeans'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('dumbbell set', 'dumbbells') THEN 'Dumbbell Set'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('face serum', 'facial serum') THEN 'Facial Serum'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('football', 'soccer ball') THEN 'Football'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('galaxy s23', 'samsung galaxy s23') THEN 'Samsung Galaxy S23'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('gaming mouse') THEN 'Gaming Mouse'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('hair dryer', 'hairdryer') THEN 'Hair Dryer'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('iphone 14', 'iphone14') THEN 'iPhone 14'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('laptop stand') THEN 'Laptop Stand'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('mech keyboard', 'mechanical keyboard') THEN 'Mechanical Keyboard'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('men sneakers', 'men''s sneakers', 'mens sneakers') THEN 'Men''s Sneakers'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('office chair') THEN 'Office Chair'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('rc car', 'remote control car') THEN 'Remote Control Car'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('run shoes', 'running shoes') THEN 'Running Shoes'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('sofa cover') THEN 'Sofa Cover'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('sony headphones', 'sony wh-1000xm5 headphones', 'wh-1000xm5 headphones') THEN 'Sony WH-1000XM5 Headphones'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('sql data analysis', 'sql for data analysis') THEN 'SQL for Data Analysis'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('standing desk') THEN 'Standing Desk'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('sunscreen', 'sunscreen spf 50') THEN 'Sunscreen SPF 50'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('usb c charger', 'usb-c charger') THEN 'USB-C Charger'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('women jacket', 'women''s jacket', 'womens jacket') THEN 'Women''s Jacket'
    WHEN LOWER(REGEXP_REPLACE(product_name, '\s+', ' ', 'g')) IN ('yoga mat') THEN 'Yoga Mat'
    ELSE REGEXP_REPLACE(product_name, '\s+', ' ', 'g')
END
WHERE product_name IS NOT NULL;

-- Verify product names after standardization.
SELECT
    product_name,
    COUNT(*) AS row_count
FROM ecommerce_deduped
GROUP BY product_name
ORDER BY product_name;


-- =====================================================
-- 7. Standardize product category values
-- =====================================================
-- Product categories are grouped into consistent business labels.


-- Verify product categories.
SELECT
    product_category,
    COUNT(*) AS row_count
FROM ecommerce_deduped
GROUP BY product_category
ORDER BY product_category;

UPDATE ecommerce_deduped
SET product_category = CASE
    WHEN LOWER(product_category) IN ('electronic', 'electronics') THEN 'Electronics'
    WHEN LOWER(product_category) IN ('furniture', 'furnitures') THEN 'Furniture'
    WHEN LOWER(product_category) IN ('home and kitchen', 'home & kitchen', 'kitchen') THEN 'Home & Kitchen'
    WHEN LOWER(product_category) IN ('sports', 'sport') THEN 'Sports'
    WHEN LOWER(product_category) IN ('apparel', 'clothes', 'clothing', 'fashion') THEN 'Clothing'
    WHEN LOWER(product_category) IN ('beauty', 'beauty & personal care', 'personal care') THEN 'Beauty'
    WHEN LOWER(product_category) IN ('books', 'book') THEN 'Books'
    WHEN LOWER(product_category) IN ('toys', 'toy') THEN 'Toys'
    ELSE product_category
END
WHERE product_category IS NOT NULL;


-- =====================================================
-- 8. Standardize customer segment values
-- =====================================================
-- Segment variants are mapped to a smaller set of reporting labels.

-- Verify customer segments.
SELECT
    customer_segment,
    COUNT(*) AS row_count
FROM ecommerce_deduped
GROUP BY customer_segment
ORDER BY customer_segment;

UPDATE ecommerce_deduped
SET customer_segment = CASE
    WHEN LOWER(customer_segment) IN ('consumer', 'consumers') THEN 'Consumer'
    WHEN LOWER(customer_segment) IN ('corporate', 'corp') THEN 'Corporate'
    WHEN LOWER(customer_segment) IN ('home office', 'home-office') THEN 'Home Office'
    WHEN LOWER(customer_segment) IN ('small business', 'smb', 'small biz') THEN 'Small Business'
    ELSE customer_segment
END
WHERE customer_segment IS NOT NULL;

-- =====================================================
-- 9. Clean numeric text fields
-- =====================================================
-- Remove symbols before casting text values into numeric data types.
-- Examples: '$1,200.50' -> '1200.50', '15%' -> '15'

SELECT
    unit_price,
    shipping_fee,
    sales_amount,
    discount_percentage
FROM ecommerce_deduped
LIMIT 100;

UPDATE ecommerce_deduped
SET unit_price = REGEXP_REPLACE(unit_price, '[$,]', '', 'g')
WHERE unit_price IS NOT NULL;

UPDATE ecommerce_deduped
SET shipping_fee = REGEXP_REPLACE(shipping_fee, '[$,]', '', 'g')
WHERE shipping_fee IS NOT NULL;

UPDATE ecommerce_deduped
SET sales_amount = REGEXP_REPLACE(sales_amount, '[$,]', '', 'g')
WHERE sales_amount IS NOT NULL;

UPDATE ecommerce_deduped
SET discount_percentage = REPLACE(discount_percentage, '%', '')
WHERE discount_percentage IS NOT NULL;

-- =====================================================
-- 10. Create clean table with proper PostgreSQL data types
-- =====================================================
-- Business rules:
-- - quantity must be a positive integer
-- - unit_price and sales_amount must be positive numeric values
-- - shipping_fee must be zero or positive
-- - discount_percentage accepts either decimal format, such as 0.15,
--   or percent format, such as 15, and stores both as decimal format
-- - order_date accepts YYYY-MM-DD, MM/DD/YYYY, and MM-DD-YYYY

DROP TABLE IF EXISTS ecommerce_clean;

CREATE TABLE ecommerce_clean AS
SELECT
    row_id AS source_row_id,
    order_id,
    customer_name,
    product_name,
    product_category,
    customer_segment,
    country,

    -- Convert only valid positive whole numbers into INTEGER.
    CASE
        WHEN quantity ~ '^[0-9]+$' AND quantity::INTEGER > 0
        THEN quantity::INTEGER
        ELSE NULL
    END AS quantity,

    -- Convert only valid positive prices into NUMERIC(10,2).
    CASE
        WHEN unit_price ~ '^[+-]?[0-9]+([.][0-9]+)?$' AND unit_price::NUMERIC > 0
        THEN unit_price::NUMERIC(10,2)
        ELSE NULL
    END AS unit_price,

    -- Store discounts as decimals: 15 becomes 0.15, while 0.15 stays 0.15.
    CASE
        WHEN discount_percentage ~ '^[+-]?[0-9]+([.][0-9]+)?$'
             AND discount_percentage::NUMERIC BETWEEN 0 AND 1
        THEN discount_percentage::NUMERIC(5,2)
        WHEN discount_percentage ~ '^[+-]?[0-9]+([.][0-9]+)?$'
             AND discount_percentage::NUMERIC > 1
             AND discount_percentage::NUMERIC <= 100
        THEN ROUND((discount_percentage::NUMERIC / 100), 2)::NUMERIC(5,2)
        ELSE 0
    END AS discount_percentage,

    -- Convert only zero or positive shipping fees into NUMERIC(10,2).
    CASE
        WHEN shipping_fee ~ '^[+-]?[0-9]+([.][0-9]+)?$' AND shipping_fee::NUMERIC >= 0
        THEN shipping_fee::NUMERIC(10,2)
        ELSE NULL
    END AS shipping_fee,

    -- Convert only valid positive sales values into NUMERIC(10,2).
    CASE
        WHEN sales_amount ~ '^[+-]?[0-9]+([.][0-9]+)?$' AND sales_amount::NUMERIC > 0
        THEN sales_amount::NUMERIC(10,2)
        ELSE NULL
    END AS sales_amount,

    -- Parse three common date formats and reject invalid calendar dates.
    CASE
        WHEN order_date ~ '^[0-9]{4}-(0[1-9]|1[0-2])-([0][1-9]|[12][0-9]|3[01])$'
             AND TO_CHAR(TO_DATE(order_date, 'YYYY-MM-DD'), 'YYYY-MM-DD') = order_date
        THEN TO_DATE(order_date, 'YYYY-MM-DD')

        WHEN order_date ~ '^(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])/[0-9]{4}$'
             AND TO_CHAR(TO_DATE(order_date, 'MM/DD/YYYY'), 'YYYY-MM-DD') =
                 split_part(order_date, '/', 3) || '-' ||
                 LPAD(split_part(order_date, '/', 1), 2, '0') || '-' ||
                 LPAD(split_part(order_date, '/', 2), 2, '0')
        THEN TO_DATE(order_date, 'MM/DD/YYYY')

        WHEN order_date ~ '^(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])-[0-9]{4}$'
             AND TO_CHAR(TO_DATE(order_date, 'MM-DD-YYYY'), 'YYYY-MM-DD') =
                 split_part(order_date, '-', 3) || '-' ||
                 LPAD(split_part(order_date, '-', 1), 2, '0') || '-' ||
                 LPAD(split_part(order_date, '-', 2), 2, '0')
        THEN TO_DATE(order_date, 'MM-DD-YYYY')

        ELSE NULL
    END AS order_date
FROM ecommerce_deduped;






-- Preview before-and-after values for type conversion checks.
SELECT
    d.quantity AS before_quantity,
    c.quantity AS after_quantity,
    d.unit_price AS before_unit_price,
    c.unit_price AS after_unit_price,
    d.discount_percentage AS before_discount_percentage,
    c.discount_percentage AS after_discount_percentage,
    d.shipping_fee AS before_shipping_fee,
    c.shipping_fee AS after_shipping_fee,
    d.sales_amount AS before_sales_amount,
    c.sales_amount AS after_sales_amount,
    d.order_date AS before_order_date,
    c.order_date AS after_order_date
FROM ecommerce_deduped AS d
LEFT JOIN ecommerce_clean AS c
    ON d.row_id = c.source_row_id
LIMIT 100;

-- =====================================================
-- 11. Remove rows missing critical fields
-- =====================================================
-- Critical fields are required for order-level revenue analysis.
-- discount_percentage and shipping_fee are optional and can remain NULL.

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE customer_name IS NULL) AS missing_customer_name,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS missing_quantity,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS missing_unit_price,
    COUNT(*) FILTER (WHERE sales_amount IS NULL) AS missing_sales_amount,
    COUNT(*) FILTER (WHERE order_date IS NULL) AS missing_order_date
FROM ecommerce_clean;

DELETE FROM ecommerce_clean
WHERE order_id IS NULL
   OR customer_name IS NULL
   OR quantity IS NULL
   OR unit_price IS NULL
   OR sales_amount IS NULL
   OR order_date IS NULL;

-- Count the total row reduction from original staging to the current clean table.
-- This includes duplicate removal and critical-field removal.
SELECT
    (SELECT COUNT(*) FROM ecommerce_staging) AS original_staging_rows,
    (SELECT COUNT(*) FROM ecommerce_clean) AS current_clean_rows,
    (SELECT COUNT(*) FROM ecommerce_staging) - (SELECT COUNT(*) FROM ecommerce_clean) AS total_rows_removed_so_far;

-- =====================================================
-- 12. Add calculated columns
-- =====================================================
-- gross_sales stores quantity * unit_price before discount and shipping.
-- expected_sales is temporary and is used to validate sales_amount.

ALTER TABLE ecommerce_clean
ADD COLUMN gross_sales NUMERIC(10,2),
ADD COLUMN expected_sales NUMERIC(10,2);

UPDATE ecommerce_clean
SET gross_sales = ROUND((quantity * unit_price)::NUMERIC, 2);

UPDATE ecommerce_clean
SET expected_sales = ROUND(
    (quantity * unit_price * (1 - COALESCE(discount_percentage, 0)) + COALESCE(shipping_fee, 0))::NUMERIC,
    2
);

-- =====================================================
-- 13. Validate and correct sales_amount
-- =====================================================
-- A row is considered different when sales_amount and expected_sales
-- differ by more than 0.01.

SELECT
    COUNT(*) AS discrepant_rows,
    ROUND(AVG(ABS(sales_amount - expected_sales)), 2) AS average_difference
FROM ecommerce_clean
WHERE sales_amount IS NOT NULL
  AND expected_sales IS NOT NULL
  AND ABS(sales_amount - expected_sales) > 0.01;

-- Preview rows that will be corrected.
SELECT
    sales_amount,
    expected_sales,
    ABS(sales_amount - expected_sales) AS difference
FROM ecommerce_clean
WHERE sales_amount IS NOT NULL
  AND expected_sales IS NOT NULL
  AND ABS(sales_amount - expected_sales) > 0.01
LIMIT 20;

-- Replace inconsistent sales_amount values with the calculated value.
UPDATE ecommerce_clean
SET sales_amount = expected_sales
WHERE sales_amount IS NOT NULL
  AND expected_sales IS NOT NULL
  AND ABS(sales_amount - expected_sales) > 0.01;

-- Confirm that no calculation discrepancies remain.
SELECT COUNT(*) AS remaining_discrepancies
FROM ecommerce_clean
WHERE sales_amount IS NOT NULL
  AND expected_sales IS NOT NULL
  AND ABS(sales_amount - expected_sales) > 0.01;

-- Remove the temporary validation column after correcting sales_amount.
ALTER TABLE ecommerce_clean
DROP COLUMN expected_sales;


-- =====================================================
-- 14. Final verification and business summary
-- =====================================================
-- These checks confirm row count, date range, customer count, product count,
-- total revenue, and average order value after cleaning.

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
LIMIT 100;

SELECT COUNT(*) AS final_row_count
FROM ecommerce_clean;

SELECT
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_name) AS unique_customers,
    COUNT(DISTINCT product_name) AS unique_products,
    ROUND(SUM(sales_amount), 2) AS total_revenue,
    ROUND(AVG(sales_amount), 2) AS average_order_value
FROM ecommerce_clean;

-- =====================================================
-- 15. Final data quality summary
-- =====================================================
-- Shows the share of optional missing fields and the sales value range.

SELECT
    COUNT(*) AS total_rows,
    ROUND(
        COUNT(*) FILTER (WHERE discount_percentage IS NULL)::NUMERIC / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS pct_no_discount,
    ROUND(
        COUNT(*) FILTER (WHERE shipping_fee IS NULL)::NUMERIC / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS pct_no_shipping,
    ROUND(MIN(sales_amount), 2) AS min_order_value,
    ROUND(MAX(sales_amount), 2) AS max_order_value
FROM ecommerce_clean;
