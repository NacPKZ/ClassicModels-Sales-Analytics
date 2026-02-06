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

-- 3) Hiérarchie organisationnelle avec CTE récursif
WITH RECURSIVE employee_hierarchy AS (
    -- Niveau 0 : employés sans manager (top management)
    SELECT
        employeeNumber,
        CONCAT(firstName, ' ', lastName) AS employee_name,
        reportsTo,
        0 AS level
    FROM employees
    WHERE reportsTo IS NULL

    UNION ALL

    -- Niveaux suivants : subordonnés
    SELECT
        e.employeeNumber,
        CONCAT(e.firstName, ' ', e.lastName) AS employee_name,
        e.reportsTo,
        eh.level + 1 AS level
    FROM employees e
    JOIN employee_hierarchy eh
        ON e.reportsTo = eh.employeeNumber
)

SELECT
    employeeNumber,
    employee_name,
    reportsTo,
    level
FROM employee_hierarchy
ORDER BY level, employee_name;

-- 4) Segmentation clients VIP avec jointures multiples (5 tables)
SELECT
    c.customerNumber,
    c.customerName,
    c.country,
    CONCAT(e.firstName, ' ', e.lastName) AS sales_rep,
    COUNT(DISTINCT o.orderNumber) AS nb_orders,
    SUM(od.quantityOrdered * od.priceEach) AS total_revenue
FROM customers c
JOIN employees e
    ON c.salesRepEmployeeNumber = e.employeeNumber
JOIN orders o
    ON c.customerNumber = o.customerNumber
JOIN orderdetails od
    ON o.orderNumber = od.orderNumber
JOIN products p
    ON od.productCode = p.productCode
GROUP BY
    c.customerNumber,
    c.customerName,
    c.country,
    sales_rep
HAVING total_revenue > 100000
ORDER BY total_revenue DESC;
