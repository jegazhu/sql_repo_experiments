--How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) as Overall_customer_count
FROM subscriptions;

--What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT DATENAME(month, dateadd(month, month(start_date), -1)) as month,
       count(DISTINCT customer_id) as 'monthly distribution'
FROM subscriptions as su
INNER JOIN plans as pl
ON pl.plan_id = su.plan_id
WHERE plan_name = 'trial'
GROUP BY month(start_date);


--What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT MIN(pl.plan_name) as plan_name,
       count(customer_id) AS 'Count of Events'
FROM plans as pl
INNER JOIN subscriptions as su 
ON pl.plan_id = su.plan_id
WHERE year(start_date) > 2020
GROUP BY pl.plan_id
ORDER BY count(customer_id) ASC;

--What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
--I
SELECT MIN(plan_name) as 'plan', count(DISTINCT customer_id) as 'churned customers',
--     round(100 * count(DISTINCT customer_id) / (
--	   SELECT COUNT(DISTINCT customer_id) as 'Customers'
--	   FROM subscriptions),2) as 'churn %'
		CAST((100 * count(DISTINCT customer_id)/(
		SELECT COUNT(distinct customer_id) as 'Customers'
		FROM subscriptions)) as decimal(5,2)) as 'churn %'
FROM subscriptions su
INNER JOIN plans pl
ON su.plan_id = pl.plan_id
where pl.plan_id=4;

--II
WITH churned_cust AS
  (SELECT MIN(pl.plan_name) as 'plan',
          count(DISTINCT su.customer_id) AS distinct_customer_count,
          SUM(CASE
                  WHEN su.plan_id=4 THEN 1
                  ELSE 0
              END) AS churned_customer_count
   FROM subscriptions su
   JOIN plans pl
   ON pl.plan_id = su.plan_id)
SELECT *,
       --round(100*(churned_customer_count/distinct_customer_count), 2) AS churn_percentage
	   CAST((100 * (churned_customer_count)/(distinct_customer_count)) as decimal(5,2)) AS 'churn_percentage'
FROM churned_cust;

--How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH churned_after AS
  (SELECT *,
          LEAD(plan_id, 1) OVER(
		  PARTITION BY customer_id
           ORDER BY start_date) AS next_plan
   FROM subscriptions),
     churners AS
  (SELECT *
   FROM churned_after
   WHERE next_plan=4
     AND plan_id=0)
SELECT count(customer_id) AS 'churn after trial count',
       CAST(100 * count(customer_id)/ (SELECT count(DISTINCT customer_id) AS 'distinct customers'
										FROM subscriptions) as decimal(5,1)) AS 'churn percentage'
FROM churners;

--What is the number and percentage of customer plans after their initial free trial?
SELECT MIN(plan_name) as 'plan name',
       count(customer_id) as 'customer count',
       CAST(100 *count(DISTINCT customer_id) /
               (SELECT count(DISTINCT customer_id) AS 'unique customers'
                FROM subscriptions) as decimal(5,1)) AS '% customer'
FROM subscriptions su
JOIN plans pl
ON su.plan_id = pl.plan_id
WHERE pl.plan_name != 'trial'
GROUP BY pl.plan_name;
--ORDER BY CAST(pl.plan_id as varchar(4000));

--What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH five_plans AS 
  (SELECT *,
          row_number() over(PARTITION BY customer_id
                            ORDER BY start_date DESC) AS latest_plan
   FROM subscriptions
   WHERE start_date <='2020-12-31' )
SELECT pl.plan_id,
       MIN(pl.plan_name) as 'plan name',
       count(customer_id) AS customer_count,
       CAST(100 *count(DISTINCT customer_id) /
               (SELECT count(DISTINCT customer_id) AS 'unique customers'
                FROM subscriptions) as decimal(5,1)) AS '% customer'
FROM five_plans fp
JOIN plans pl
ON pl.plan_id = fp.plan_id
WHERE latest_plan = 1
GROUP BY pl.plan_id
ORDER BY pl.plan_id;

--How many customers have upgraded to an annual plan in 2020?
SELECT MIN(plan_id) as 'total plans',
       COUNT(DISTINCT customer_id) AS annual_plan_customer_count
FROM subscriptions
WHERE plan_id = 3
  AND year(start_date) = 2020;

--How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
--I
WITH trial_plan_customer_cte AS
  (SELECT *
   FROM subscriptions
   WHERE plan_id=0),
     annual_plan_customer_cte AS
  (SELECT *
   FROM subscriptions
   WHERE plan_id=3)
SELECT CAST(avg(datediff(DAYOFYEAR, trial_plan_customer_cte.start_date, annual_plan_customer_cte.start_date)) as decimal(5,2)) AS AVG_ConvDays
FROM trial_plan_customer_cte
INNER JOIN annual_plan_customer_cte 
ON trial_plan_customer_cte.customer_id = annual_plan_customer_cte.customer_id;

--II
WITH trial_plan_cte AS
  (SELECT *,
          first_value(start_date) over(PARTITION BY customer_id
                                       ORDER BY start_date) AS trial_plan_start_date
   FROM subscriptions)
SELECT round(avg(datediff(DAYOFYEAR, trial_plan_start_date, start_date)), 2)AS AVG_ConvDays
FROM trial_plan_cte
WHERE plan_id =3;

--Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

--30 days

WITH next_plan_cte AS
  (SELECT *,
          lead(start_date, 1) over(PARTITION BY customer_id
                                   ORDER BY start_date) AS next_plan_start_date,
          lead(plan_id, 1) over(PARTITION BY customer_id
                                ORDER BY start_date) AS next_plan
   FROM subscriptions),
     window_details_cte AS
  (SELECT *,
          DATEDIFF(MONTH, start_date, next_plan_start_date) AS days,
          ROUND(DATEDIFF(MONTH, start_date, next_plan_start_date), 2/30) AS w_30_days
   FROM next_plan_cte
   WHERE next_plan=3)
SELECT w_30_days,
       count(*) AS customer_count
FROM window_details_cte
GROUP BY w_30_days
ORDER BY w_30_days;

--60 days

WITH next_plan_cte AS
  (SELECT *,
          lead(start_date, 1) over(PARTITION BY customer_id
                                   ORDER BY start_date) AS next_plan_start_date,
          lead(plan_id, 1) over(PARTITION BY customer_id
                                ORDER BY start_date) AS next_plan
   FROM subscriptions),
     window_details_cte AS
  (SELECT *,
          DATEDIFF(MONTH, start_date, next_plan_start_date) AS days,
          ROUND(DATEDIFF(MONTH, start_date, next_plan_start_date), 2/60) AS w_60_days
   FROM next_plan_cte
   WHERE next_plan=3)
SELECT w_60_days,
       count(*) AS customer_count
FROM window_details_cte
GROUP BY w_60_days
ORDER BY w_60_days;

--How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH next_plan_cte AS
  (SELECT *,
          lead(plan_id, 1) over(PARTITION BY customer_id
                                ORDER BY start_date) AS next_plan
   FROM subscriptions)
SELECT count(*) AS downgrade_count
FROM next_plan_cte
WHERE plan_id=2 
	AND next_plan=1;


--description about each customer’s onboarding journey.
SELECT
  su.customer_id as customer,pl.plan_id as planid, pl.plan_name as nombre_plan,  su.start_date
FROM plans pl
JOIN subscriptions su
  ON pl.plan_id = su.plan_id
WHERE su.customer_id IN (1,2,11,13,15,16,18,19)