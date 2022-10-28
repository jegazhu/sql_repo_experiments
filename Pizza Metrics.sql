--How many pizzas were ordered?
SELECT COUNT(*) AS pizza_ordered
FROM customer_orders;

--How many unique customer orders were made?
SELECT 
  COUNT(DISTINCT order_id) AS total_unique_orders
FROM customer_orders;

--How many successful orders were delivered by each runner?
SELECT 
  runner_id, 
  COUNT(order_id) AS delivered_orders
FROM runner_orders
WHERE distance != '0' 
GROUP BY runner_id;

--How many of each type of pizza was delivered?
SELECT 
  CAST(p.pizza_name as nvarchar(4000)) as Selection,
  COUNT(c.pizza_id) AS delivered_pizza_count
FROM customer_orders AS c
JOIN runner_orders AS r
  ON c.order_id = r.order_id
JOIN pizza_names AS p
  ON c.pizza_id = p.pizza_id
WHERE r.distance != '0'
GROUP BY CAST(p.pizza_name as nvarchar(4000));

--How many Vegetarian and Meatlovers were ordered by each customer?
SELECT  
	c.customer_id, 
	CAST(p.pizza_name as nvarchar(4000)),
	COUNT(c.pizza_id) as number_sold
from customer_orders c
JOIN pizza_names p 
	ON c.pizza_id = p.pizza_id
GROUP BY 
	c.customer_id, 
	CAST(p.pizza_name as nvarchar(4000));


--What was the maximum number of pizzas delivered in a single order?
WITH totpizza_delivered AS
(
  SELECT 
    c.order_id, 
    COUNT(c.pizza_id) AS pizza_per_order
  FROM customer_orders AS c
  JOIN runner_orders AS r
    ON c.order_id = r.order_id
  WHERE r.distance != '0'
  GROUP BY c.order_id
)

SELECT 
  *
FROM totpizza_delivered;

--For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
  c.customer_id as Customer,
  SUM(
    CASE WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL THEN 1
    ELSE 0
    END) AS with_change,
  SUM(
    CASE WHEN c.exclusions IS NULL AND c.extras IS NULL THEN 1 
    ELSE 0
    END) AS no_change
FROM customer_orders AS c
JOIN runner_orders AS r
  ON c.order_id = r.order_id
WHERE r.distance != '0'
GROUP BY c.customer_id
ORDER BY c.customer_id;

--How many pizzas were delivered that had both exclusions and extras?
SELECT  
  SUM(
    CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1
    ELSE 0
    END) AS pizza_count_w_exclusions_extras
FROM customer_orders AS c
JOIN runner_orders AS r
  ON c.order_id = r.order_id
WHERE r.distance >= '1'
  AND exclusions <> ' ' 
  AND extras <> ' ';

--What was the total volume of pizzas ordered for each hour of the day?
SELECT 
  DATEPART(HOUR, [order_time]) AS day_hr, 
  COUNT(order_id) AS total_pizza
FROM customer_orders
GROUP BY DATEPART(HOUR, [order_time]);

--What was the volume of orders for each day of the week?
SELECT 
  FORMAT(DATEADD(DAY, 2, order_time),'dddd') AS day_of_week, -- add 2 to adjust 1st day of the week as Monday
  COUNT(order_id) AS total_pizzas_ordered
FROM customer_orders
GROUP BY FORMAT(DATEADD(DAY, 2, order_time),'dddd');

