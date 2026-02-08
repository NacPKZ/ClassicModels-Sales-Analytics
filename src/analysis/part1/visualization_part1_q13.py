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

QUERY_Q13 = """
SELECT
  pl.productLine,
  SUM(od.quantityOrdered * od.priceEach) AS total_revenue
FROM productlines pl
JOIN products p ON pl.productLine = p.productLine
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY pl.productLine
ORDER BY total_revenue DESC;
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
    df = fetch_df(QUERY_Q13)

    df = df.sort_values("total_revenue", ascending=True)

    plt.figure(figsize=(10, 6))
    plt.barh(df["productLine"], df["total_revenue"])
    plt.title("Chiffre d'affaires par gamme de produits")
    plt.xlabel("Chiffre d'affaires (total_revenue)")
    plt.ylabel("Gamme (productLine)")
    plt.tight_layout()

    out_path = os.path.join(OUTPUT_DIR, "part1_q13_ca_par_gamme.png")
    plt.savefig(out_path, dpi=200)
    print(f"✅ PNG généré: {out_path}")

if __name__ == "__main__":
    main()
