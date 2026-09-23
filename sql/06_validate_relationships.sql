-- ============================================================
-- 06_validate_relationships.sql
-- Purpose: Validate referential integrity before creating foreign keys.
-- Strategy: Detect orphan records in all parent-child relationships.
-- ============================================================

USE ecommerce_analytics;

-- Check whether every order references an existing customer.
SELECT
    'orders -> customers' AS relationship,
    COUNT(*) AS orphan_rows
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Check whether every order item references an existing order.
SELECT
    'order_items -> orders' AS relationship,
    COUNT(*) AS orphan_rows
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check whether every order item references an existing product.
SELECT
    'order_items -> products' AS relationship,
    COUNT(*) AS orphan_rows
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Check whether every order item references an existing seller.
SELECT
    'order_items -> sellers' AS relationship,
    COUNT(*) AS orphan_rows
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- Check whether every payment references an existing order.
SELECT
    'order_payments -> orders' AS relationship,
    COUNT(*) AS orphan_rows
FROM order_payments op
LEFT JOIN orders o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check whether every review references an existing order.
SELECT
    'order_reviews -> orders' AS relationship,
    COUNT(*) AS orphan_rows
FROM order_reviews r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;