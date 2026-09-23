-- ============================================================
-- 04_transform_and_load_core.sql
-- Purpose: Transform raw staging data into typed core tables.
-- Strategy: Convert strings into numeric and datetime fields while
-- preserving meaningful NULL values from the source data.
-- Business Rule: Do not invent default values for missing data.
-- ============================================================

USE ecommerce_analytics;

-- Load customers from staging into the typed customer core table.
INSERT INTO customers (
    customer_id,
    customer_unique_id,
    customer_name,
    customer_gender,
    customer_age,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    customer_segment
)
SELECT
    TRIM(customer_id),
    TRIM(customer_unique_id),
    NULLIF(TRIM(customer_name), ''),
    NULLIF(TRIM(customer_gender), ''),
    CAST(NULLIF(TRIM(customer_age), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(customer_zip_code_prefix), '') AS UNSIGNED),
    NULLIF(TRIM(customer_city), ''),
    NULLIF(TRIM(customer_state), ''),
    NULLIF(TRIM(customer_segment), '')
FROM stg_customers;

-- Load geolocation data and convert geographic coordinates to decimal values.
INSERT INTO geolocation (
    zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
SELECT
    CAST(NULLIF(TRIM(zip_code_prefix), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(geolocation_lat), '') AS DECIMAL(10,7)),
    CAST(NULLIF(TRIM(geolocation_lng), '') AS DECIMAL(10,7)),
    NULLIF(TRIM(geolocation_city), ''),
    NULLIF(TRIM(geolocation_state), '')
FROM stg_geolocation;

-- Load products and convert physical measurements and financial fields to numeric types.
INSERT INTO products (
    product_id,
    product_category_name,
    product_name,
    product_brand,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    cost,
    price
)
SELECT
    TRIM(product_id),
    NULLIF(TRIM(product_category_name), ''),
    NULLIF(TRIM(product_name), ''),
    NULLIF(TRIM(product_brand), ''),
    CAST(NULLIF(TRIM(product_weight_g), '') AS DECIMAL(12,2)),
    CAST(NULLIF(TRIM(product_length_cm), '') AS DECIMAL(10,2)),
    CAST(NULLIF(TRIM(product_height_cm), '') AS DECIMAL(10,2)),
    CAST(NULLIF(TRIM(product_width_cm), '') AS DECIMAL(10,2)),
    CAST(NULLIF(TRIM(cost), '') AS DECIMAL(12,2)),
    CAST(NULLIF(TRIM(price), '') AS DECIMAL(12,2))
FROM stg_products;

-- Load sellers and convert the seller postal code into an integer.
INSERT INTO sellers (
    seller_id,
    seller_company_name,
    seller_contact_name,
    seller_contact_gender,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    TRIM(seller_id),
    NULLIF(TRIM(seller_company_name), ''),
    NULLIF(TRIM(seller_contact_name), ''),
    NULLIF(TRIM(seller_contact_gender), ''),
    CAST(NULLIF(TRIM(seller_zip_code_prefix), '') AS UNSIGNED),
    NULLIF(TRIM(seller_city), ''),
    NULLIF(TRIM(seller_state), '')
FROM stg_sellers;

-- Load orders and convert all event timestamps into DATETIME values.
-- Delivery timestamps remain NULL when the source contains no delivery event.
INSERT INTO orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)
SELECT
    TRIM(order_id),
    TRIM(customer_id),
    NULLIF(TRIM(order_status), ''),
    STR_TO_DATE(NULLIF(TRIM(order_purchase_timestamp), ''), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(NULLIF(TRIM(order_approved_at), ''), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(NULLIF(TRIM(order_delivered_carrier_date), ''), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(NULLIF(TRIM(order_delivered_customer_date), ''), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(NULLIF(TRIM(order_estimated_delivery_date), ''), '%Y-%m-%d %H:%i:%s')
FROM stg_orders;

-- Load order items and convert pricing and shipping fields to numeric values.
INSERT INTO order_items (
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,
    discount_rate
)
SELECT
    TRIM(order_id),
    CAST(NULLIF(TRIM(order_item_id), '') AS UNSIGNED),
    TRIM(product_id),
    TRIM(seller_id),
    STR_TO_DATE(NULLIF(TRIM(shipping_limit_date), ''), '%Y-%m-%d %H:%i:%s'),
    CAST(NULLIF(TRIM(price), '') AS DECIMAL(12,2)),
    CAST(NULLIF(TRIM(freight_value), '') AS DECIMAL(12,2)),
    CAST(NULLIF(TRIM(discount_rate), '') AS DECIMAL(8,4))
FROM stg_order_items;

-- Load payment records and convert installments and payment values to numeric types.
INSERT INTO order_payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    TRIM(order_id),
    CAST(NULLIF(TRIM(payment_sequential), '') AS UNSIGNED),
    NULLIF(TRIM(payment_type), ''),
    CAST(NULLIF(TRIM(payment_installments), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(payment_value), '') AS DECIMAL(12,2))
FROM stg_order_payments;

-- Load review records and convert review scores and timestamps to their proper types.
INSERT INTO order_reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_messsage,
    review_creation_date,
    review_answer_timestamp
)
SELECT
    TRIM(review_id),
    TRIM(order_id),
    CAST(NULLIF(TRIM(review_score), '') AS UNSIGNED),
    NULLIF(TRIM(review_comment_title), ''),
    NULLIF(TRIM(review_comment_messsage), ''),
    STR_TO_DATE(NULLIF(TRIM(review_creation_date), ''), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(NULLIF(TRIM(review_answer_timestamp), ''), '%Y-%m-%d %H:%i:%s')
FROM stg_order_reviews;

-- Compare staging and core row counts to confirm that no records were lost during transformation.
SELECT 'customers' AS table_name,
       (SELECT COUNT(*) FROM stg_customers) AS staging_rows,
       (SELECT COUNT(*) FROM customers) AS core_rows
UNION ALL
SELECT 'geolocation',
       (SELECT COUNT(*) FROM stg_geolocation),
       (SELECT COUNT(*) FROM geolocation)
UNION ALL
SELECT 'products',
       (SELECT COUNT(*) FROM stg_products),
       (SELECT COUNT(*) FROM products)
UNION ALL
SELECT 'sellers',
       (SELECT COUNT(*) FROM stg_sellers),
       (SELECT COUNT(*) FROM sellers)
UNION ALL
SELECT 'orders',
       (SELECT COUNT(*) FROM stg_orders),
       (SELECT COUNT(*) FROM orders)
UNION ALL
SELECT 'order_items',
       (SELECT COUNT(*) FROM stg_order_items),
       (SELECT COUNT(*) FROM order_items)
UNION ALL
SELECT 'order_payments',
       (SELECT COUNT(*) FROM stg_order_payments),
       (SELECT COUNT(*) FROM order_payments)
UNION ALL
SELECT 'order_reviews',
       (SELECT COUNT(*) FROM stg_order_reviews),
       (SELECT COUNT(*) FROM order_reviews);