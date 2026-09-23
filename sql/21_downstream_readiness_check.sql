-- ============================================================
-- 21_downstream_readiness_check.sql
-- Purpose: Validate the complete Analytical Summary Layer before export.
-- Scope: SQL -> Python -> Power BI downstream readiness.
-- This script is read-only and does not modify any table.
-- ============================================================

USE ecommerce_analytics;

-- 1. Confirm all nine analytical tables exist.
SELECT
    table_name,
    table_rows
FROM information_schema.tables
WHERE table_schema = 'ecommerce_analytics'
AND table_name IN (
    'sales_performance',
    'category_performance',
    'product_performance',
    'product_economics',
    'customer_performance',
    'customer_summary',
    'seller_performance',
    'payment_performance',
    'delivery_review'
)
ORDER BY FIELD(
    table_name,
    'sales_performance',
    'category_performance',
    'product_performance',
    'product_economics',
    'customer_performance',
    'customer_summary',
    'seller_performance',
    'payment_performance',
    'delivery_review'
);

-- 2. Validate the common time dimension used by monthly analytical tables.
SELECT
    'sales_performance' AS table_name,
    COUNT(*) AS rows_count,
    MIN(month_period) AS first_month,
    MAX(month_period) AS last_month,
    COUNT(DISTINCT year) AS years,
    COUNT(DISTINCT month_period) AS months
FROM sales_performance
UNION ALL
SELECT
    'category_performance',
    COUNT(*),
    MIN(month_period),
    MAX(month_period),
    COUNT(DISTINCT year),
    COUNT(DISTINCT month_period)
FROM category_performance
UNION ALL
SELECT
    'product_performance',
    COUNT(*),
    MIN(month_period),
    MAX(month_period),
    COUNT(DISTINCT year),
    COUNT(DISTINCT month_period)
FROM product_performance
UNION ALL
SELECT
    'customer_performance',
    COUNT(*),
    MIN(month_period),
    MAX(month_period),
    COUNT(DISTINCT year),
    COUNT(DISTINCT month_period)
FROM customer_performance
UNION ALL
SELECT
    'seller_performance',
    COUNT(*),
    MIN(month_period),
    MAX(month_period),
    COUNT(DISTINCT year),
    COUNT(DISTINCT month_period)
FROM seller_performance
UNION ALL
SELECT
    'payment_performance',
    COUNT(*),
    MIN(month_period),
    MAX(month_period),
    COUNT(DISTINCT year),
    COUNT(DISTINCT month_period)
FROM payment_performance
UNION ALL
SELECT
    'delivery_review',
    COUNT(*),
    MIN(month_period),
    MAX(month_period),
    COUNT(DISTINCT year),
    COUNT(DISTINCT month_period)
FROM delivery_review;

-- 3. Check that the main financial metrics reconcile across analytical layers.
SELECT
    'fact_sales' AS source_table,
    SUM(price) AS revenue,
    SUM(cost) AS total_cost,
    SUM(gross_profit) AS gross_profit,
    COUNT(*) AS units
FROM fact_sales
UNION ALL
SELECT
    'sales_performance',
    SUM(revenue),
    NULL,
    NULL,
    NULL
FROM sales_performance
UNION ALL
SELECT
    'category_performance',
    SUM(revenue),
    NULL,
    NULL,
    SUM(units_sold)
FROM category_performance
UNION ALL
SELECT
    'product_performance',
    SUM(revenue),
    NULL,
    SUM(gross_profit),
    SUM(units_sold)
FROM product_performance
UNION ALL
SELECT
    'product_economics',
    SUM(revenue),
    SUM(total_cost),
    SUM(gross_profit),
    SUM(units_sold)
FROM product_economics
UNION ALL
SELECT
    'customer_performance',
    SUM(revenue),
    NULL,
    NULL,
    NULL
FROM customer_performance
UNION ALL
SELECT
    'customer_summary',
    SUM(revenue),
    NULL,
    NULL,
    SUM(units_sold)
FROM customer_summary
UNION ALL
SELECT
    'seller_performance',
    SUM(revenue),
    NULL,
    NULL,
    SUM(units_sold)
FROM seller_performance;

-- 4. Validate core customer, product and seller coverage.
SELECT
    (SELECT COUNT(DISTINCT customer_unique_id) FROM fact_sales) AS fact_customers,
    (SELECT COUNT(*) FROM customer_summary) AS summary_customers,
    (SELECT COUNT(DISTINCT product_id) FROM fact_sales) AS fact_products,
    (SELECT COUNT(*) FROM product_economics) AS summary_products,
    (SELECT COUNT(DISTINCT seller_id) FROM fact_sales) AS fact_sellers,
    (SELECT COUNT(DISTINCT seller_id) FROM seller_performance) AS summary_sellers;

-- 5. Validate review and payment reconciliation.
SELECT
    (SELECT COUNT(*) FROM fact_delivery_review) AS fact_review_rows,
    (SELECT SUM(orders) FROM delivery_review) AS summary_review_orders,
    (SELECT SUM(late_orders) FROM delivery_review) AS summary_late_orders,
    (SELECT SUM(payment_value) FROM fact_payment) AS fact_payment_value,
    (SELECT SUM(payment_value) FROM payment_performance) AS summary_payment_value;

-- 6. Check NULLs in critical analytical fields.
SELECT
    'sales_performance' AS table_name,
    SUM(CASE WHEN month_period IS NULL THEN 1 ELSE 0 END) AS null_month,
    SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END) AS null_revenue
FROM sales_performance
UNION ALL
SELECT
    'category_performance',
    SUM(CASE WHEN month_period IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END)
FROM category_performance
UNION ALL
SELECT
    'product_performance',
    SUM(CASE WHEN month_period IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END)
FROM product_performance
UNION ALL
SELECT
    'customer_performance',
    SUM(CASE WHEN month_period IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END)
FROM customer_performance
UNION ALL
SELECT
    'seller_performance',
    SUM(CASE WHEN month_period IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN revenue IS NULL THEN 0 ELSE 1 END)
FROM seller_performance;


-- Add month_start_date to all monthly analytical tables.
ALTER TABLE sales_performance
ADD COLUMN month_start_date DATE;

ALTER TABLE category_performance
ADD COLUMN month_start_date DATE;

ALTER TABLE product_performance
ADD COLUMN month_start_date DATE;

ALTER TABLE customer_performance
ADD COLUMN month_start_date DATE;

ALTER TABLE seller_performance
ADD COLUMN month_start_date DATE;

ALTER TABLE payment_performance
ADD COLUMN month_start_date DATE;

ALTER TABLE delivery_review
ADD COLUMN month_start_date DATE;

-- Populate month_start_date from the existing month_period field.
UPDATE sales_performance
SET month_start_date = STR_TO_DATE(CONCAT(month_period, '-01'), '%Y-%m-%d');

UPDATE category_performance
SET month_start_date = STR_TO_DATE(CONCAT(month_period, '-01'), '%Y-%m-%d');

UPDATE product_performance
SET month_start_date = STR_TO_DATE(CONCAT(month_period, '-01'), '%Y-%m-%d');

UPDATE customer_performance
SET month_start_date = STR_TO_DATE(CONCAT(month_period, '-01'), '%Y-%m-%d');

UPDATE seller_performance
SET month_start_date = STR_TO_DATE(CONCAT(month_period, '-01'), '%Y-%m-%d');

UPDATE payment_performance
SET month_start_date = STR_TO_DATE(CONCAT(month_period, '-01'), '%Y-%m-%d');

UPDATE delivery_review
SET month_start_date = STR_TO_DATE(CONCAT(month_period, '-01'), '%Y-%m-%d');

-- ============================================================
-- Validate month_start_date across all monthly analytical tables.
-- Expected result: NULL count = 0 and correct 2019-01-01 to 2025-12-01 range.
-- ============================================================

SELECT
    'sales_performance' AS table_name,
    COUNT(*) AS rows_count,
    SUM(CASE WHEN month_start_date IS NULL THEN 1 ELSE 0 END) AS null_dates,
    MIN(month_start_date) AS first_month,
    MAX(month_start_date) AS last_month
FROM sales_performance
UNION ALL
SELECT
    'category_performance',
    COUNT(*),
    SUM(CASE WHEN month_start_date IS NULL THEN 1 ELSE 0 END),
    MIN(month_start_date),
    MAX(month_start_date)
FROM category_performance
UNION ALL
SELECT
    'product_performance',
    COUNT(*),
    SUM(CASE WHEN month_start_date IS NULL THEN 1 ELSE 0 END),
    MIN(month_start_date),
    MAX(month_start_date)
FROM product_performance
UNION ALL
SELECT
    'customer_performance',
    COUNT(*),
    SUM(CASE WHEN month_start_date IS NULL THEN 1 ELSE 0 END),
    MIN(month_start_date),
    MAX(month_start_date)
FROM customer_performance
UNION ALL
SELECT
    'seller_performance',
    COUNT(*),
    SUM(CASE WHEN month_start_date IS NULL THEN 1 ELSE 0 END),
    MIN(month_start_date),
    MAX(month_start_date)
FROM seller_performance
UNION ALL
SELECT
    'payment_performance',
    COUNT(*),
    SUM(CASE WHEN month_start_date IS NULL THEN 1 ELSE 0 END),
    MIN(month_start_date),
    MAX(month_start_date)
FROM payment_performance
UNION ALL
SELECT
    'delivery_review',
    COUNT(*),
    SUM(CASE WHEN month_start_date IS NULL THEN 1 ELSE 0 END),
    MIN(month_start_date),
    MAX(month_start_date)
FROM delivery_review;

-- ============================================================
-- export_readiness_check.sql
-- Purpose: Final validation before exporting analytical data.
-- Scope: SQL -> Python -> Power BI.
-- This script is read-only and does not modify any table.
-- ============================================================


-- 1. Validate analytical table row counts and time coverage.
SELECT
    'sales_performance' AS table_name,
    COUNT(*) AS rows_count,
    MIN(month_start_date) AS first_month,
    MAX(month_start_date) AS last_month
FROM sales_performance
UNION ALL
SELECT
    'category_performance',
    COUNT(*),
    MIN(month_start_date),
    MAX(month_start_date)
FROM category_performance
UNION ALL
SELECT
    'product_performance',
    COUNT(*),
    MIN(month_start_date),
    MAX(month_start_date)
FROM product_performance
UNION ALL
SELECT
    'product_economics',
    COUNT(*),
    NULL,
    NULL
FROM product_economics
UNION ALL
SELECT
    'customer_performance',
    COUNT(*),
    MIN(month_start_date),
    MAX(month_start_date)
FROM customer_performance
UNION ALL
SELECT
    'customer_summary',
    COUNT(*),
    NULL,
    NULL
FROM customer_summary
UNION ALL
SELECT
    'seller_performance',
    COUNT(*),
    MIN(month_start_date),
    MAX(month_start_date)
FROM seller_performance
UNION ALL
SELECT
    'payment_performance',
    COUNT(*),
    MIN(month_start_date),
    MAX(month_start_date)
FROM payment_performance
UNION ALL
SELECT
    'delivery_review',
    COUNT(*),
    MIN(month_start_date),
    MAX(month_start_date)
FROM delivery_review;

-- 2. Confirm the main financial metrics still reconcile.
SELECT
    'Revenue' AS metric,
    (SELECT SUM(price) FROM fact_sales) AS fact_value,
    (SELECT SUM(revenue) FROM sales_performance) AS summary_value,
    (SELECT SUM(price) FROM fact_sales) -
    (SELECT SUM(revenue) FROM sales_performance) AS difference
UNION ALL
SELECT
    'Cost',
    (SELECT SUM(cost) FROM fact_sales),
    (SELECT SUM(total_cost) FROM product_economics),
    (SELECT SUM(cost) FROM fact_sales) -
    (SELECT SUM(total_cost) FROM product_economics)
UNION ALL
SELECT
    'Gross Profit',
    (SELECT SUM(gross_profit) FROM fact_sales),
    (SELECT SUM(gross_profit) FROM product_economics),
    (SELECT SUM(gross_profit) FROM fact_sales) -
    (SELECT SUM(gross_profit) FROM product_economics)
UNION ALL
SELECT
    'Units',
    (SELECT COUNT(*) FROM fact_sales),
    (SELECT SUM(units_sold) FROM product_economics),
    (SELECT COUNT(*) FROM fact_sales) -
    (SELECT SUM(units_sold) FROM product_economics);

-- 3. Confirm customer, product and seller coverage.
SELECT
    'Customers' AS entity,
    (SELECT COUNT(DISTINCT customer_unique_id) FROM fact_sales) AS fact_count,
    (SELECT COUNT(*) FROM customer_summary) AS summary_count
UNION ALL
SELECT
    'Products',
    (SELECT COUNT(DISTINCT product_id) FROM fact_sales),
    (SELECT COUNT(*) FROM product_economics)
UNION ALL
SELECT
    'Sellers',
    (SELECT COUNT(DISTINCT seller_id) FROM fact_sales),
    (SELECT COUNT(DISTINCT seller_id) FROM seller_performance);

-- 4. Confirm payment and review reconciliation.
SELECT
    'Payment Value' AS metric,
    (SELECT SUM(payment_value) FROM fact_payment) AS fact_value,
    (SELECT SUM(payment_value) FROM payment_performance) AS summary_value,
    (SELECT SUM(payment_value) FROM fact_payment) -
    (SELECT SUM(payment_value) FROM payment_performance) AS difference
UNION ALL
SELECT
    'Review Orders',
    (SELECT COUNT(*) FROM fact_delivery_review),
    (SELECT SUM(orders) FROM delivery_review),
    (SELECT COUNT(*) FROM fact_delivery_review) -
    (SELECT SUM(orders) FROM delivery_review);

-- 5. Confirm all monthly tables have complete 84-month coverage.
SELECT
    table_name,
    month_count
FROM (
    SELECT 'sales_performance' AS table_name, COUNT(DISTINCT month_start_date) AS month_count
    FROM sales_performance
    UNION ALL
    SELECT 'category_performance', COUNT(DISTINCT month_start_date)
    FROM category_performance
    UNION ALL
    SELECT 'product_performance', COUNT(DISTINCT month_start_date)
    FROM product_performance
    UNION ALL
    SELECT 'customer_performance', COUNT(DISTINCT month_start_date)
    FROM customer_performance
    UNION ALL
    SELECT 'seller_performance', COUNT(DISTINCT month_start_date)
    FROM seller_performance
    UNION ALL
    SELECT 'payment_performance', COUNT(DISTINCT month_start_date)
    FROM payment_performance
    UNION ALL
    SELECT 'delivery_review', COUNT(DISTINCT month_start_date)
    FROM delivery_review
) AS coverage_check
WHERE month_count <> 84;

-- 6. Corrected NULL check for seller_performance.
SELECT
    'seller_performance' AS table_name,
    SUM(CASE WHEN month_start_date IS NULL THEN 1 ELSE 0 END) AS null_month,
    SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END) AS null_revenue
FROM seller_performance;

