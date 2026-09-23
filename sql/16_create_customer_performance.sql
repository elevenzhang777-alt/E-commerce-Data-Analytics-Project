-- ============================================================
-- 16_create_customer_performance.sql
-- Purpose: Create monthly customer-level sales performance.
-- Grain: One row per month and customer.
-- Source: fact_sales.
-- ============================================================

USE ecommerce_analytics;

DROP TABLE IF EXISTS customer_performance;

CREATE TABLE customer_performance (
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_number INT NOT NULL,
    month_period CHAR(7) NOT NULL,
    customer_unique_id VARCHAR(100) NOT NULL,
    customer_segment VARCHAR(100),
    revenue DECIMAL(18,2),
    orders INT,
    aov DECIMAL(18,2),
    PRIMARY KEY (month_period, customer_unique_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Aggregate realized revenue and orders by month and customer.
INSERT INTO customer_performance (
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    customer_unique_id,
    customer_segment,
    revenue,
    orders,
    aov
)
SELECT
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    customer_unique_id,
    MAX(customer_segment) AS customer_segment,
    SUM(price) AS revenue,
    COUNT(DISTINCT order_id) AS orders,
    CASE
        WHEN COUNT(DISTINCT order_id) <> 0
        THEN SUM(price) / COUNT(DISTINCT order_id)
        ELSE NULL
    END AS aov
FROM fact_sales
GROUP BY
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    customer_unique_id;

-- Validate customer-level aggregation and financial reconciliation.
SELECT
    COUNT(*) AS rows_count,
    COUNT(DISTINCT customer_unique_id) AS customers,
    MIN(month_period) AS first_month,
    MAX(month_period) AS last_month,
    SUM(revenue) AS total_revenue,
    SUM(orders) AS total_orders
FROM customer_performance;

-- Confirm that each month-customer combination appears exactly once.
SELECT
    month_period,
    customer_unique_id,
    COUNT(*) AS row_count
FROM customer_performance
GROUP BY month_period, customer_unique_id
HAVING COUNT(*) > 1
LIMIT 20;