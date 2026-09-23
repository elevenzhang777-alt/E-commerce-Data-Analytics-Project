-- ============================================================
-- 14_create_product_performance.sql
-- Purpose: Create monthly product-level sales performance.
-- Grain: One row per month and product.
-- Source: fact_sales only.
-- ============================================================

USE ecommerce_analytics;

DROP TABLE IF EXISTS product_performance;

CREATE TABLE product_performance (
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_number INT NOT NULL,
    month_period CHAR(7) NOT NULL,
    product_id VARCHAR(100) NOT NULL,
    product_name VARCHAR(255),
    category VARCHAR(255),
    brand VARCHAR(255),
    revenue DECIMAL(18,2),
    orders INT,
    units_sold INT,
    gross_profit DECIMAL(18,2),
    gross_margin_pct DECIMAL(10,4),
    PRIMARY KEY (month_period, product_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Aggregate sales by month and product.
INSERT INTO product_performance (
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    product_id,
    product_name,
    category,
    brand,
    revenue,
    orders,
    units_sold,
    gross_profit,
    gross_margin_pct
)
SELECT
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    product_id,
    MAX(product_name) AS product_name,
    MAX(category) AS category,
    MAX(brand) AS brand,
    SUM(price) AS revenue,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(*) AS units_sold,
    SUM(gross_profit) AS gross_profit,
    CASE
        WHEN SUM(price) <> 0
        THEN SUM(gross_profit) / SUM(price)
        ELSE NULL
    END AS gross_margin_pct
FROM fact_sales
GROUP BY
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    product_id;

-- Validate product-level aggregation and financial reconciliation.
SELECT
    COUNT(*) AS rows_count,
    COUNT(DISTINCT product_id) AS products,
    MIN(month_period) AS first_month,
    MAX(month_period) AS last_month,
    SUM(revenue) AS total_revenue,
    SUM(units_sold) AS total_units,
    SUM(gross_profit) AS total_gross_profit
FROM product_performance;

-- Confirm that each month-product combination appears exactly once.
SELECT
    month_period,
    product_id,
    COUNT(*) AS row_count
FROM product_performance
GROUP BY month_period, product_id
HAVING COUNT(*) > 1
LIMIT 20;