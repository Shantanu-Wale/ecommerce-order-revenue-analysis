USE ecom;
 
-- Script: Shantanu Wale
-- E-Commerce Order & Revenue Analysis
-- Dataset: 150 orders, 30 customers, 20 products | Feb-Mar 2026

 
 
-- Q1. Which category made the most revenue? (delivered orders only)
-- Result: Electronics topped at 603348.20 | Lenovo IdeaPad was the highest in that category
 
SELECT p.category, SUM(o.total_amount) AS revenue
FROM orders o 
JOIN products p ON p.product_id = o.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
ORDER BY revenue DESC;

-- drill down into electronics using window function
-- window function to show per-product revenue alongside category context
SELECT p.category, p.product_name, SUM(o.total_amount) OVER (PARTITION BY p.product_name) AS revenue
FROM orders o 
JOIN products p ON p.product_id = o.product_id
WHERE o.order_status = 'Delivered' AND p.category = 'Electronics'
ORDER BY revenue DESC;


-- Q2. Most preferred payment mode?
-- Result: UPI with 60 orders

SELECT 
payment_mode, COUNT(*) AS preffered_pay_mode
FROM orders
GROUP BY payment_mode
ORDER BY preffered_pay_mode DESC;


-- Q3. Top 5 customers by spending (delivered orders only)
-- Result: Nisha Agarwal 84481 | Prakash Sawant 70952 | Aarav Sharma 58714 | Divya Nair 56517 | Raju Pandey 53098

-- created a view to filter only delivered orders
CREATE OR REPLACE VIEW net_success_orders AS
SELECT * FROM orders
WHERE order_status = 'Delivered';

SELECT c.customer_name, SUM(total_amount) AS total_spend
FROM net_success_orders n_o
JOIN customers c ON c.customer_id = n_o.customer_id
GROUP BY c.customer_name
ORDER BY total_spend DESC
LIMIT 5;

-- same but for all orders regardless of status
SELECT c.customer_name, SUM(total_amount) AS total_spend
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY total_spend DESC
LIMIT 5;


-- Q4. Which region had the most revenue and orders?
-- Result: West region topped both

SELECT c.region, SUM(o.quantity) AS total_orders, SUM(o.total_amount) AS total_revenue
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.region
ORDER BY total_revenue DESC;


-- Q5. How much revenue was lost due to discounts?
-- Result: Potential 906618 | Earned 809275 | Loss due to discounts: 97342
 
SELECT 
    SUM(p.base_price * o.quantity) AS potential_revenue,
    SUM(o.total_amount) AS earned_revenue,
    AVG(o.discount) AS avg_discount,
    SUM(p.base_price * o.quantity) - SUM(o.total_amount) AS discount_loss
FROM orders o
JOIN products p ON p.product_id = o.product_id
WHERE o.order_status = 'Delivered' AND o.discount != 0;
 
 
-- Q6. February vs March — which month did better?
-- Result: February 475329 outperformed March despite fewer orders (higher avg order value)
 
SELECT MONTHNAME(order_date) AS month_, SUM(total_amount) AS revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY month_
ORDER BY revenue DESC;
 
 
-- Q7. Which product made high revenue but wasn't the highest in quantity sold?
-- used subquery with HAVING to find products below max quantity but sorted by revenue
 
SELECT p.product_name, SUM(o.total_amount) AS total_revenue, SUM(o.quantity) AS total_quantity
FROM orders o
JOIN products p ON p.product_id = o.product_id
GROUP BY p.product_id, p.product_name
HAVING total_quantity < (
    SELECT MAX(product_quantity) 
    FROM (SELECT SUM(quantity) AS product_quantity FROM orders GROUP BY product_id) q
)
ORDER BY total_revenue DESC;
 
-- alternative approach: sort by quantity first, then manually check revenue
SELECT p.product_name, SUM(o.quantity) AS total_quantity, SUM(o.total_amount) AS total_revenue
FROM orders o
JOIN products p ON p.product_id = o.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_quantity DESC
LIMIT 7;
 
 
-- Q8. Return and cancellation breakdown by category
 
SELECT p.category, o.order_status, COUNT(*) AS order_count
FROM orders o
JOIN products p ON p.product_id = o.product_id
GROUP BY o.order_status, p.category
ORDER BY order_count DESC;
 
 
-- view created for Power BI dashboard (delivered orders only)
CREATE OR REPLACE VIEW sales_view AS
SELECT 
    order_date,
    quantity,
    price_per_unit,
    quantity * price_per_unit AS amount,
    discount, 
    total_amount AS net_amount
FROM orders
WHERE order_status = 'Delivered';
 