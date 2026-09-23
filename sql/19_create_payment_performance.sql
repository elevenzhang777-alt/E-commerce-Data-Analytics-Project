-- ============================================================
-- 19_create_payment_performance.sql
-- Purpose: Create monthly payment-method performance.
-- Grain: One row per month and payment type.
-- Source: fact_payment.
-- ============================================================

USE ecommerce_analytics;

DROP TABLE IF EXISTS payment_performance;

CREATE TABLE payment_performance (
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_number INT NOT NULL,
    month_period CHAR(7) NOT NULL,
    payment_type VARCHAR(100) NOT NULL,
    orders INT,
    payment_value DECIMAL(18,2),
    avg_payment_per_order DECIMAL(18,2),
    avg_installments DECIMAL(10,4),
    PRIMARY KEY (month_period, payment_type)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Aggregate payment activity by month and payment type.
INSERT INTO payment_performance (
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    payment_type,
    orders,
    payment_value,
    avg_payment_per_order,
    avg_installments
)
SELECT
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    payment_type,
    COUNT(DISTINCT order_id) AS orders,
    SUM(payment_value) AS payment_value,
    SUM(payment_value) / COUNT(DISTINCT order_id) AS avg_payment_per_order,
    AVG(payment_installments) AS avg_installments
FROM fact_payment
GROUP BY
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    payment_type;

-- Validate payment aggregation and financial reconciliation.
SELECT
    COUNT(*) AS rows_count,
    COUNT(DISTINCT payment_type) AS payment_types,
    MIN(month_period) AS first_month,
    MAX(month_period) AS last_month,
    SUM(payment_value) AS total_payment_value
FROM payment_performance;

-- Confirm that each month-payment type combination appears exactly once.
SELECT
    month_period,
    payment_type,
    COUNT(*) AS row_count
FROM payment_performance
GROUP BY month_period, payment_type
HAVING COUNT(*) > 1
LIMIT 20;