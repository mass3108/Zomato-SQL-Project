SELECT * FROM customers
SELECT * FROM restaurants
SELECT * FROM orders
SELECT * FROM riders
SELECT * FROM deliveries

--Analysis Report

--Q1. Write a query to find the top 5 most frequently ordered dishes by customer called "Arjun Mehta" in the last 1 year.

SELECT customer_name, order_item, total_cnt
FROM(
SELECT customer_name,
order_item,
COUNT(*) AS total_cnt,
DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS rn
FROM orders o
INNER JOIN customers c
ON o.customer_id = c.customer_id
WHERE customer_name = 'Arjun Mehta'
AND order_date >= CURRENT_DATE - INTERVAL '1 Year'
GROUP BY customer_name, order_item
ORDER BY total_cnt DESC)
WHERE rn <= 5

--Q2. Identify the time slots during which the most orders are placed. based on 2-hour intervals.

SELECT 
CASE 
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
END AS time_slot,
COUNT(order_id) AS total_orders
FROM orders
GROUP BY time_slot
ORDER BY total_orders DESC

--Q3. Find the average order value per customer who has placed more than 750 orders.
-- Return customer_name, and aov(average order value)

SELECT customer_name,
ROUND(AVG(total_amount),2) AS aov
FROM orders o
INNER JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY c.customer_id
HAVING COUNT(*) > 750

-- Q4. List the customers who have spent more than 100K in total on food orders.
-- return customer_name, and customer_id!

SELECT customer_name,
SUM(total_amount) AS total_amount
FROM orders o
INNER JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY c.customer_id
HAVING SUM(total_amount) > 100000
ORDER BY total_amount DESC

-- Q5. Write a query to find orders that were placed but not delivered. 
-- Return each restaurant name, city and number of not delivered orders 

SELECT restaurant_name, city, 
COUNT(order_id) AS total_orders
FROM restaurants r
LEFT JOIN orders o
ON r.restaurant_id = o.restaurant_id
WHERE order_status = 'Not Fulfilled'
GROUP BY restaurant_name, city

--Q6. Rank restaurants by their total revenue from the last year, including their name, 
-- total revenue, and rank within their city.

SELECT *
FROM(
SELECT city, restaurant_name,  
SUM(total_amount) AS total_revenue,
DENSE_RANK() OVER(PARTITION BY city ORDER BY SUM(total_amount) DESC) AS rank
FROM restaurants r
INNER JOIN orders o
ON r.restaurant_id = o.restaurant_id
WHERE order_date >= CURRENT_DATE - INTERVAL '1 YEAR'
GROUP BY restaurant_name, city)
WHERE rank = 1

--Q7. Identify the most popular dish in each city based on the number of orders.

SELECT *
FROM(
SELECT city, order_item,
COUNT(order_id) AS total_orders,
DENSE_RANK() OVER(PARTITION BY city ORDER BY COUNT(order_id) DESC) AS rn
FROM restaurants r
INNER JOIN orders o
ON r.restaurant_id = o.restaurant_id
GROUP BY city, order_item)
WHERE rn = 1

--Q8. Find customers who haven’t placed an order in 2024 but did in 2023.

SELECT DISTINCT customer_id
FROM orders
WHERE EXTRACT(year from order_date) = 2023
AND customer_id NOT IN (SELECT DISTINCT customer_id
					    FROM orders
                        WHERE EXTRACT(year from order_date) = 2024)
						
-- Q9. Calculate and compare the order cancellation rate for each restaurant between the 
-- current year and the previous year.

WITH cancel_ratio_prev AS
(SELECT restaurant_name,
COUNT(o.order_id) AS total_orders,
COUNT(CASE WHEN delivery_id IS NULL THEN 1 END) AS not_delivered
FROM restaurants r
INNER JOIN orders o
ON r.restaurant_id = o.restaurant_id
LEFT JOIN deliveries d
ON o.order_id = d.order_id
WHERE EXTRACT(year from order_date) = 2023
GROUP BY restaurant_name),

cancel_ratio_current AS
(SELECT restaurant_name,
COUNT(o.order_id) AS total_orders,
COUNT(CASE WHEN delivery_id IS NULL THEN 1 END) AS not_delivered
FROM restaurants r
INNER JOIN orders o
ON r.restaurant_id = o.restaurant_id
LEFT JOIN deliveries d
ON o.order_id = d.order_id
WHERE EXTRACT(year from order_date) = 2024
GROUP BY restaurant_name)

SELECT cp.restaurant_name, 
CAST(cp.not_delivered AS FLOAT)/ CAST(cp.total_orders AS FLOAT) * 100 AS cancellation_ratio_prev,
CAST(cc.not_delivered AS FLOAT)/ CAST(cc.total_orders AS FLOAT) * 100 AS cancellation_ratio_curr
FROM cancel_ratio_prev cp
INNER JOIN cancel_ratio_current cc 
ON cp.restaurant_name = cc.restaurant_name

--Q10. Determine each rider's average delivery time.

SELECT rider_name,
AVG(EXTRACT(EPOCH from delivery_time))/60 AS average_delivery_time
FROM riders r
INNER JOIN deliveries d
ON r.rider_id = d.rider_id
WHERE delivery_status = 'Delivered'
GROUP BY rider_name

--Q11. Monthly Restaurant Growth Ratio: 
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining

WITH CTE AS
(SELECT restaurant_id, 
TO_CHAR(order_date, 'mm-yy') AS month,
COUNT(o.order_id) AS total_orders,
LAG(COUNT(o.order_id)) OVER(PARTITION BY o.restaurant_id ORDER BY TO_CHAR(order_date, 'mm-yy')) AS prev_month_orders
FROM orders o
INNER JOIN deliveries d
ON o.order_id = d.order_id
WHERE delivery_status = 'Delivered'
GROUP BY 1, 2
ORDER BY 1, 2)

SELECT restaurant_id, month, total_orders, prev_month_orders,
CAST((total_orders-prev_month_orders) AS FLOAT)/ CAST(prev_month_orders AS FLOAT) * 100 AS growth_ratio
FROM CTE

-- Q.12 Customer Segmentation: 
-- Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their total spending 
-- compared to the average order value (AOV). If a customer's total spending exceeds the AOV, 
-- label them as 'Gold'; otherwise, label them as 'Silver'. Write an SQL query to determine each segment's 
-- total number of orders and total revenue

SELECT category, 
SUM(total_orders) AS total_orders,
SUM(total_revenue) AS total_revenue
FROM(
SELECT customer_name,
COUNT(order_id) AS total_orders,
SUM(total_amount) AS total_revenue,
CASE 
WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
ELSE 'Silver'
END AS category
FROM customers c
INNER JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY customer_name)
GROUP BY 1

-- Q.13 Rider Monthly Earnings: 
-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.

SELECT rider_name, 
EXTRACT(month from order_date) AS month,
SUM(total_amount) *0.08 AS total_earnings
FROM riders r
INNER JOIN deliveries d
ON r.rider_id = d.rider_id
INNER JOIN orders o
ON d.order_id = o.order_id
GROUP BY rider_name, month
ORDER BY month

-- Q.14 Rider Ratings Analysis: 
-- Find the number of 5-star, 4-star, and 3-star ratings each rider has.
-- riders receive this rating based on delivery time.
-- If orders are delivered less than 15 minutes of order received time the rider get 5 star rating,
-- if they deliver 15 and 20 minute they get 4 star rating 
-- if they deliver after 20 minute they get 3 star rating.

SELECT rider_name, stars,
COUNT(*) AS total_cnt
FROM(
SELECT rider_name, delivery_total_time,
CASE WHEN delivery_total_time < 15 THEN '5 star'
WHEN delivery_total_time BETWEEN 15 AND 20 THEN '4 star'
WHEN delivery_total_time > 20 THEN '3 star'
END AS stars
FROM(
SELECT rider_name, o.order_id, order_time, delivery_time,
EXTRACT(EPOCH FROM (delivery_time - order_time) + 
CASE WHEN delivery_time < order_time THEN INTERVAL '1 Day'
ELSE INTERVAL '0 Day' END)/60 AS delivery_total_time
FROM riders r
INNER JOIN deliveries d
ON r.rider_id = d.rider_id
INNER JOIN orders o
ON d.order_id = o.order_id
WHERE delivery_status = 'Delivered'))
GROUP BY rider_name, stars
ORDER BY stars DESC


-- Q.15 Order Frequency by Day: 
-- Analyze order frequency per day of the week and identify the peak day for each restaurant.

SELECT *
FROM(
SELECT restaurant_name, 
TO_CHAR(order_date, 'Day') AS day_of_week,
COUNT(order_id) AS total_orders,
RANK() OVER(PARTITION BY restaurant_name ORDER BY COUNT(order_id) DESC) AS rn
FROM restaurants r
INNER JOIN orders o
ON r.restaurant_id = o.restaurant_id
GROUP BY 1, 2)
WHERE rn = 1

-- Q.16 Customer Lifetime Value (CLV): 
-- Calculate the total revenue generated by each customer over all their orders.

SELECT customer_name,
SUM(total_amount) AS total_revenue
FROM customers c
INNER JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY customer_name

-- Q.17 Monthly Sales Trends: 
-- Identify sales trends by comparing each month's total sales to the previous month.

SELECT 
EXTRACT(year from order_date) AS year,
EXTRACT(month from order_date) AS month,
SUM(total_amount) AS totaL_sales,
LAG(SUM(total_amount)) OVER(ORDER BY EXTRACT(year from order_date), EXTRACT(month from order_date)) AS prev_sales
FROM orders
GROUP BY 1, 2


-- Q.18 Rider Efficiency: 
-- Evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages.

WITH CTE AS
(SELECT rider_name,
EXTRACT(EPOCH FROM (d.delivery_time - o.order_time) 
+ CASE WHEN delivery_time < order_time THEN INTERVAL '1 Day'
ELSE INTERVAL '0 Day' END)/60 AS time_deliver
FROM riders r
INNER JOIN deliveries d
ON r.rider_id = d.rider_id
INNER JOIN orders o
ON o.order_id = d.order_id
WHERE delivery_status = 'Delivered'
),

avg_table AS
(SELECT rider_name,
AVG(time_deliver) AS avg
FROM CTE
GROUP BY 1)

SELECT 
MIN(avg) AS min_time,
MAX(avg) AS max_time
FROM avg_table

-- Q.19 Order Item Popularity: 
-- Track the popularity of specific order items over time and identify seasonal demand spikes.

SELECT season, order_item,
COUNT(order_item) AS total_cnt
FROM(
SELECT 
EXTRACT(month from order_date) AS month,
CASE 
WHEN EXTRACT(month from order_date) BETWEEN 4 AND 6 THEN 'spring'
WHEN EXTRACT(month from order_date) BETWEEN 7 AND 9 THEN 'summer'
ELSE 'winter'
END AS season,
order_item
FROM orders)
GROUP BY 1, 2
ORDER BY 2, 3 DESC


-- Q.20 Rank each city based on the total revenue for last year 2023 

SELECT city,
SUM(total_amount) AS total_revenue,
RANK() OVER(ORDER BY SUM(total_amount) DESC) AS rank
FROM restaurants r
INNER JOIN orders o
ON r.restaurant_id = o.restaurant_id
WHERE EXTRACT(year from order_date) = 2023
GROUP BY 1

-- Thank You
