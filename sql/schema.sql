-- schema.sql
-- Database design for the e-commerce delivery analysis project.
-- raw   = data exactly as it came from the CSV files
-- clean = data after cleaning (filled in later)

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS clean;

-- Parent tables first (no foreign keys)

CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id              VARCHAR(32) PRIMARY KEY,
    customer_unique_id       VARCHAR(32) NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city            TEXT,
    customer_state           CHAR(2)
);

CREATE TABLE IF NOT EXISTS raw.products (
    product_id                 VARCHAR(32) PRIMARY KEY,
    product_category_name      TEXT,
    product_name_lenght        INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty         INTEGER,
    product_weight_g           INTEGER,
    product_length_cm          INTEGER,
    product_height_cm          INTEGER,
    product_width_cm           INTEGER
);

CREATE TABLE IF NOT EXISTS raw.sellers (
    seller_id              VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city            TEXT,
    seller_state           CHAR(2)
);

CREATE TABLE IF NOT EXISTS raw.category_translation (
    product_category_name         TEXT PRIMARY KEY,
    product_category_name_english TEXT
);

-- Geolocation has no unique column (many duplicate rows), so no primary key.
CREATE TABLE IF NOT EXISTS raw.geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat             DOUBLE PRECISION,
    geolocation_lng             DOUBLE PRECISION,
    geolocation_city            TEXT,
    geolocation_state           CHAR(2)
);

-- Child tables (with foreign keys)

CREATE TABLE IF NOT EXISTS raw.orders (
    order_id                      VARCHAR(32) PRIMARY KEY,
    customer_id                   VARCHAR(32) NOT NULL REFERENCES raw.customers (customer_id),
    order_status                  TEXT NOT NULL,
    order_purchase_timestamp      TIMESTAMP,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE IF NOT EXISTS raw.order_items (
    order_id            VARCHAR(32) REFERENCES raw.orders (order_id),
    order_item_id       INTEGER,
    product_id          VARCHAR(32) NOT NULL REFERENCES raw.products (product_id),
    seller_id           VARCHAR(32) NOT NULL REFERENCES raw.sellers (seller_id),
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10,2),
    freight_value       NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE IF NOT EXISTS raw.payments (
    order_id             VARCHAR(32) REFERENCES raw.orders (order_id),
    payment_sequential   INTEGER,
    payment_type         TEXT,
    payment_installments INTEGER,
    payment_value        NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE IF NOT EXISTS raw.reviews (
    review_id               VARCHAR(32),
    order_id                VARCHAR(32) REFERENCES raw.orders (order_id),
    review_score            INTEGER,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    PRIMARY KEY (review_id, order_id)
);