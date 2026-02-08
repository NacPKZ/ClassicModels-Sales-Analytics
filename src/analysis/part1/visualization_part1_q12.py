import os
import pandas as pd
import matplotlib.pyplot as plt
import mysql.connector
from dotenv import load_dotenv

load_dotenv()

MYSQL_HOST = os.getenv("MYSQL_HOST", "localhost")
MYSQL_USER = os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "classicmodels")

OUTPUT_DIR = os.path.join("visualizations", "part1")
os.makedirs(OUTPUT_DIR, exist_ok=True)

QUERY_Q12 = """
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
"""

def fetch_df(query: str) -> pd.DataFrame:
    cnx = mysql.connector.connect(
        host=MYSQL_HOST,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        database=MYSQL_DATABASE
    )
    try:
        df = pd.read_sql(query, cnx)
        return df
    finally:
        cnx.close()

def main():
    df = fetch_df(QUERY_Q12)

    name = df.loc[0, "employee_name"]
    revenue = df.loc[0, "total_revenue"]

    plt.figure(figsize=(7, 4))
    plt.bar([name], [revenue])
    plt.title("Employé ayant réalisé le plus de ventes (CA)")
    plt.xlabel("Employé")
    plt.ylabel("Chiffre d'affaires (total_revenue)")
    plt.tight_layout()

    out_path = os.path.join(OUTPUT_DIR, "part1_q12_best_employee_ca.png")
    plt.savefig(out_path, dpi=200)
    print(f"✅ PNG généré: {out_path}")

if __name__ == "__main__":
    main()
