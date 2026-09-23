-- ============================================================
-- 10_create_fact_payment.sql
-- Purpose: Create the payment fact table for payment behavior
-- and payment-method analysis.
-- Grain: One row per order payment record.
-- ============================================================

USE ecommerce_analytics;

DROP TABLE IF EXISTS fact_payment;

CREATE TABLE fact_payment (
    order_id VARCHAR(100) NOT NULL,
    payment_sequential INT NOT NULL,
    customer_id VARCHAR(100),
    customer_unique_id VARCHAR(100),
    customer_segment VARCHAR(100),
    purchase_datetime DATETIME,
    purchase_date DATE,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    month_number INT,
    month_period CHAR(7),
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(12,2),
    PRIMARY KEY (order_id, payment_sequential)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- Load payment records at their original transaction grain.
-- Payment data is kept separate from fact_sales to prevent
-- one-to-many joins from inflating sales metrics.
-- ============================================================

INSERT INTO fact_payment (
    order_id,
    payment_sequential,
    customer_id,
    customer_unique_id,
    customer_segment,
    purchase_datetime,
    purchase_date,
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    op.order_id,
    op.payment_sequential,
    o.customer_id,
    c.customer_unique_id,
    c.customer_segment,
    o.order_purchase_timestamp,
    DATE(o.order_purchase_timestamp),
    YEAR(o.order_purchase_timestamp),
    QUARTER(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp),
    MONTHNAME(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp),
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'),
    op.payment_type,
    op.payment_installments,
    op.payment_value
FROM order_payments op
INNER JOIN orders o
    ON op.order_id = o.order_id
INNER JOIN customers c
    ON o.customer_id = c.customer_id;

-- Validate payment fact-table grain and financial totals.
SELECT
    COUNT(*) AS fact_payment_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(DISTINCT customer_unique_id) AS distinct_customers,
    MIN(purchase_date) AS earliest_purchase_date,
    MAX(purchase_date) AS latest_purchase_date,
    SUM(payment_value) AS total_payment_value
FROM fact_payment;

-- Confirm that each order-payment combination appears exactly once.
SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS row_count
FROM fact_payment
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1
LIMIT 20;

-- Add indexes for payment-method, customer, and time analysis.
CREATE INDEX idx_fact_payment_purchase_date
ON fact_payment (purchase_date);

CREATE INDEX idx_fact_payment_month_period
ON fact_payment (month_period);

CREATE INDEX idx_fact_payment_type
ON fact_payment (payment_type);

CREATE INDEX idx_fact_payment_customer
ON fact_payment (customer_unique_id);

-- Verify payment fact-table indexes.
SHOW INDEX FROM fact_payment;