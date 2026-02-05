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
