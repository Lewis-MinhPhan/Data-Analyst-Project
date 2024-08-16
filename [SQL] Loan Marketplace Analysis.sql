SELECT *
FROM banks;

SELECT *
FROM customer;

SELECT *
FROM leads;

SELECT *
FROM product;

-- Question a. Portfolio Management
-- Process: 
-- 1. Create a CTE_1 (name: 'monthly_approval')  to count the appoval and total status in each month for each source.
-- 2. Create a CTE_2 (name: 'cumulative_count') to count cumulative value for both 'all status' and 'approval status'.
-- 3. Now, simply calculate the cumulative approval rate = ( cumulative_approval * 100 ) / cumulative_total

WITH
monthly_approval AS(
	SELECT
		c.source,
		MONTH(l.apply_date) AS months,
		SUM(CASE WHEN latest_status = 'approved' THEN 1 ELSE 0 END) AS approved_count,
		COUNT(*) AS total_count
	FROM leads l
	JOIN customer c
		ON l.customer_id = c.customer_id
	WHERE
		SUBSTRING(l.apply_date,1,4) = '2023'
	GROUP BY 1,2
	ORDER BY 1,2
),

cumulative_count AS (
	SELECT
		source,
		months,
		SUM(approved_count) OVER (PARTITION BY source ORDER BY months) AS cumulative_approval,
		SUM(total_count) OVER (PARTITION BY source ORDER BY months) AS cumulative_total
	FROM monthly_approval
)

SELECT
	source,
    months,
    cumulative_approval,
    cumulative_total,
    (cumulative_approval * 100 / cumulative_total) AS cumulative_approval_rate
FROM cumulative_count;




-- Question b. Marketing
-- Process:
-- 1. Create the CTE_1 (name: 'percentage_leads_2022') to manually calculate 92.5% of customer age in 2022.
-- 2. Create the CTE_2 (name: 'leads_in_2023') to have a list of all leads in 2023.
-- 3. Now, simply query the customer name in 2023 that their age older than 92.5% of the age of leads who applied in 2022.

WITH 
percentage_leads_2022 AS (
	SELECT customer_age
	FROM (
	  SELECT c.customer_age,
			 PERCENT_RANK() OVER (ORDER BY customer_age) AS p
	  FROM customer c
		JOIN leads l
			ON c.customer_id = l.customer_id
		WHERE SUBSTRING(l.apply_date,1,4) = '2023'
	) AS ranked_data
	WHERE p <= 0.925
	ORDER BY p DESC
	LIMIT 1
),

leads_in_2023 AS (
	SELECT
		c.customer_name,
		c.customer_age,
		l.apply_date
	FROM customer c
	JOIN leads l
		ON c.customer_id = l.customer_id
	WHERE SUBSTRING(l.apply_date,1,4) = '2023'
	ORDER BY l.apply_date
)

SELECT l2023.customer_name
FROM leads_in_2023 l2023
JOIN percentage_leads_2022 p2022
	ON l2023.customer_age > p2022.customer_age;




-- Question e. The race of products
-- Process:
-- 1. Create the CTE_1 (name: 'monthly_application') to count applications by each month for each product. 
-- 2. Create the CTE_2 (name: 'define_high_risk_application') to count high-risk applications by each month for each product.
-- 3. Create the CTE_3 (name: 'rank_good_product') to rank the product that has the highest amount of applications and the lowest high-risk number of applications
-- 4. Now, simply query the information with 1st ranking

WITH
good_product AS (
	SELECT
		date_format(l.apply_date, '%Y-%m') AS months,
		p.product_id,
		p.product_name,
		COUNT(*) AS applications
	FROM product p
	JOIN leads l
		ON p.product_id = l.product_id
	WHERE SUBSTRING(l.apply_date,1,4) = '2023'
	GROUP BY p.product_id, months, p.product_name
    HAVING applications >= 100000
    ORDER BY p.product_id, months
),

define_high_risk_application AS (
	SELECT
		gp.months,
		gp.product_id,
		gp.product_name,
		gp.applications,
		(SELECT COUNT(*)
			FROM leads l
			JOIN customer c
				ON l.customer_id = c.customer_id
			WHERE c.estimated_risk_level = 'high'
			AND gp.product_id = l.product_id
		) AS high_risk_applications
	FROM good_product gp
),

rank_good_product AS (
SELECT
	*,
    RANK() OVER(PARTITION BY months ORDER BY applications DESC, high_risk_applications ASC) AS product_rank
FROM define_high_risk_application
)

SELECT
	months,
    COUNT(DISTINCT product_name) AS no_good_products,
    product_name AS best_product,
    applications AS maximim_applications
FROM rank_good_product
WHERE product_rank = 1
GROUP BY product_id, months, product_name
ORDER BY months;
