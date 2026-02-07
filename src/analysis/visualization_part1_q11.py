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

QUERY_Q11 = """
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
    df = fetch_df(QUERY_Q11)

    df = df.sort_values("total_revenue", ascending=True)

    plt.figure(figsize=(10, 5))
    plt.barh(df["customerName"], df["total_revenue"])
    plt.title("Top 5 clients par chiffre d'affaires")
    plt.xlabel("Chiffre d'affaires (total_revenue)")
    plt.ylabel("Client")
    plt.tight_layout()

    out_path = os.path.join(OUTPUT_DIR, "part1_q11_top5_clients_ca.png")
    plt.savefig(out_path, dpi=200)
    print(f"✅ PNG généré: {out_path}")

if __name__ == "__main__":
    main()
