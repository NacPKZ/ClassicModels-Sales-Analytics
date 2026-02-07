import os
import pandas as pd
import matplotlib.pyplot as plt
from db import get_connection

OUT_DIR = os.path.join("visualizations", "part2")
os.makedirs(OUT_DIR, exist_ok=True)

SQL = """
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
    ROUND(total_sales / SUM(total_sales) OVER () * 100, 2) AS percentage_of_total
FROM yearly_sales
ORDER BY year;
"""

def main():
    cnx = get_connection()
    df = pd.read_sql(SQL, cnx)
    cnx.close()

    # Graph 1: bar ventes / année
    plt.figure()
    plt.bar(df["year"].astype(str), df["total_sales"])
    plt.title("Partie 2 - Q1 : Ventes totales par année")
    plt.xlabel("Année")
    plt.ylabel("Ventes (total)")
    plt.xticks(rotation=45, ha="right")
    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "part2_q1_sales_par_annee.png"), dpi=200)
    plt.close()

    # Graph 2: part (%) du total
    plt.figure()
    plt.plot(df["year"], df["percentage_of_total"], marker="o")
    plt.title("Partie 2 - Q1 : % des ventes totales par année")
    plt.xlabel("Année")
    plt.ylabel("% du total")
    plt.xticks(df["year"])
    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "part2_q1_pourcentage_du_total.png"), dpi=200)
    plt.close()

if __name__ == "__main__":
    main()
