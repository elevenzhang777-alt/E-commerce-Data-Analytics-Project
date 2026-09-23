-- ============================================================
-- 12_create_sales_performance.sql
-- Purpose: Create the monthly sales-performance analytical table.
-- Grain: One row per month.
-- Strategy: Aggregate fact_sales first, then calculate MoM and
-- YoY metrics on the small monthly dataset.
-- ============================================================

USE ecommerce_analytics;

DROP TABLE IF EXISTS sales_performance;

CREATE TABLE sales_performance (
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_number INT NOT NULL,
    month_period CHAR(7) NOT NULL,
    revenue DECIMAL(18,2),
    orders INT,
    aov DECIMAL(18,2),
    revenue_mom_pct DECIMAL(10,4),
    orders_mom_pct DECIMAL(10,4),
    revenue_yoy_pct DECIMAL(10,4),
    orders_yoy_pct DECIMAL(10,4),
    PRIMARY KEY (month_period)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Aggregate sales to monthly grain before calculating growth metrics.
INSERT INTO sales_performance (
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period,
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
    SUM(price) AS revenue,
    COUNT(DISTINCT order_id) AS orders,
    SUM(price) / COUNT(DISTINCT order_id) AS aov
FROM fact_sales
GROUP BY
    year,
    quarter,
    month,
    month_name,
    month_number,
    month_period;

-- Calculate monthly and yearly growth rates from the aggregated
-- monthly sales dataset.
WITH growth AS (
    SELECT
        month_period,
        revenue,
        orders,
        LAG(revenue, 1) OVER (ORDER BY month_period) AS previous_month_revenue,
        LAG(orders, 1) OVER (ORDER BY month_period) AS previous_month_orders,
        LAG(revenue, 12) OVER (ORDER BY month_period) AS previous_year_revenue,
        LAG(orders, 12) OVER (ORDER BY month_period) AS previous_year_orders
    FROM sales_performance
)
UPDATE sales_performance sp
JOIN growth g
    ON sp.month_period = g.month_period
SET
    sp.revenue_mom_pct = CASE
        WHEN g.previous_month_revenue IS NOT NULL
        AND g.previous_month_revenue <> 0
        THEN (g.revenue - g.previous_month_revenue)
             / g.previous_month_revenue
        ELSE NULL
    END,
    sp.orders_mom_pct = CASE
        WHEN g.previous_month_orders IS NOT NULL
        AND g.previous_month_orders <> 0
        THEN (g.orders - g.previous_month_orders)
             / g.previous_month_orders
        ELSE NULL
    END,
    sp.revenue_yoy_pct = CASE
        WHEN g.previous_year_revenue IS NOT NULL
        AND g.previous_year_revenue <> 0
        THEN (g.revenue - g.previous_year_revenue)
             / g.previous_year_revenue
        ELSE NULL
    END,
    sp.orders_yoy_pct = CASE
        WHEN g.previous_year_orders IS NOT NULL
        AND g.previous_year_orders <> 0
        THEN (g.orders - g.previous_year_orders)
             / g.previous_year_orders
        ELSE NULL
    END;

-- Validate the monthly sales-performance analytical table.
SELECT *
FROM sales_performance
ORDER BY month_period;