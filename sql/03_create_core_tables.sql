-- ============================================================
-- 03_create_core_tables.sql
-- Purpose: Create clean relational core tables from the staging layer.
-- Design: Use appropriate business data types and prepare primary keys.
-- Strategy: Keep staging tables unchanged as the raw-data backup layer.
-- ============================================================

USE ecommerce_analytics;

-- Remove previous core tables so the script can be rerun safely.
-- Tables are dropped in dependency order.
DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS geolocation;

-- Create the customer core table.
CREATE TABLE customers (
    customer_id VARCHAR(100) NOT NULL,
    customer_unique_id VARCHAR(100) NOT NULL,
    customer_name VARCHAR(255),
    customer_gender VARCHAR(50),
    customer_age INT,
    customer_zip_code_prefix INT,
    customer_city VARCHAR(255),
    customer_state VARCHAR(50),
    customer_segment VARCHAR(100),
    PRIMARY KEY (customer_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the geolocation core table.
-- Zip codes are intentionally not defined as a primary key because
-- multiple geographic observations can exist for the same prefix.
CREATE TABLE geolocation (
    zip_code_prefix INT NOT NULL,
    geolocation_lat DECIMAL(10,7),
    geolocation_lng DECIMAL(10,7),
    geolocation_city VARCHAR(255),
    geolocation_state VARCHAR(50)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the product core table.
CREATE TABLE products (
    product_id VARCHAR(100) NOT NULL,
    product_category_name VARCHAR(255),
    product_name VARCHAR(1000),
    product_brand VARCHAR(255),
    product_weight_g DECIMAL(12,2),
    product_length_cm DECIMAL(10,2),
    product_height_cm DECIMAL(10,2),
    product_width_cm DECIMAL(10,2),
    cost DECIMAL(12,2),
    price DECIMAL(12,2),
    PRIMARY KEY (product_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the seller core table.
CREATE TABLE sellers (
    seller_id VARCHAR(100) NOT NULL,
    seller_company_name VARCHAR(255),
    seller_contact_name VARCHAR(255),
    seller_contact_gender VARCHAR(50),
    seller_zip_code_prefix INT,
    seller_city VARCHAR(255),
    seller_state VARCHAR(50),
    PRIMARY KEY (seller_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the order core table.
-- Delivery dates remain nullable because cancelled orders may not have delivery events.
CREATE TABLE orders (
    order_id VARCHAR(100) NOT NULL,
    customer_id VARCHAR(100) NOT NULL,
    order_status VARCHAR(100),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    PRIMARY KEY (order_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the order-item core table.
-- The composite primary key identifies each item within an order.
CREATE TABLE order_items (
    order_id VARCHAR(100) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(100) NOT NULL,
    seller_id VARCHAR(100) NOT NULL,
    shipping_limit_date DATETIME,
    price DECIMAL(12,2),
    freight_value DECIMAL(12,2),
    discount_rate DECIMAL(8,4),
    PRIMARY KEY (order_id, order_item_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the payment core table.
-- Multiple payment records can exist for one order.
CREATE TABLE order_payments (
    order_id VARCHAR(100) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(100),
    payment_installments INT,
    payment_value DECIMAL(12,2),
    PRIMARY KEY (order_id, payment_sequential)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the review core table.
-- review_id uniquely identifies each review record.
CREATE TABLE order_reviews (
    review_id VARCHAR(100) NOT NULL,
    order_id VARCHAR(100) NOT NULL,
    review_score INT,
    review_comment_title VARCHAR(1000),
    review_comment_messsage VARCHAR(2000),
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Verify that all eight core tables have been created successfully.
SHOW TABLES;