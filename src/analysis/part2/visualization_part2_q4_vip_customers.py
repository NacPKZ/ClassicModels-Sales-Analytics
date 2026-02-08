import os
import pandas as pd
import matplotlib.pyplot as plt
from db import get_connection

OUT_DIR = os.path.join("visualizations", "part2")
os.makedirs(OUT_DIR, exist_ok=True)

SQL = """
SELECT
    c.customerNumber,
    c.customerName,
    c.country,
    CONCAT(e.firstName, ' ', e.lastName) AS sales_rep,
    COUNT(DISTINCT o.orderNumber) AS nb_orders,
    SUM(od.quantityOrdered * od.priceEach) AS total_revenue
FROM customers c
JOIN employees e ON c.salesRepEmployeeNumber = e.employeeNumber
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
GROUP BY c.customerNumber, c.customerName, c.country, sales_rep
HAVING total_revenue > 100000
ORDER BY total_revenue DESC;
"""

def main():
    cnx = get_connection()
    df = pd.read_sql(SQL, cnx)
    cnx.close()

    top = df.head(15).copy()
    top = top.sort_values("total_revenue", ascending=True)

    plt.figure()
    plt.barh(top["customerName"], top["total_revenue"])
    plt.title("Partie 2 - Q4 : Top 15 clients VIP (CA > 100k)")
    plt.xlabel("Chiffre d'affaires")
    plt.ylabel("Client")
    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "part2_q4_top15_vip_customers.png"), dpi=200)
    plt.close()

if __name__ == "__main__":
    main()
