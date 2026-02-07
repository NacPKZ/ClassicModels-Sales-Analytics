import os
import pandas as pd
import matplotlib.pyplot as plt
from db import get_connection

OUT_DIR = os.path.join("visualizations", "part2")
os.makedirs(OUT_DIR, exist_ok=True)

SQL_NEW = """
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
"""

SQL_RETURNING = """
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
"""

def main():
    cnx = get_connection()
    df_new = pd.read_sql(SQL_NEW, cnx)
    df_ret = pd.read_sql(SQL_RETURNING, cnx)
    cnx.close()

    df = pd.merge(df_new, df_ret, on="year", how="outer").fillna(0).sort_values("year")

    plt.figure()
    plt.plot(df["year"], df["new_customers"], marker="o", label="Nouveaux clients")
    plt.plot(df["year"], df["returning_customers"], marker="o", label="Clients récurrents")
    plt.title("Partie 2 - Q5 : Nouveaux vs Récurrents par année")
    plt.xlabel("Année")
    plt.ylabel("Nombre de clients")
    plt.xticks(df["year"])
    plt.legend()
    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "part2_q5_new_vs_returning.png"), dpi=200)
    plt.close()

if __name__ == "__main__":
    main()
