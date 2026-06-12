-- =====================================================
-- ECOMMERCE SALES EDA
-- =====================================================

SET search_path TO ecommerce_portfolio_project;

-- Preview cleaned dataset
SELECT *
FROM ecommerce_clean;


-- =====================================================
-- 1. Sales Performance
-- =====================================================

-- Total revenue
SELECT 
    ROUND(SUM(sales_amount), 2) AS total_revenue
FROM ecommerce_clean;

-- Average order value
SELECT 
    ROUND(AVG(sales_amount), 2) AS avg_order_value
FROM ecommerce_clean;

-- Top 10 highest-value orders
SELECT *
FROM ecommerce_clean
ORDER BY sales_amount DESC
LIMIT 10;


-- =====================================================
-- 2. Customer Analysis
-- =====================================================

-- Top 10 customers by number of orders
SELECT 
    customer_name,
    COUNT(*) AS total_orders
FROM ecommerce_clean
GROUP BY customer_name
ORDER BY total_orders DESC
LIMIT 10;

-- Top 10 customers by total sales amount
SELECT 
    customer_name,
    ROUND(SUM(sales_amount), 2) AS total_sales_amount
FROM ecommerce_clean
GROUP BY customer_name
ORDER BY total_sales_amount DESC
LIMIT 10;

-- Average spend per customer
SELECT
    customer_name,
    ROUND(AVG(sales_amount), 2) AS avg_spend
FROM ecommerce_clean
GROUP BY customer_name
ORDER BY avg_spend DESC
LIMIT 10;

-- Revenue by customer segment
SELECT
    customer_segment,
    ROUND(SUM(sales_amount), 2) AS revenue
FROM ecommerce_clean
GROUP BY customer_segment
ORDER BY revenue DESC;


-- =====================================================
-- 3. Product Analysis
-- =====================================================

-- Top 10 products by revenue
SELECT
    product_name,
    ROUND(SUM(sales_amount), 2) AS revenue
FROM ecommerce_clean
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 10;

-- Top 10 products by quantity sold
SELECT
    product_name,
    SUM(quantity) AS units_sold
FROM ecommerce_clean
GROUP BY product_name
ORDER BY units_sold DESC
LIMIT 10;

-- Revenue by product category
SELECT
    product_category,
    ROUND(SUM(sales_amount), 2) AS revenue
FROM ecommerce_clean
GROUP BY product_category
ORDER BY revenue DESC;


-- =====================================================
-- 4. Geographic Analysis
-- =====================================================

-- Revenue by country
SELECT
    country,
    ROUND(SUM(sales_amount), 2) AS revenue
FROM ecommerce_clean
GROUP BY country
ORDER BY revenue DESC;

-- Number of orders by country
SELECT
    country,
    COUNT(*) AS total_orders
FROM ecommerce_clean
GROUP BY country
ORDER BY total_orders DESC;


-- =====================================================
-- 5. Discount Analysis
-- =====================================================

-- Sales performance by discount percentage
SELECT
    discount_percentage,
    COUNT(*) AS total_orders,
    ROUND(AVG(sales_amount), 2) AS avg_sales_amount
FROM ecommerce_clean
GROUP BY discount_percentage
ORDER BY discount_percentage;

-- Estimated revenue reduction from discounts
SELECT
    ROUND(SUM(gross_sales), 2) AS gross_revenue,
    ROUND(SUM(sales_amount), 2) AS net_revenue,
    ROUND(SUM(gross_sales - sales_amount), 2) AS estimated_revenue_reduction,
    ROUND((SUM(gross_sales - sales_amount) / SUM(gross_sales)) * 100, 2) AS revenue_reduction_percentage
FROM ecommerce_clean;


-- =====================================================
-- 6. Shipping Analysis
-- =====================================================

-- Average shipping fee by country
SELECT
    country,
    ROUND(AVG(shipping_fee), 2) AS avg_shipping_fee
FROM ecommerce_clean
GROUP BY country
ORDER BY avg_shipping_fee DESC;

-- Average shipping fee compared with average sales amount
SELECT
    ROUND(AVG(shipping_fee), 2) AS avg_shipping_fee,
    ROUND(AVG(sales_amount), 2) AS avg_sales_amount
FROM ecommerce_clean;


-- =====================================================
-- 7. Time Series Analysis
-- =====================================================

-- Dataset date range
SELECT 
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM ecommerce_clean;

-- Yearly revenue
SELECT
    EXTRACT(YEAR FROM order_date)::INTEGER AS order_year,
    ROUND(SUM(sales_amount), 2) AS revenue
FROM ecommerce_clean
GROUP BY order_year
ORDER BY order_year;

-- Monthly revenue
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    ROUND(SUM(sales_amount), 2) AS revenue
FROM ecommerce_clean
GROUP BY order_month
ORDER BY order_month;

-- Monthly order volume
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    COUNT(*) AS total_orders
FROM ecommerce_clean
GROUP BY order_month
ORDER BY order_month;

-- Best sales month by revenue
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    ROUND(SUM(sales_amount), 2) AS revenue
FROM ecommerce_clean
GROUP BY order_month
ORDER BY revenue DESC
LIMIT 1;

-- =====================================================
-- 8. Peak Month Drill-Down
-- =====================================================

-- Which categories drove the highest-revenue month?
SELECT
    product_category,
    ROUND(SUM(sales_amount), 2) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(sales_amount), 2) AS avg_order_value
FROM ecommerce_clean
WHERE order_date >= DATE '2023-08-01'
  AND order_date < DATE '2023-09-01'
GROUP BY product_category
ORDER BY total_revenue DESC;
