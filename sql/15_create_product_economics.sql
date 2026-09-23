-- ============================================================
-- 15_create_product_economics.sql
-- Purpose: Create overall product-level economic performance.
-- Grain: One row per product across the full analysis period.
-- Source: fact_sales.
-- Business Rule: Use realized sales and cost from fact_sales.
-- This avoids confusing product master price/cost with actual sales performance.
-- ============================================================

USE ecommerce_analytics;

DROP TABLE IF EXISTS product_economics;

CREATE TABLE product_economics (
    product_id VARCHAR(100) NOT NULL,
    product_name VARCHAR(255),
    category VARCHAR(255),
    brand VARCHAR(255),
    units_sold INT NOT NULL,
    revenue DECIMAL(18,2),
    total_cost DECIMAL(18,2),
    gross_profit DECIMAL(18,2),
    avg_selling_price DECIMAL(18,2),
    avg_unit_cost DECIMAL(18,2),
    gross_margin_pct DECIMAL(10,4),
    PRIMARY KEY (product_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Aggregate realized sales and cost at product level.
INSERT INTO product_economics (
    product_id,
    product_name,
    category,
    brand,
    units_sold,
    revenue,
    total_cost,
    gross_profit,
    avg_selling_price,
    avg_unit_cost,
    gross_margin_pct
)
SELECT
    product_id,
    MAX(product_name) AS product_name,
    MAX(category) AS category,
    MAX(brand) AS brand,
    COUNT(*) AS units_sold,
    SUM(price) AS revenue,
    SUM(cost) AS total_cost,
    SUM(gross_profit) AS gross_profit,
    AVG(price) AS avg_selling_price,
    AVG(cost) AS avg_unit_cost,
    CASE
        WHEN SUM(price) <> 0
        THEN SUM(gross_profit) / SUM(price)
        ELSE NULL
    END AS gross_margin_pct
FROM fact_sales
GROUP BY product_id;

-- Validate product-level economic performance.
SELECT
    COUNT(*) AS products,
    SUM(units_sold) AS total_units,
    SUM(revenue) AS total_revenue,
    SUM(total_cost) AS total_cost,
    SUM(gross_profit) AS total_gross_profit,
    MIN(gross_margin_pct) AS min_margin,
    MAX(gross_margin_pct) AS max_margin
FROM product_economics;

-- Confirm that each product appears exactly once.
SELECT
    product_id,
    COUNT(*) AS row_count
FROM product_economics
GROUP BY product_id
HAVING COUNT(*) > 1
LIMIT 20;