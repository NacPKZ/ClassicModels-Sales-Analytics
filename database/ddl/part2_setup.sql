USE classicmodels;

-- =========================
-- PARTIE 2 - SETUP (DDL)
-- Fonctions / Procédures / Triggers
-- =========================

-- 0) Colonne customerStatus 
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS customerStatus VARCHAR(20) DEFAULT 'Regular';

-- NOTE: si IF NOT EXISTS n'est pas supporté par la version MySQL,
-- un commentaire sera mis et on pourra l'exécuter à la main.

-- 0) Fonction : customer_lifetime_value
DROP FUNCTION IF EXISTS customer_lifetime_value;
DELIMITER $$
CREATE FUNCTION customer_lifetime_value(p_customerNumber INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE clv DECIMAL(15,2);

    SELECT IFNULL(SUM(od.quantityOrdered * od.priceEach), 0)
    INTO clv
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    WHERE o.customerNumber = p_customerNumber;

    RETURN clv;
END $$
DELIMITER ;

USE classicmodels;

-- =====================================================
-- 1) PROCÉDURE : calculate_employee_commission
-- =====================================================
DROP PROCEDURE IF EXISTS calculate_employee_commission;
DELIMITER $$

CREATE PROCEDURE calculate_employee_commission(
    IN p_employeeNumber INT,
    IN p_commission_rate DECIMAL(5,2)
)
BEGIN
    SELECT
        e.employeeNumber,
        CONCAT(e.firstName, ' ', e.lastName) AS employee_name,
        SUM(od.quantityOrdered * od.priceEach) AS total_revenue,
        ROUND(
            SUM(od.quantityOrdered * od.priceEach) * p_commission_rate / 100,
            2
        ) AS commission_amount
    FROM employees e
    JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN orders o ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    WHERE e.employeeNumber = p_employeeNumber
    GROUP BY e.employeeNumber, employee_name;
END $$

DELIMITER ;

-- =====================================================
-- 2) PROCÉDURE : reserve_stock
-- =====================================================
DROP PROCEDURE IF EXISTS reserve_stock;
DELIMITER $$

CREATE PROCEDURE reserve_stock(
    IN p_productCode VARCHAR(15),
    IN p_quantity INT
)
BEGIN
    DECLARE current_stock INT;

    SELECT quantityInStock
    INTO current_stock
    FROM products
    WHERE productCode = p_productCode;

    IF current_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuffisant pour ce produit';
    ELSE
        UPDATE products
        SET quantityInStock = quantityInStock - p_quantity
        WHERE productCode = p_productCode;

        SELECT
            p_productCode AS productCode,
            p_quantity AS reserved_quantity,
            (current_stock - p_quantity) AS new_stock;
    END IF;
END $$

DELIMITER ;

-- =====================================================
-- 3) TABLE + TRIGGER : orders_audit
-- =====================================================
DROP TABLE IF EXISTS orders_audit;

CREATE TABLE orders_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    orderNumber INT,
    action_type VARCHAR(10),
    action_date DATETIME
);

DROP TRIGGER IF EXISTS trg_orders_audit_insert;
DELIMITER $$

CREATE TRIGGER trg_orders_audit_insert
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    INSERT INTO orders_audit(orderNumber, action_type, action_date)
    VALUES (NEW.orderNumber, 'INSERT', NOW());
END $$

DELIMITER ;

-- =====================================================
-- 4) TRIGGER : check_stock_before_insert
-- =====================================================
DROP TRIGGER IF EXISTS trg_check_stock_before_insert;
DELIMITER $$

CREATE TRIGGER trg_check_stock_before_insert
BEFORE INSERT ON orderdetails
FOR EACH ROW
BEGIN
    DECLARE current_stock INT;

    SELECT quantityInStock
    INTO current_stock
    FROM products
    WHERE productCode = NEW.productCode;

    IF current_stock < NEW.quantityOrdered THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuffisant pour ce produit';
    END IF;
END $$

DELIMITER ;

-- =====================================================
-- 5) COLONNE customerStatus + TRIGGER update_customer_status
-- =====================================================
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS customerStatus VARCHAR(20) DEFAULT 'Regular';

DROP TRIGGER IF EXISTS trg_update_customer_status;
DELIMITER $$

CREATE TRIGGER trg_update_customer_status
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE total_paid DECIMAL(15,2);

    SELECT IFNULL(SUM(amount), 0)
    INTO total_paid
    FROM payments
    WHERE customerNumber = NEW.customerNumber;

    IF total_paid >= 100000 THEN
        UPDATE customers
        SET customerStatus = 'VIP'
        WHERE customerNumber = NEW.customerNumber;
    ELSE
        UPDATE customers
        SET customerStatus = 'Regular'
        WHERE customerNumber = NEW.customerNumber;
    END IF;
END $$

DELIMITER ;

-- =====================================================
-- (RAJOUT CAR OUBLIE) 6) FUNCTION : customer_lifetime_value (CLV)
-- =====================================================
DROP FUNCTION IF EXISTS customer_lifetime_value;
DELIMITER $$

CREATE FUNCTION customer_lifetime_value(p_customerNumber INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE clv DECIMAL(15,2);

    SELECT IFNULL(SUM(od.quantityOrdered * od.priceEach), 0)
    INTO clv
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    WHERE o.customerNumber = p_customerNumber;

    RETURN clv;
END $$

DELIMITER ;
