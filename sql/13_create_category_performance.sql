-- ============================================================
-- 13_create_category_performance.sql
-- Purpose: Create monthly category-level sales performance.
-- Grain: One row per month and product category.
-- Source: fact_sales only.
-- ============================================================

USE ecommerce_analytics;

DROP TABLE IF EXISTS category_performance;

CREATE TABLE category_performance (
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_number INT NOT NULL,
    month_period CHAR(7) NOT NULL,
    category VARCHAR(255),
    revenue DECIMAL(18,2),
    orders INT,
    units_sold INT,
    aov DECIMAL(18,2),
    PRIMARY KEY (month_period, category)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Aggregate sales by month and product category.
INSERT INTO category_performance (
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    category,
    revenue,
    orders,
    units_sold,
    aov
)
SELECT
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    category,
    SUM(price) AS revenue,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(*) AS units_sold,
    SUM(price) / COUNT(DISTINCT order_id) AS aov
FROM fact_sales
GROUP BY
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    category;

-- Validate category-level analytical results.
SELECT
    COUNT(*) AS rows_count,
    COUNT(DISTINCT category) AS categories,
    MIN(month_period) AS first_month,
    MAX(month_period) AS last_month,
    SUM(revenue) AS total_revenue,
    SUM(units_sold) AS total_units
FROM category_performance;

-- Confirm that each month-category combination appears exactly once.
SELECT
    month_period,
    category,
    COUNT(*) AS row_count
FROM category_performance
GROUP BY month_period, category
HAVING COUNT(*) > 1
LIMIT 20;

-- Review category performance across the full analysis period.
SELECT
    month_period,
    category,
    revenue,
    orders,
    units_sold,
    aov
FROM category_performance
ORDER BY month_period, revenue DESC;