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

-- 5.1) Nouveaux clients par année (sous-requête corrélée)
SELECT
    YEAR(o.orderDate) AS year,
    COUNT(DISTINCT o.customerNumber) AS new_customers
FROM orders o
WHERE o.orderDate = (
    SELECT MIN(o2.orderDate)
    FROM orders o2
    WHERE o2.customerNumber = o.customerNumber
)
GROUP BY YEAR(o.orderDate)
ORDER BY year;

-- 5.2) Clients récurrents (rétention) avec sous-requête corrélée
SELECT
    YEAR(o.orderDate) AS year,
    COUNT(DISTINCT o.customerNumber) AS returning_customers
FROM orders o
WHERE (
    SELECT COUNT(*)
    FROM orders o2
    WHERE o2.customerNumber = o.customerNumber
) > 1
GROUP BY YEAR(o.orderDate)
ORDER BY year;

-- 6) PIVOT : ventes par gamme de produits et par trimestre
SELECT
    pl.productLine,

    SUM(CASE WHEN QUARTER(o.orderDate) = 1
        THEN od.quantityOrdered * od.priceEach ELSE 0 END) AS Q1_sales,

    SUM(CASE WHEN QUARTER(o.orderDate) = 2
        THEN od.quantityOrdered * od.priceEach ELSE 0 END) AS Q2_sales,

    SUM(CASE WHEN QUARTER(o.orderDate) = 3
        THEN od.quantityOrdered * od.priceEach ELSE 0 END) AS Q3_sales,

    SUM(CASE WHEN QUARTER(o.orderDate) = 4
        THEN od.quantityOrdered * od.priceEach ELSE 0 END) AS Q4_sales,

    SUM(od.quantityOrdered * od.priceEach) AS total_sales

FROM orders o
JOIN orderdetails od
    ON o.orderNumber = od.orderNumber
JOIN products p
    ON od.productCode = p.productCode
JOIN productlines pl
    ON p.productLine = pl.productLine

GROUP BY pl.productLine
ORDER BY total_sales DESC;

USE classicmodels;

DROP PROCEDURE IF EXISTS calculate_employee_commission;

DELIMITER $$

CREATE PROCEDURE calculate_employee_commission (
    IN p_employeeNumber INT,
    IN p_commission_rate DECIMAL(5,2)
)
BEGIN
    SELECT
        e.employeeNumber,
        CONCAT(e.firstName, ' ', e.lastName) AS employee_name,
        SUM(od.quantityOrdered * od.priceEach) AS total_revenue,
        ROUND(SUM(od.quantityOrdered * od.priceEach) * p_commission_rate / 100, 2) AS commission_amount
    FROM employees e
    JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN orders o ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    WHERE e.employeeNumber = p_employeeNumber
    GROUP BY e.employeeNumber, employee_name;
END $$

DELIMITER ;
