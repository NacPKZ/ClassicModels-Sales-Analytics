-- PARTIE 1 : Analyse exploratoire ClassicModels
-- Auteur : Pekgoz Can
-- Date de rendue : 15/02/2026

USE classicmodels;

-- 1) Combien de clients ?
SELECT COUNT(*) AS nb_clients FROM customers;

-- 2) Combien d'employés ?
SELECT COUNT(*) AS nb_employees FROM employees;

-- 3) Combien de bureaux ?
SELECT COUNT(*) AS nb_offices FROM offices;

-- 4) Combien de commandes ?
SELECT COUNT(*) AS nb_orders FROM orders;

-- 5) Combien de produits ?
SELECT COUNT(*) AS nb_products FROM products;

-- 6) Combien de gammes de produits ?
SELECT COUNT(*) AS nb_productlines FROM productlines;

-- 7) Répartition géographique des clients (nombre de clients par pays)
SELECT
  country,
  COUNT(*) AS nb_clients
FROM customers
GROUP BY country
ORDER BY nb_clients DESC, country ASC;

-- 8) Nombre de commandes par statut
SELECT
  status,
  COUNT(*) AS nb_orders
FROM orders
GROUP BY status
ORDER BY nb_orders DESC, status ASC;

-- 9) Montant total des ventes et panier moyen par commande
SELECT
  SUM(t.order_total) AS total_sales,
  AVG(t.order_total) AS average_order_value
FROM (
  SELECT
    o.orderNumber,
    SUM(od.quantityOrdered * od.priceEach) AS order_total
  FROM orders o
  JOIN orderdetails od ON o.orderNumber = od.orderNumber
  GROUP BY o.orderNumber
) AS t;

-- 10) Top 10 produits les plus vendus (en quantité)
SELECT
  p.productCode,
  p.productName,
  SUM(od.quantityOrdered) AS total_quantity_sold
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.productName
ORDER BY total_quantity_sold DESC
LIMIT 10;

-- 11) Top 5 meilleurs clients par chiffre d'affaires
SELECT
  c.customerNumber,
  c.customerName,
  SUM(od.quantityOrdered * od.priceEach) AS total_revenue
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY c.customerNumber, c.customerName
ORDER BY total_revenue DESC
LIMIT 5;

-- 12) Employé ayant réalisé le plus de ventes
SELECT
  e.employeeNumber,
  CONCAT(e.firstName, ' ', e.lastName) AS employee_name,
  SUM(od.quantityOrdered * od.priceEach) AS total_revenue
FROM employees e
JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY e.employeeNumber, employee_name
ORDER BY total_revenue DESC
LIMIT 1;

-- 13) Gamme de produits la plus rentable
SELECT
  pl.productLine,
  SUM(od.quantityOrdered * od.priceEach) AS total_revenue
FROM productlines pl
JOIN products p ON pl.productLine = p.productLine
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY pl.productLine
ORDER BY total_revenue DESC;
