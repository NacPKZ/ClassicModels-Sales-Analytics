/* ============================================================
   PARTIE 1 : Analyse exploratoire ClassicModels
   Auteur : Pekgoz Can
   Date de rendue : 15/02/2026
   ============================================================ */

USE classicmodels;

-- ============================================================
-- 1) Combien de clients ?
-- Objectif : obtenir le nombre total de clients dans la base.
-- RESULTAT: 122 clients
-- ============================================================
SELECT COUNT(*) AS nb_clients
FROM customers;


-- ============================================================
-- 2) Combien d'employés ?
-- Objectif : obtenir le nombre total d’employés.
-- RESULTAT: 23 employés
-- ============================================================
SELECT COUNT(*) AS nb_employees
FROM employees;


-- ============================================================
-- 3) Combien de bureaux ?
-- Objectif : obtenir le nombre total de bureaux (offices).
-- RESULTAT: 7 bureaux
-- ============================================================
SELECT COUNT(*) AS nb_offices
FROM offices;


-- ============================================================
-- 4) Combien de commandes ?
-- Objectif : obtenir le nombre total de commandes.
-- RESULTAT: 326 commandes
-- ============================================================
SELECT COUNT(*) AS nb_orders
FROM orders;


-- ============================================================
-- 5) Combien de produits ?
-- Objectif : obtenir le nombre total de produits.
-- RESULTAT: 110 produits
-- ============================================================
SELECT COUNT(*) AS nb_products
FROM products;


-- ============================================================
-- 6) Combien de gammes de produits ?
-- Objectif : compter le nombre de gammes (productlines).
-- RESULTAT: 7 gammes
-- ============================================================
SELECT COUNT(*) AS nb_productlines
FROM productlines;


-- ============================================================
-- 7) Répartition géographique des clients (nombre par pays)
-- Objectif : identifier les pays avec le plus de clients.
-- RESULTAT: voir tableau (pays + nb_clients) -> EX : USA=36, France=12, South Africa=1
-- Remarque : tri par nb_clients DESC puis country ASC.
-- ============================================================
SELECT
  country,
  COUNT(*) AS nb_clients
FROM customers
GROUP BY country
ORDER BY nb_clients DESC, country ASC;


-- ============================================================
-- 8) Nombre de commandes par statut
-- Objectif : vérifier la distribution des statuts de commande.
-- RESULTAT: voir tableau (status + nb_orders)  -> EX : Shipped=303, On Hold=4, Disputed=3
-- ============================================================
SELECT
  status,
  COUNT(*) AS nb_orders
FROM orders
GROUP BY status
ORDER BY nb_orders DESC, status ASC;


-- ============================================================
-- 9) Montant total des ventes et panier moyen par commande
-- Objectif :
--   - total_sales = somme de toutes les lignes de commande
--   - average_order_value = moyenne des totaux par commande
-- Méthode :
--   (1) calcul du total par commande (order_total)
--   (2) agrégation finale SUM et AVG
-- RESULTAT:
--   total_sales = 9604190.61
--   average_order_value = 29460.707393
-- ============================================================
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


-- ============================================================
-- 10) Top 10 produits les plus vendus (en quantité)
-- Objectif : identifier les produits avec la plus grande quantité vendue.
-- RESULTAT: voir top 10 (productCode, productName, total_quantity_sold)
-- TOP1 : S18_3232, 1992 Ferrari 360 Spider red,	1808
-- TOP10 :S24_3856,	1956 Porsche 356A Coupe,	1052
-- ============================================================
SELECT
  p.productCode,
  p.productName,
  SUM(od.quantityOrdered) AS total_quantity_sold
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.productName
ORDER BY total_quantity_sold DESC
LIMIT 10;


-- ============================================================
-- 11) Top 5 meilleurs clients par chiffre d'affaires
-- Objectif : classer les clients selon le CA généré.
-- RESULTAT: voir top 5 (customerNumber, customerName, total_revenue)
-- TOP1 : 141,	Euro+ Shopping Channel,	820689.54
-- ============================================================
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


-- ============================================================
-- 12) Employé ayant réalisé le plus de ventes
-- Objectif : trouver le salesRep avec le plus de CA.
-- RESULTAT:
--   employeeNumber = 1370
--   employee_name  = Gerard Hernandez
--   total_revenue  = 1258577.81
-- ============================================================
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


-- ============================================================
-- 13) Gamme de produits la plus rentable
-- Objectif : identifier la productLine générant le plus de CA.
-- RESULTAT:
--   productLine   = Classic Cars
--   total_revenue = 3853922.49
-- Remarque : ICI on veut uniquement la #1, donc ajout de "LIMIT 1",
-- sinon pour le tableau dans son ensemble on enleve.
-- ============================================================
SELECT
  pl.productLine,
  SUM(od.quantityOrdered * od.priceEach) AS total_revenue
FROM productlines pl
JOIN products p ON pl.productLine = p.productLine
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY pl.productLine
ORDER BY total_revenue DESC
LIMIT 1;
