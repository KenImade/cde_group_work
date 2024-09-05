-- 1. Which are the top 5 accounts by order amount?
SELECT
	a.name,
	ROUND(CAST(SUM(total_amt_usd) AS numeric), 2) AS total_amount
FROM orders o
LEFT JOIN accounts a
ON o.account_id = a.id
GROUP BY account_id, a.name
ORDER BY total_amount DESC
LIMIT 5

-- 2. Which sales reps are the top performers?
SELECT
	s.name as Sales_Rep_Name,
	ROUND(CAST(SUM(o.total_amt_usd) AS numeric), 2) AS Total_Revenue
FROM orders o
LEFT JOIN accounts a
ON o.account_id = a.id
LEFT JOIN sales_reps s
ON a.sales_rep_id = s.id
GROUP BY s.name
ORDER BY total_revenue desc, sales_rep_name
LIMIT 5

-- 3. Which year had the most sales?
SELECT
	EXTRACT(YEAR FROM occurred_at) AS year,
	ROUND(CAST(SUM(total_amt_usd) AS numeric),2) AS total_revenue
FROM orders
GROUP BY EXTRACT(YEAR FROM occurred_at)
ORDER BY total_revenue DESC

-- 4. Who are the top 5 accounts by quantity ordered?
SELECT
	a.name,
	SUM(total) AS total_quantity
FROM orders o
LEFT JOIN accounts a
ON o.account_id = a.id
GROUP BY account_id, a.name
ORDER BY total_quantity DESC
LIMIT 5

-- 5. Who are the top sales reps by region?
WITH sales_report AS (
		SELECT
			r.name,
			s.name AS sales_rep_name,
			ROUND(CAST(SUM(total_amt_usd) AS numeric), 2) AS total_sales
		FROM orders o
		LEFT JOIN accounts a
		ON o.account_id = a.id
		LEFT JOIN sales_reps s
		ON a.sales_rep_id = s.id
		LEFT JOIN region r
		on s.region_id = r.id
		GROUP BY r.name, s.name
), ranked_sales_rep AS (
	SELECT
		name AS region,
		sales_rep_name,
		total_sales,
		RANK() OVER(PARTITION BY name ORDER BY total_sales DESC) AS rnk
	FROM sales_report
)

SELECT
	region,
	sales_rep_name as sales_rep,
	total_sales
FROM ranked_sales_rep
WHERE rnk = 1

-- 6. What is the year on year change in sales?
SELECT
	year,
	total_revenue,
	ROUND(CAST(LAG(total_revenue) OVER(ORDER BY year) AS numeric), 2) AS previous_year_amount,
	ROUND(CAST((total_revenue - LAG(total_revenue) OVER (ORDER BY year)) / LAG(total_revenue) OVER (ORDER BY year) * 100 AS numeric), 2) AS yoy_growth_percentage
FROM (
	SELECT
		EXTRACT(YEAR FROM occurred_at) AS year,
		ROUND(CAST(SUM(total_amt_usd) AS numeric),2) AS total_revenue
	FROM orders
	GROUP BY EXTRACT(YEAR FROM occurred_at)
	ORDER BY year
)