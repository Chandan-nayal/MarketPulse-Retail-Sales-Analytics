SELECT VERSION();

SHOW VARIABLES LIKE 'secure_file_priv';

CREATE DATABASE marketpulse_analytics;

USE marketpulse_analytics;

SELECT DATABASE();

CREATE TABLE IF NOT EXISTS orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp VARCHAR(30),
    order_approved_at VARCHAR(30),
    order_delivered_carrier_date VARCHAR(30),
    order_delivered_customer_date VARCHAR(30),
    order_estimated_delivery_date VARCHAR(30)
);

SHOW VARIABLES LIKE 'local_infile';

SHOW TABLES;

DESCRIBE orders;

ALTER TABLE orders
MODIFY order_status VARCHAR(30);
 
 SHOW VARIABLES LIKE 'local_infile';
 
 SELECT COUNT(*) FROM orders;
 
LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_orders_dataset.csv'
INTO TABLE marketpulse_analytics.orders
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status,
 order_purchase_timestamp, order_approved_at,
 order_delivered_carrier_date, order_delivered_customer_date,
 order_estimated_delivery_date);
 
 USE marketpulse_analytics;

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id,
 shipping_limit_date, price, freight_value);

SELECT COUNT(*) FROM order_items;
 
 CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, payment_sequential, payment_type,
 payment_installments, payment_value);

 
CREATE TABLE products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
); 

ALTER TABLE products
    MODIFY product_name_length INT NULL,
    MODIFY product_description_length INT NULL,
    MODIFY product_photos_qty INT NULL,
    MODIFY product_weight_g INT NULL,
    MODIFY product_length_cm INT NULL,
    MODIFY product_height_cm INT NULL,
    MODIFY product_width_cm INT NULL;
    
LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@product_id, @category, @name_len, @desc_len, @photos,
 @weight, @length, @height, @width)
SET
product_id = @product_id,
product_category_name = NULLIF(@category, ''),
product_name_length = NULLIF(@name_len, ''),
product_description_length = NULLIF(@desc_len, ''),
product_photos_qty = NULLIF(@photos, ''),
product_weight_g = NULLIF(@weight, ''),
product_length_cm = NULLIF(@length, ''),
product_height_cm = NULLIF(@height, ''),
product_width_cm = NULLIF(@width, '');

SELECT 'orders' AS table_name, COUNT(*) AS total_rows
FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'products', COUNT(*) FROM products;

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;
 
 SELECT
    COUNT(*) AS total_items,
    ROUND(SUM(price), 2) AS total_sales,
    ROUND(SUM(freight_value), 2) AS total_freight,
    ROUND(AVG(price), 2) AS avg_item_price
FROM order_items;

SELECT
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders
WHERE order_status = 'delivered'
LIMIT 10;

SELECT
    order_id,
    DATEDIFF(
        order_delivered_customer_date,
        order_purchase_timestamp
    ) AS delivery_days
FROM orders
WHERE order_status = 'delivered'
LIMIT 10;

SELECT
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered';

SELECT
    CASE
        WHEN order_delivered_customer_date
             <= order_estimated_delivery_date
        THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS total_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY delivery_status;

SELECT
    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date
                     <= order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS on_time_percentage
FROM orders
WHERE order_status = 'delivered';

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    ROUND(SUM(oi.price), 2) AS monthly_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;

SELECT
    p.product_category_name,
    COUNT(*) AS total_items,
    ROUND(SUM(oi.price), 2) AS total_sales
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY total_sales DESC
LIMIT 10;

SELECT
    op.payment_type,
    COUNT(*) AS total_payments,
    ROUND(SUM(op.payment_value), 2) AS total_payment_value
FROM order_payments op
JOIN orders o
    ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY op.payment_type
ORDER BY total_payment_value DESC;


SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;