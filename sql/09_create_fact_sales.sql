-- ============================================================
-- 09_create_fact_sales.sql
-- Purpose: Create the main sales fact table for downstream
-- Python analysis and Power BI reporting.
-- Grain: One row per order item.
-- Revenue Definition: Product selling price only.
-- Gross Profit: Selling price minus product cost.
-- ============================================================

USE ecommerce_analytics;

DROP TABLE IF EXISTS fact_sales;

CREATE TABLE fact_sales (
    order_id VARCHAR(100) NOT NULL,
    order_item_id INT NOT NULL,
    customer_id VARCHAR(100) NOT NULL,
    customer_unique_id VARCHAR(100) NOT NULL,
    customer_segment VARCHAR(100),
    customer_state VARCHAR(20),
    product_id VARCHAR(100) NOT NULL,
    product_name VARCHAR(255),
    category VARCHAR(255),
    brand VARCHAR(255),
    seller_id VARCHAR(100) NOT NULL,
    seller_name VARCHAR(255),
    purchase_datetime DATETIME NOT NULL,
    purchase_date DATE NOT NULL,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_number INT NOT NULL,
    month_period CHAR(7) NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    cost DECIMAL(12,2) NOT NULL,
    freight_value DECIMAL(12,2) NOT NULL,
    gross_profit DECIMAL(12,2) NOT NULL,
    gross_margin_pct DECIMAL(8,4),
    PRIMARY KEY (order_id, order_item_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- Load the sales fact table from the validated core tables.
-- The joins preserve the one-row-per-order-item grain.
-- ============================================================

INSERT INTO fact_sales (
    order_id,
    order_item_id,
    customer_id,
    customer_unique_id,
    customer_segment,
    customer_state,
    product_id,
    product_name,
    category,
    brand,
    seller_id,
    seller_name,
    purchase_datetime,
    purchase_date,
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    price,
    cost,
    freight_value,
    gross_profit,
    gross_margin_pct
)
SELECT
    oi.order_id,
    oi.order_item_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_segment,
    c.customer_state,
    oi.product_id,
    p.product_name,
    p.product_category_name,
    p.product_brand,
    oi.seller_id,
    s.seller_company_name,
    o.order_purchase_timestamp,
    DATE(o.order_purchase_timestamp),
    YEAR(o.order_purchase_timestamp),
    QUARTER(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp),
    MONTHNAME(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp),
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'),
    oi.price,
    p.cost,
    oi.freight_value,
    oi.price - p.cost,
    CASE
        WHEN oi.price <> 0
        THEN (oi.price - p.cost) / oi.price
        ELSE NULL
    END
FROM order_items oi
INNER JOIN orders o
    ON oi.order_id = o.order_id
INNER JOIN customers c
    ON o.customer_id = c.customer_id
INNER JOIN products p
    ON oi.product_id = p.product_id
INNER JOIN sellers s
    ON oi.seller_id = s.seller_id;

-- Validate that the fact table preserves the original order-item grain.
SELECT
    COUNT(*) AS fact_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(DISTINCT product_id) AS distinct_products,
    COUNT(DISTINCT customer_unique_id) AS distinct_customers,
    MIN(purchase_date) AS earliest_purchase_date,
    MAX(purchase_date) AS latest_purchase_date,
    SUM(price) AS total_revenue,
    SUM(cost) AS total_cost,
    SUM(freight_value) AS total_freight,
    SUM(gross_profit) AS total_gross_profit
FROM fact_sales;

-- Confirm that each order-item combination appears exactly once.
SELECT
    order_id,
    order_item_id,
    COUNT(*) AS row_count
FROM fact_sales
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1
LIMIT 20;

-- ============================================================
-- Indexes for the sales fact table.
-- Purpose: Improve time, product, customer, category,
-- and seller analysis performance.
-- ============================================================


CREATE INDEX idx_fact_sales_purchase_date
ON fact_sales (purchase_date);

CREATE INDEX idx_fact_sales_month_period
ON fact_sales (month_period);

CREATE INDEX idx_fact_sales_product
ON fact_sales (product_id);

CREATE INDEX idx_fact_sales_customer
ON fact_sales (customer_unique_id);

CREATE INDEX idx_fact_sales_seller
ON fact_sales (seller_id);

CREATE INDEX idx_fact_sales_category
ON fact_sales (category);

-- Check which indexes already exist on the sales fact table.
SHOW INDEX FROM fact_sales;

-- ============================================================
-- Fact Sales Reconciliation
-- Purpose: Confirm that the fact table preserves the original
-- order-item counts and financial totals.
-- ============================================================


SELECT
    (SELECT COUNT(*) FROM order_items) AS source_order_items,
    (SELECT COUNT(*) FROM fact_sales) AS fact_sales_rows,
    (SELECT SUM(price) FROM order_items) AS source_revenue,
    (SELECT SUM(price) FROM fact_sales) AS fact_revenue,
    (SELECT SUM(freight_value) FROM order_items) AS source_freight,
    (SELECT SUM(freight_value) FROM fact_sales) AS fact_freight,
    (SELECT SUM(oi.price - p.cost)
     FROM order_items oi
     JOIN products p ON oi.product_id = p.product_id) AS source_gross_profit,
    (SELECT SUM(gross_profit) FROM fact_sales) AS fact_gross_profit;