-- ============================================================
-- database_setup.sql
-- Purpose: Initialize the ecommerce analytics database.
-- Project: End-to-end E-commerce Data Analysis Portfolio
-- ============================================================

-- Create the project database if it does not already exist.
CREATE DATABASE IF NOT EXISTS ecommerce_analytics
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

-- Switch to the project database.
USE ecommerce_analytics;

-- Confirm the active database before loading any data.
SELECT DATABASE() AS current_database;

-- ============================================================
-- 01_create_staging_tables.sql
-- Purpose: Create staging tables for raw CSV ingestion.
-- Design: Preserve source data before type conversion and cleaning.
-- Strategy: Use flexible VARCHAR fields to prevent import failures.
-- ============================================================

USE ecommerce_analytics;

-- Drop existing staging tables so the script can be rerun safely.
DROP TABLE IF EXISTS stg_customers;
DROP TABLE IF EXISTS stg_geolocation;
DROP TABLE IF EXISTS stg_order_items;
DROP TABLE IF EXISTS stg_order_payments;
DROP TABLE IF EXISTS stg_order_reviews;
DROP TABLE IF EXISTS stg_orders;
DROP TABLE IF EXISTS stg_products;
DROP TABLE IF EXISTS stg_sellers;

-- Create the raw customers staging table.
CREATE TABLE stg_customers (
    customer_id VARCHAR(100),
    customer_unique_id VARCHAR(100),
    customer_name VARCHAR(255),
    customer_gender VARCHAR(50),
    customer_age VARCHAR(50),
    customer_zip_code_prefix VARCHAR(50),
    customer_city VARCHAR(255),
    customer_state VARCHAR(50),
    customer_segment VARCHAR(100)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the raw geolocation staging table.
CREATE TABLE stg_geolocation (
    zip_code_prefix VARCHAR(50),
    geolocation_lat VARCHAR(100),
    geolocation_lng VARCHAR(100),
    geolocation_city VARCHAR(255),
    geolocation_state VARCHAR(50)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the raw order items staging table.
CREATE TABLE stg_order_items (
    order_id VARCHAR(100),
    order_item_id VARCHAR(50),
    product_id VARCHAR(100),
    seller_id VARCHAR(100),
    shipping_limit_date VARCHAR(100),
    price VARCHAR(100),
    freight_value VARCHAR(100),
    discount_rate VARCHAR(100)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the raw payment staging table.
CREATE TABLE stg_order_payments (
    order_id VARCHAR(100),
    payment_sequential VARCHAR(50),
    payment_type VARCHAR(100),
    payment_installments VARCHAR(50),
    payment_value VARCHAR(100)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the raw review staging table.
CREATE TABLE stg_order_reviews (
    review_id VARCHAR(100),
    order_id VARCHAR(100),
    review_score VARCHAR(50),
    review_comment_title VARCHAR(1000),
    review_comment_messsage VARCHAR(2000),
    review_creation_date VARCHAR(100),
    review_answer_timestamp VARCHAR(100)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the raw orders staging table.
CREATE TABLE stg_orders (
    order_id VARCHAR(100),
    customer_id VARCHAR(100),
    order_status VARCHAR(100),
    order_purchase_timestamp VARCHAR(100),
    order_approved_at VARCHAR(100),
    order_delivered_carrier_date VARCHAR(100),
    order_delivered_customer_date VARCHAR(100),
    order_estimated_delivery_date VARCHAR(100)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the raw products staging table.
CREATE TABLE stg_products (
    product_id VARCHAR(100),
    product_category_name VARCHAR(255),
    product_name VARCHAR(1000),
    product_brand VARCHAR(255),
    product_weight_g VARCHAR(100),
    product_length_cm VARCHAR(100),
    product_height_cm VARCHAR(100),
    product_width_cm VARCHAR(100),
    cost VARCHAR(100),
    price VARCHAR(100)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Create the raw sellers staging table.
CREATE TABLE stg_sellers (
    seller_id VARCHAR(100),
    seller_company_name VARCHAR(255),
    seller_contact_name VARCHAR(255),
    seller_contact_gender VARCHAR(50),
    seller_zip_code_prefix VARCHAR(50),
    seller_city VARCHAR(255),
    seller_state VARCHAR(50)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- Verify that all eight staging tables were created successfully.
SHOW TABLES;

-- Check whether MySQL allows loading data from local CSV files.
-- This setting is required for importing the raw CSV files into staging tables.
SHOW VARIABLES LIKE 'local_infile';

-- Enable local CSV file loading for the current MySQL session.
-- This allows LOAD DATA LOCAL INFILE to import files from the local computer.
SET GLOBAL local_infile = 1;
-- Confirm that local CSV file loading has been enabled.
SHOW VARIABLES LIKE 'local_infile';

