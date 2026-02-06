-- PARTIE 2 : SQL AVANCÉ
-- 1) Analyse des ventes par année avec WINDOW FUNCTIONS

USE classicmodels;

WITH yearly_sales AS (
    SELECT
        YEAR(o.orderDate) AS year,
        SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY YEAR(o.orderDate)
)

SELECT
    year,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
    ROUND(
        total_sales / SUM(total_sales) OVER () * 100,
        2
    ) AS percentage_of_total
FROM yearly_sales
ORDER BY year;

-- 2) Analyse temporelle avec moyenne mobile (WINDOW FUNCTION)
WITH quarterly_sales AS (
    SELECT
        YEAR(o.orderDate) AS year,
        QUARTER(o.orderDate) AS quarter,
        SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY YEAR(o.orderDate), QUARTER(o.orderDate)
)

SELECT
    year,
    quarter,
    total_sales,
    ROUND(
        AVG(total_sales) OVER (
            ORDER BY year, quarter
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_average_3_periods
FROM quarterly_sales
ORDER BY year, quarter;
