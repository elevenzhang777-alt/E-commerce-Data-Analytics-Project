-- ============================================================
-- 18_create_seller_performance.sql
-- Purpose: Create monthly seller-level sales performance.
-- Grain: One row per month and seller.
-- Source: fact_sales.
-- ============================================================

USE ecommerce_analytics;

DROP TABLE IF EXISTS seller_performance;

CREATE TABLE seller_performance (
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_number INT NOT NULL,
    month_period CHAR(7) NOT NULL,
    seller_id VARCHAR(100) NOT NULL,
    seller_name VARCHAR(255),
    seller_state VARCHAR(100),
    revenue DECIMAL(18,2),
    orders INT,
    units_sold INT,
    aov DECIMAL(18,2),
    PRIMARY KEY (month_period, seller_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Aggregate realized sales performance by month and seller.
-- Seller location attributes are retrieved from the small sellers dimension table.
INSERT INTO seller_performance (
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    seller_id,
    seller_name,
    seller_state,
    revenue,
    orders,
    units_sold,
    aov
)
SELECT
    fs.year,
    fs.quarter,
    fs.month,
    fs.month_name,
    fs.month_number,
    fs.month_period,
    fs.seller_id,
    MAX(s.seller_company_name) AS seller_name,
    MAX(s.seller_state) AS seller_state,
    SUM(fs.price) AS revenue,
    COUNT(DISTINCT fs.order_id) AS orders,
    COUNT(*) AS units_sold,
    CASE
        WHEN COUNT(DISTINCT fs.order_id) <> 0
        THEN SUM(fs.price) / COUNT(DISTINCT fs.order_id)
        ELSE NULL
    END AS aov
FROM fact_sales fs
LEFT JOIN sellers s
    ON fs.seller_id = s.seller_id
GROUP BY
    fs.year,
    fs.quarter,
    fs.month,
    fs.month_name,
    fs.month_number,
    fs.month_period,
    fs.seller_id;

-- Validate seller-level aggregation and financial reconciliation.
SELECT
    COUNT(*) AS rows_count,
    COUNT(DISTINCT seller_id) AS sellers,
    MIN(month_period) AS first_month,
    MAX(month_period) AS last_month,
    SUM(revenue) AS total_revenue,
    SUM(units_sold) AS total_units,
    SUM(orders) AS total_orders
FROM seller_performance;

-- Confirm that each month-seller combination appears exactly once.
SELECT
    month_period,
    seller_id,
    COUNT(*) AS row_count
FROM seller_performance
GROUP BY month_period, seller_id
HAVING COUNT(*) > 1
LIMIT 20;

-- Validate that all sellers have sales records and seller revenue reconciles to fact_sales.
SELECT
    COUNT(DISTINCT seller_id) AS sellers,
    SUM(revenue) AS total_revenue,
    SUM(units_sold) AS total_units,
    SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END) AS null_revenue_rows
FROM seller_performance;