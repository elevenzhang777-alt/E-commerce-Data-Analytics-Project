-- ============================================================
-- 20_create_delivery_review.sql
-- Purpose: Create monthly delivery and review performance.
-- Grain: One row per month and review score.
-- Source: fact_delivery_review.
-- ============================================================

USE ecommerce_analytics;

DROP TABLE IF EXISTS delivery_review;

CREATE TABLE delivery_review (
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_number INT NOT NULL,
    month_period CHAR(7) NOT NULL,
    review_score INT NOT NULL,
    orders INT,
    avg_delivery_days DECIMAL(10,4),
    avg_estimated_days DECIMAL(10,4),
    late_orders INT,
    late_rate_pct DECIMAL(10,4),
    PRIMARY KEY (month_period, review_score)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Aggregate delivery and review metrics by month and review score.
INSERT INTO delivery_review (
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    review_score,
    orders,
    avg_delivery_days,
    avg_estimated_days,
    late_orders,
    late_rate_pct
)
SELECT
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    review_score,
    COUNT(DISTINCT order_id) AS orders,
    AVG(delivery_days) AS avg_delivery_days,
    AVG(estimated_delivery_days) AS avg_estimated_days,
    SUM(late_delivery_flag) AS late_orders,
    SUM(late_delivery_flag) / COUNT(DISTINCT order_id) * 100 AS late_rate_pct
FROM fact_delivery_review
GROUP BY
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
    review_score;

-- Validate delivery and review aggregation.
SELECT
    COUNT(*) AS rows_count,
    COUNT(DISTINCT review_score) AS review_scores,
    MIN(month_period) AS first_month,
    MAX(month_period) AS last_month,
    SUM(orders) AS total_orders,
    SUM(late_orders) AS total_late_orders,
    SUM(late_orders) / SUM(orders) * 100 AS overall_late_rate_pct,
    SUM(orders * avg_delivery_days) / SUM(orders) AS weighted_avg_delivery_days,
    SUM(orders * avg_estimated_days) / SUM(orders) AS weighted_avg_estimated_days
FROM delivery_review;

-- Confirm that each month-review score combination appears exactly once.
SELECT
    month_period,
    review_score,
    COUNT(*) AS row_count
FROM delivery_review
GROUP BY month_period, review_score
HAVING COUNT(*) > 1
LIMIT 20;