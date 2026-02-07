/* ============================================================
   PARTIE 2 : SQL AVANCÉ — ClassicModels
   Auteur : Pekgoz Can
   Date de rendue : 15/02/2026

   Objectif :
   - Utiliser des fonctionnalités SQL avancées :
     WINDOW FUNCTIONS, CTE récursif, jointures multiples,
     sous-requêtes corrélées, pivot, procédures, fonctions,
     triggers.
   - Documenter les résultats directement dans le script.
   ============================================================ */

USE classicmodels;

-- ============================================================
-- 1) Analyse des ventes par année (WINDOW FUNCTIONS)
-- Objectif :
--   - Calculer le chiffre d’affaires total par année
--   - Classer les années par CA (RANK)
--   - Calculer la part (%) de chaque année dans le total global
--
-- RESULTAT :
-- 2004 : 4515905.51,	1	(47.02 %)
-- 2003	: 3317348.39,	2	(34.54 %)
-- 2005	: 1770936.71,	3	(18.44 %)
--   - Vérification : somme des pourcentages ≈ 100 %
-- ============================================================
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


-- ============================================================
-- 2) Analyse temporelle avec moyenne mobile (WINDOW FUNCTION)
-- Objectif :
--   - Calculer les ventes par trimestre
--   - Lisser la série temporelle avec une moyenne mobile
--     sur 3 périodes (2 précédentes + période courante)
--
-- RESULTAT : (years, quarter, total_sales, moving_average_3_periods)

/*
2003	1	405613.55	405613.55
2003	2	515754.91	460684.23
2003	3	616895.32	512754.59
2003	4	1779084.61	970578.28
2004	1	799579.31	1065186.41
2004	2	779271.81	1119311.91
2004	3	1028690.38	869180.50
2004	4	1908364.01	1238775.40
2005	1	984641.15	1307231.85
2005	2	786295.56	1226433.57                             
 */
--   - Observation : la moyenne mobile réduit les variations fortes entre trimestres.
-- ============================================================
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


-- ============================================================
-- 3) Hiérarchie organisationnelle (CTE récursif)
-- Objectif :
--   - Reconstituer l’organigramme de l’entreprise
--   - Identifier les niveaux hiérarchiques
--
-- RESULTAT :
--   - Nombre de niveaux hiérarchiques observés : 4
--   - Niveau 0 = top management (reportsTo IS NULL)
-- ============================================================
WITH RECURSIVE employee_hierarchy AS (
    SELECT
        employeeNumber,
        CONCAT(firstName, ' ', lastName) AS employee_name,
        reportsTo,
        0 AS level
    FROM employees
    WHERE reportsTo IS NULL

    UNION ALL

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


-- ============================================================
-- 4) Segmentation clients VIP (jointures multiples)
-- Tables utilisées :
--   customers, employees, orders, orderdetails, products
--
-- Objectif :
--   - Identifier les clients générant un CA élevé
--   - Associer chaque client à son commercial
--
-- Critère VIP :
--   - total_revenue > 100 000
--
-- RESULTAT :
--   - Nombre de clients VIP : 32
--   - Client VIP avec le plus de CA : 
/*
Euro+ Shopping Channel
Pays : Spain
Commercial : Gerard Hernandez
Nombre de commandes : 26
Chiffre d’affaires total : 820 689,54
*/
-- ============================================================
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


-- ============================================================
-- 5.1) Nouveaux clients par année (sous-requête corrélée)
-- Objectif :
--   - Identifier l’année de la première commande de chaque client
--   - Compter les nouveaux clients par année
--
-- RESULTAT :
--   - Année avec le plus de nouveaux clients : 2003 
-- ============================================================
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


-- ============================================================
-- 5.2) Clients récurrents (rétention simple)
-- Objectif :
--   - Identifier les clients ayant passé plus d’une commande
--   - Mesurer leur présence par année
--
-- RESULTAT :
--   - Année avec le plus de clients récurrents : 2004
-- ============================================================
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


-- ============================================================
-- 6) PIVOT : ventes par gamme et par trimestre
-- Objectif :
--   - Comparer les performances des gammes sur l’année
--
-- Classic Cars
-- Q1 = 868 487,88
-- Q2 = 798 229,99
-- Q3 = 690 564,27
-- Q4 = 1 496 640,35
-- Somme : 868 487,88 + 798 229,99 + 690 564,27 + 1 496 640,35 = 3 853 922,49
-- ============================================================
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
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
JOIN productlines pl ON p.productLine = pl.productLine
GROUP BY pl.productLine
ORDER BY total_sales DESC;


-- ============================================================
-- 7) Procédure stockée : calcul de commission employé
-- Objectif :
--   - Calculer le CA généré par un employé
--   - Calculer sa commission selon un taux donné
--
-- RESULTAT (test) :
--   CALL calculate_employee_commission(1401, 5.00);
--   → Vérifier : commission = total_revenue * taux / 100 --> 868220.55 * 5.00/100 = 43411.03 
-- ============================================================
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
        ROUND(SUM(od.quantityOrdered * od.priceEach)
              * p_commission_rate / 100, 2) AS commission_amount
    FROM employees e
    JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN orders o ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    WHERE e.employeeNumber = p_employeeNumber
    GROUP BY e.employeeNumber, employee_name;
END $$

DELIMITER ; 

SELECT
  e.employeeNumber,
  CONCAT(e.firstName, ' ', e.lastName) AS name,
  COUNT(c.customerNumber) AS nb_customers
FROM employees e
JOIN customers c ON c.salesRepEmployeeNumber = e.employeeNumber
GROUP BY e.employeeNumber, name
ORDER BY nb_customers DESC;

-- ============================================================
-- 8) Fonction : Customer Lifetime Value (CLV)
-- Objectif :
--   - Calculer le chiffre d’affaires total généré par un client
--
-- RESULTAT (test) : on prends le VIP avec le plus grand CA 
--   SELECT customer_lifetime_value(141);
-- ============================================================
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
        ROUND(SUM(od.quantityOrdered * od.priceEach)
              * p_commission_rate / 100, 2) AS commission_amount
    FROM employees e
    JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN orders o ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    WHERE e.employeeNumber = p_employeeNumber
    GROUP BY e.employeeNumber, employee_name;
END $$

DELIMITER ; 

SELECT
  e.employeeNumber,
  CONCAT(e.firstName, ' ', e.lastName) AS name,
  COUNT(c.customerNumber) AS nb_customers
FROM employees e
JOIN customers c ON c.salesRepEmployeeNumber = e.employeeNumber
GROUP BY e.employeeNumber, name
ORDER BY nb_customers DESC;

SELECT customer_lifetime_value(141);

-- ============================================================
-- 9) TRIGGERS
-- ============================================================

-- 9.1) Trigger : audit des nouvelles commandes
-- Objectif :
--   - Enregistrer toute nouvelle commande dans une table d’audit
--
-- RESULTAT :
--   - Après INSERT sur orders, une ligne est ajoutée dans order_audit_log
-- ============================================================
DROP TRIGGER IF EXISTS trg_order_audit;

DELIMITER $$

CREATE TRIGGER trg_order_audit
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    INSERT INTO order_audit_log(orderNumber, action_date)
    VALUES (NEW.orderNumber, NOW());
END $$

DELIMITER ;


-- 9.2) Trigger : validation du stock
-- Objectif :
--   - Empêcher la vente si le stock est insuffisant
--
-- RESULTAT :
--   - INSERT refusé si quantityOrdered > quantityInStock
-- ============================================================
DROP TRIGGER IF EXISTS trg_check_stock;

DELIMITER $$

CREATE TRIGGER trg_check_stock
BEFORE INSERT ON orderdetails
FOR EACH ROW
BEGIN
    DECLARE stock INT;

    SELECT quantityInStock
    INTO stock
    FROM products
    WHERE productCode = NEW.productCode;

    IF stock < NEW.quantityOrdered THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuffisant';
    END IF;
END $$

DELIMITER ;


-- 9.3) Trigger : mise à jour du statut / crédit client
-- Objectif :
--   - Mettre à jour les informations client après paiement
--
-- RESULTAT :
--   - creditLimit modifié après INSERT sur payments
-- ============================================================
DROP TRIGGER IF EXISTS trg_update_customer_status;

DELIMITER $$

CREATE TRIGGER trg_update_customer_status
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    UPDATE customers
    SET creditLimit = creditLimit + NEW.amount
    WHERE customerNumber = NEW.customerNumber;
END $$

DELIMITER ;
