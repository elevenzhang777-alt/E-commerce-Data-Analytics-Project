-- ============================================================
-- 11_create_fact_delivery_review.sql
-- Purpose: Create the delivery and review fact table for
-- operational and customer-experience analysis.
-- Grain: One row per order-review record.
-- ============================================================

USE ecommerce_analytics;

DROP TABLE IF EXISTS fact_delivery_review;

CREATE TABLE fact_delivery_review (
    review_id VARCHAR(100) NOT NULL,
    order_id VARCHAR(100) NOT NULL,
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
    order_status VARCHAR(50),
    delivered_customer_date DATETIME,
    estimated_delivery_date DATETIME,
    delivery_days DECIMAL(10,2),
    estimated_delivery_days DECIMAL(10,2),
    late_delivery_flag TINYINT,
    review_score INT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- Load delivery and review information at the review grain.
-- Delivery metrics are calculated only when the required
-- delivery timestamps are available.
-- ============================================================

INSERT INTO fact_delivery_review (
    review_id,
    order_id,
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
    order_status,
    delivered_customer_date,
    estimated_delivery_date,
    delivery_days,
    estimated_delivery_days,
    late_delivery_flag,
    review_score,
    review_creation_date,
    review_answer_timestamp
)
SELECT
    r.review_id,
    r.order_id,
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
    o.order_status,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN TIMESTAMPDIFF(
            DAY,
            o.order_purchase_timestamp,
            o.order_delivered_customer_date
        )
        ELSE NULL
    END,
    CASE
        WHEN o.order_estimated_delivery_date IS NOT NULL
        THEN TIMESTAMPDIFF(
            DAY,
            o.order_purchase_timestamp,
            o.order_estimated_delivery_date
        )
        ELSE NULL
    END,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 1
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN 0
        ELSE NULL
    END,
    r.review_score,
    r.review_creation_date,
    r.review_answer_timestamp
FROM order_reviews r
INNER JOIN orders o
    ON r.order_id = o.order_id
INNER JOIN customers c
    ON o.customer_id = c.customer_id;

-- Validate the delivery-review fact table and its operational metrics.
SELECT
    COUNT(*) AS fact_rows,
    COUNT(DISTINCT review_id) AS distinct_reviews,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(DISTINCT customer_unique_id) AS distinct_customers,
    MIN(purchase_date) AS earliest_purchase_date,
    MAX(purchase_date) AS latest_purchase_date,
    AVG(delivery_days) AS avg_delivery_days,
    AVG(estimated_delivery_days) AS avg_estimated_delivery_days,
    SUM(late_delivery_flag) AS late_orders,
    AVG(late_delivery_flag) AS late_rate
FROM fact_delivery_review;

-- Confirm that each review record appears exactly once.
SELECT
    review_id,
    COUNT(*) AS row_count
FROM fact_delivery_review
GROUP BY review_id
HAVING COUNT(*) > 1
LIMIT 20;

-- Add indexes for delivery, review, customer, and time analysis.
CREATE INDEX idx_fact_delivery_review_purchase_date
ON fact_delivery_review (purchase_date);

CREATE INDEX idx_fact_delivery_review_month_period
ON fact_delivery_review (month_period);

CREATE INDEX idx_fact_delivery_review_score
ON fact_delivery_review (review_score);

CREATE INDEX idx_fact_delivery_review_customer
ON fact_delivery_review (customer_unique_id);