-- ============================================================
-- 08_validate_database.sql
-- Purpose: Perform final data-quality checks before building
-- the analytical fact layer.
-- Strategy: Validate row counts, keys, relationships, dates,
-- and important numeric business rules.
-- ============================================================

USE ecommerce_analytics;

-- Check final row counts for all core tables.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews;

-- Check for orphan orders without a matching customer.
SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Check for orphan order items without a matching order.
SELECT COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check for orphan order items without a matching product.
SELECT COUNT(*) AS orphan_products
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Check for orphan order items without a matching seller.
SELECT COUNT(*) AS orphan_sellers
FROM order_items oi
LEFT JOIN sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- Check for orphan payments without a matching order.
SELECT COUNT(*) AS orphan_payments
FROM order_payments op
LEFT JOIN orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check for orphan reviews without a matching order.
SELECT COUNT(*) AS orphan_reviews
FROM order_reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check review scores outside the valid 1-5 range.
SELECT COUNT(*) AS invalid_review_scores
FROM order_reviews
WHERE review_score IS NOT NULL
AND (review_score < 1 OR review_score > 5);

-- Check negative product prices or costs.
SELECT COUNT(*) AS invalid_product_values
FROM products
WHERE price < 0 OR cost < 0;

-- Check negative order-item prices or freight values.
SELECT COUNT(*) AS invalid_order_item_values
FROM order_items
WHERE price < 0 OR freight_value < 0;

-- Check negative payment values.
SELECT COUNT(*) AS invalid_payment_values
FROM order_payments
WHERE payment_value < 0;

-- Check invalid payment installments.
SELECT COUNT(*) AS invalid_installments
FROM order_payments
WHERE payment_installments < 1;

-- Check invalid order purchase timestamps.
SELECT
    MIN(order_purchase_timestamp) AS earliest_purchase,
    MAX(order_purchase_timestamp) AS latest_purchase
FROM orders;