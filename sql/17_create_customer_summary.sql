-- ============================================================
-- 17_create_customer_summary.sql
-- Purpose: Create an overall customer-level behavioral summary.
-- Grain: One row per customer_unique_id across the full analysis period.
-- Source: fact_sales.
-- Business Rules: Customer behavior is measured using realized product revenue.
-- ============================================================

USE ecommerce_analytics;

DROP TABLE IF EXISTS customer_summary;

CREATE TABLE customer_summary (
    customer_unique_id VARCHAR(100) NOT NULL,
    customer_segment VARCHAR(100),
    first_purchase_date DATE,
    last_purchase_date DATE,
    order_count INT,
    units_sold INT,
    revenue DECIMAL(18,2),
    aov DECIMAL(18,2),
    purchase_frequency DECIMAL(18,4),
    customer_lifetime_days INT,
    repeat_customer_flag TINYINT,
    revenue_share_pct DECIMAL(10,6),
    PRIMARY KEY (customer_unique_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Aggregate overall customer purchasing behavior.
INSERT INTO customer_summary (
    customer_unique_id,
    customer_segment,
    first_purchase_date,
    last_purchase_date,
    order_count,
    units_sold,
    revenue,
    aov,
    purchase_frequency,
    customer_lifetime_days,
    repeat_customer_flag,
    revenue_share_pct
)
SELECT
    customer_unique_id,
    MAX(customer_segment) AS customer_segment,
    MIN(purchase_date) AS first_purchase_date,
    MAX(purchase_date) AS last_purchase_date,
    COUNT(DISTINCT order_id) AS order_count,
    COUNT(*) AS units_sold,
    SUM(price) AS revenue,
    SUM(price) / COUNT(DISTINCT order_id) AS aov,
    COUNT(DISTINCT order_id) /
        NULLIF(DATEDIFF(MAX(purchase_date), MIN(purchase_date)) + 1, 0) AS purchase_frequency,
    DATEDIFF(MAX(purchase_date), MIN(purchase_date)) AS customer_lifetime_days,
    CASE
        WHEN COUNT(DISTINCT order_id) > 1 THEN 1
        ELSE 0
    END AS repeat_customer_flag,
    SUM(price) /
        NULLIF(SUM(SUM(price)) OVER (), 0) * 100 AS revenue_share_pct
FROM fact_sales
GROUP BY customer_unique_id;

-- Validate customer summary coverage and financial reconciliation.
SELECT
    COUNT(*) AS customers,
    SUM(units_sold) AS total_units,
    SUM(revenue) AS total_revenue,
    SUM(CASE WHEN repeat_customer_flag = 1 THEN 1 ELSE 0 END) AS repeat_customers,
    SUM(CASE WHEN repeat_customer_flag = 0 THEN 1 ELSE 0 END) AS one_time_customers,
    SUM(revenue_share_pct) AS total_revenue_share_pct,
    MIN(first_purchase_date) AS first_purchase,
    MAX(last_purchase_date) AS last_purchase
FROM customer_summary;

-- Analyze customer purchase frequency distribution.
SELECT
    CASE
        WHEN order_count = 1 THEN '1 order'
        WHEN order_count BETWEEN 2 AND 4 THEN '2-4 orders'
        WHEN order_count BETWEEN 5 AND 9 THEN '5-9 orders'
        ELSE '10+ orders'
    END AS order_frequency_group,
    COUNT(*) AS customers,
    SUM(revenue) AS revenue
FROM customer_summary
GROUP BY
    CASE
        WHEN order_count = 1 THEN '1 order'
        WHEN order_count BETWEEN 2 AND 4 THEN '2-4 orders'
        WHEN order_count BETWEEN 5 AND 9 THEN '5-9 orders'
        ELSE '10+ orders'
    END
ORDER BY
    MIN(order_count);

-- Increase revenue share precision to avoid cumulative rounding errors across 279K customers.
ALTER TABLE customer_summary
MODIFY COLUMN revenue_share_pct DECIMAL(18,10);

-- Recalculate customer revenue share using higher precision.
UPDATE customer_summary cs
JOIN (
    SELECT
        customer_unique_id,
        revenue / NULLIF(SUM(revenue) OVER (), 0) * 100 AS revenue_share
    FROM customer_summary
) x
ON cs.customer_unique_id = x.customer_unique_id
SET cs.revenue_share_pct = x.revenue_share;

-- Confirm that customer revenue shares reconcile to 100%.
SELECT
    SUM(revenue_share_pct) AS total_revenue_share_pct
FROM customer_summary;

-- Recalculate each customer's revenue share against the exact total customer revenue.
UPDATE customer_summary cs
CROSS JOIN (
    SELECT SUM(revenue) AS total_revenue
    FROM customer_summary
) t
SET cs.revenue_share_pct =
    cs.revenue / NULLIF(t.total_revenue, 0) * 100;

-- Validate that all customer revenue shares reconcile to 100%.
SELECT
    SUM(revenue_share_pct) AS total_revenue_share_pct,
    SUM(revenue) AS total_revenue
FROM customer_summary;

-- Diagnose customer revenue share calculation and identify missing or inconsistent values.
SELECT
    COUNT(*) AS customers,
    COUNT(revenue_share_pct) AS customers_with_share,
    SUM(CASE WHEN revenue_share_pct IS NULL THEN 1 ELSE 0 END) AS null_share_customers,
    SUM(revenue) AS total_revenue,
    SUM(CASE WHEN revenue_share_pct IS NULL THEN revenue ELSE 0 END) AS revenue_with_null_share,
    SUM(revenue_share_pct) AS total_revenue_share_pct
FROM customer_summary;

-- Compare stored revenue share against the expected calculation for sample customers.
SELECT
    customer_unique_id,
    revenue,
    revenue_share_pct,
    revenue / (
        SELECT SUM(revenue)
        FROM customer_summary
    ) * 100 AS expected_revenue_share
FROM customer_summary
ORDER BY revenue DESC
LIMIT 10;

-- Recalculate customer revenue share from the original revenue values using high-precision DECIMAL arithmetic.
UPDATE customer_summary cs
CROSS JOIN (
    SELECT SUM(revenue) AS total_revenue
    FROM customer_summary
) t
SET cs.revenue_share_pct =
    CAST(cs.revenue AS DECIMAL(30,10))
    / CAST(t.total_revenue AS DECIMAL(30,10))
    * CAST(100 AS DECIMAL(30,10));

-- Confirm that customer revenue shares reconcile to 100% after high-precision recalculation.
SELECT
    SUM(revenue_share_pct) AS total_revenue_share_pct,
    SUM(revenue) AS total_revenue
FROM customer_summary;