-- ============================================================
-- 05_validate_primary_keys.sql
-- Purpose: Validate candidate primary keys before enforcing
-- primary-key and foreign-key constraints.
-- Strategy: Detect duplicate business keys before adding constraints.
-- ============================================================

USE ecommerce_analytics;

-- Check whether customer_id is unique.
SELECT
    'customers.customer_id' AS key_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT customer_id
    FROM customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) AS duplicates;

-- Check whether order_id is unique.
SELECT
    'orders.order_id' AS key_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT order_id
    FROM orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS duplicates;

-- Check whether product_id is unique.
SELECT
    'products.product_id' AS key_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT product_id
    FROM products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) AS duplicates;

-- Check whether seller_id is unique.
SELECT
    'sellers.seller_id' AS key_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT seller_id
    FROM sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
) AS duplicates;

-- Check whether review_id is unique.
SELECT
    'order_reviews.review_id' AS key_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT review_id
    FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
) AS duplicates;

-- Check whether the order-item composite key is unique.
SELECT
    'order_items(order_id, order_item_id)' AS key_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT order_id, order_item_id
    FROM order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
) AS duplicates;

-- Check whether the payment composite key is unique.
SELECT
    'order_payments(order_id, payment_sequential)' AS key_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT order_id, payment_sequential
    FROM order_payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
) AS duplicates;

-- Check whether customer_unique_id is duplicated.
-- Duplicates are expected because multiple customer_id values
-- can represent the same underlying customer.
SELECT
    'customers.customer_unique_id' AS key_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT customer_unique_id
    FROM customers
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
) AS duplicates;