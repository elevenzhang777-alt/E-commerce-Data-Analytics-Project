-- ============================================================
-- 02_load_staging_data.sql
-- Purpose: Load the eight raw CSV files into staging tables.
-- Strategy: Preserve the original source data before cleaning.
-- Encoding: UTF-8 CSV files with column headers.
-- ============================================================

USE ecommerce_analytics;

-- Load raw customer data into the customer staging table.
LOAD DATA LOCAL INFILE 'C:/Users/eleven-/OneDrive/million data/customers.csv'
INTO TABLE stg_customers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load raw geolocation data into the geolocation staging table.
LOAD DATA LOCAL INFILE 'C:/Users/eleven-/OneDrive/million data/geolocation.csv'
INTO TABLE stg_geolocation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load raw product data into the product staging table.
LOAD DATA LOCAL INFILE 'C:/Users/eleven-/OneDrive/million data/products.csv'
INTO TABLE stg_products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load raw seller data into the seller staging table.
LOAD DATA LOCAL INFILE 'C:/Users/eleven-/OneDrive/million data/sellers.csv'
INTO TABLE stg_sellers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load raw order data into the order staging table.
LOAD DATA LOCAL INFILE 'C:/Users/eleven-/OneDrive/million data/orders.csv'
INTO TABLE stg_orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load raw order-item data into the order-item staging table.
LOAD DATA LOCAL INFILE 'C:/Users/eleven-/OneDrive/million data/order_items.csv'
INTO TABLE stg_order_items
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load raw payment data into the payment staging table.
LOAD DATA LOCAL INFILE 'C:/Users/eleven-/OneDrive/million data/order_payments.csv'
INTO TABLE stg_order_payments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load raw review data into the review staging table.
LOAD DATA LOCAL INFILE 'C:/Users/eleven-/OneDrive/million data/order_reviews.csv'
INTO TABLE stg_order_reviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify that all eight staging tables contain imported records.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM stg_customers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM stg_geolocation
UNION ALL
SELECT 'products', COUNT(*) FROM stg_products
UNION ALL
SELECT 'sellers', COUNT(*) FROM stg_sellers
UNION ALL
SELECT 'orders', COUNT(*) FROM stg_orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM stg_order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM stg_order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM stg_order_reviews;