CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS clean;
CREATE TABLE raw.customers (
    customer_id              VARCHAR(32) PRIMARY KEY,
    customer_unique_id       VARCHAR(32) NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city            TEXT,
    customer_state           CHAR(2)
);

CREATE TABLE raw.orders (
    order_id                      VARCHAR(32) PRIMARY KEY,
    customer_id                   VARCHAR(32) NOT NULL,
    order_status                  TEXT NOT NULL,
    order_purchase_timestamp      TIMESTAMP,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE raw.order_items (
    order_id            VARCHAR(32),
    order_item_id       INTEGER,
    product_id          VARCHAR(32) NOT NULL,
    seller_id           VARCHAR(32) NOT NULL,
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10,2),
    freight_value       NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE raw.payments (
    order_id             VARCHAR(32),
    payment_sequential   INTEGER,
    payment_type         TEXT,
    payment_installments INTEGER,
    payment_value        NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE raw.reviews (
    review_id               VARCHAR(32),
    order_id                VARCHAR(32),
    review_score            INTEGER,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    PRIMARY KEY (review_id, order_id)
);

CREATE TABLE raw.products (
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

CREATE TABLE raw.sellers (
    seller_id              VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city            TEXT,
    seller_state           CHAR(2)
);

CREATE TABLE raw.geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat             DOUBLE PRECISION,
    geolocation_lng             DOUBLE PRECISION,
    geolocation_city            TEXT,
    geolocation_state           CHAR(2)
);

CREATE TABLE raw.category_translation (
    product_category_name         TEXT PRIMARY KEY,
    product_category_name_english TEXT
);



ALTER TABLE raw.orders
  ADD FOREIGN KEY (customer_id) REFERENCES raw.customers (customer_id);
ALTER TABLE raw.order_items
  ADD FOREIGN KEY (order_id) REFERENCES raw.orders (order_id);
ALTER TABLE raw.order_items
  ADD FOREIGN KEY (product_id) REFERENCES raw.products (product_id);
ALTER TABLE raw.order_items
  ADD FOREIGN KEY (seller_id) REFERENCES raw.sellers (seller_id);
ALTER TABLE raw.payments
  ADD FOREIGN KEY (order_id) REFERENCES raw.orders (order_id);
ALTER TABLE raw.reviews
  ADD FOREIGN KEY (order_id) REFERENCES raw.orders (order_id);