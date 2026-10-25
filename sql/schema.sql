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

-- Q1: Total revenue and orders (delivered only)
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(i.price), 2)     AS total_revenue
FROM raw.orders o
JOIN raw.order_items i ON o.order_id = i.order_id
WHERE o.order_status = 'delivered';

-- Q2: Revenue per monthSELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
    COUNT(DISTINCT o.order_id)                            AS orders,
    ROUND(SUM(i.price), 2)                                AS revenue
FROM raw.orders o
JOIN raw.order_items i ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;

-- Q3: Monthly revenue and month-over-month growth
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
        COUNT(DISTINCT o.order_id)                            AS orders,
        ROUND(SUM(i.price), 2)                                AS revenue
    FROM raw.orders o
    JOIN raw.order_items i ON o.order_id = i.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    month,
    orders,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month), 1
    ) AS growth_pct
FROM monthly
WHERE orders >= 100 AND month >= '2017-01-01'
ORDER BY month;

-- Q4: Top 10 product categories by revenue (delivered orders)
SELECT
    COALESCE(t.product_category_name_english,
             p.product_category_name, 'unknown')             AS category,
    COUNT(DISTINCT o.order_id)                               AS orders,
    ROUND(SUM(i.price), 2)                                   AS revenue,
    ROUND(100.0 * SUM(i.price) / SUM(SUM(i.price)) OVER (), 1) AS revenue_share_pct
FROM raw.order_items i
JOIN raw.orders o   ON i.order_id = o.order_id
JOIN raw.products p ON i.product_id = p.product_id
LEFT JOIN raw.category_translation t
       ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY revenue DESC
LIMIT 10;

-- Q5: Avg actual vs estimated delivery days by customer state
SELECT
    c.customer_state,
    COUNT(*) AS orders,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400)::numeric, 1) AS avg_actual_days,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_estimated_delivery_date - o.order_purchase_timestamp)) / 86400)::numeric, 1) AS avg_estimated_days
FROM raw.orders o
JOIN raw.customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY avg_actual_days DESC;

-- Q6: Percentage of late deliveries per month
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS month,
    COUNT(*) AS orders,
    ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
                           THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct
FROM raw.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
GROUP BY 1
HAVING COUNT(*) >= 100
ORDER BY 1;

-- Q7: Average review score for late vs on-time orders
WITH order_review AS (
    SELECT order_id, AVG(review_score) AS score
    FROM raw.reviews
    GROUP BY order_id
)
SELECT
    CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
         THEN 'late' ELSE 'on_time' END AS delivery,
    COUNT(*) AS orders,
    ROUND(AVG(r.score), 2) AS avg_score
FROM raw.orders o
JOIN order_review r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1;
-- Q8: Top 3 sellers by revenue within each seller state
SELECT *
FROM (
    SELECT
        s.seller_state,
        s.seller_id,
        ROUND(SUM(i.price), 2) AS revenue,
        RANK() OVER (PARTITION BY s.seller_state ORDER BY SUM(i.price) DESC) AS rank_in_state
    FROM raw.order_items i
    JOIN raw.orders o  ON i.order_id = o.order_id
    JOIN raw.sellers s ON i.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_state, s.seller_id
) ranked
WHERE rank_in_state <= 3
ORDER BY seller_state, rank_in_state;