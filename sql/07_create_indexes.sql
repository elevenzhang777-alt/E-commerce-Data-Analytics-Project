-- ============================================================
-- 07_create_indexes.sql
-- Purpose: Add indexes for joins, filtering, and analytical queries.
-- Strategy: Index foreign-key columns and frequently filtered fields.
-- Note: Indexes improve query performance but do not replace
-- referential-integrity constraints.
-- ============================================================

USE ecommerce_analytics;

-- Support customer-level analysis and customer relationship joins.
CREATE INDEX idx_customers_unique_id
ON customers (customer_unique_id);

-- Support customer-to-order joins.
CREATE INDEX idx_orders_customer_id
ON orders (customer_id);

-- Support time-based sales analysis and delivered-order filtering.
CREATE INDEX idx_orders_status_purchase
ON orders (order_status, order_purchase_timestamp);

-- Support order-item to product joins.
CREATE INDEX idx_order_items_product_id
ON order_items (product_id);

-- Support order-item to seller joins.
CREATE INDEX idx_order_items_seller_id
ON order_items (seller_id);

-- Support payment-to-order joins.
-- The primary key already starts with order_id, so no separate
-- order_id index is required for this table.
-- Support review-to-order joins.
CREATE INDEX idx_order_reviews_order_id
ON order_reviews (order_id);

-- Support geographic lookups by postal-code prefix.
CREATE INDEX idx_geolocation_zip
ON geolocation (zip_code_prefix);

-- Verify the indexes created on the core analytical tables.
SHOW INDEX FROM customers;
SHOW INDEX FROM orders;
SHOW INDEX FROM order_items;
SHOW INDEX FROM order_payments;
SHOW INDEX FROM order_reviews;
SHOW INDEX FROM geolocation;