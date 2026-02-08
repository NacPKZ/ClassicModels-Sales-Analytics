import os
import pandas as pd
import matplotlib.pyplot as plt
from db import get_connection

OUT_DIR = os.path.join("visualizations", "part2")
os.makedirs(OUT_DIR, exist_ok=True)

SQL = """
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
"""

def main():
    cnx = get_connection()
    df = pd.read_sql(SQL, cnx)
    cnx.close()

    df["period"] = df["year"].astype(str) + "-Q" + df["quarter"].astype(str)

    plt.figure()
    plt.plot(df["period"], df["total_sales"], marker="o", label="Ventes trimestrielles")
    plt.plot(df["period"], df["moving_average_3_periods"], marker="o", label="Moyenne mobile (3)")
    plt.title("Partie 2 - Q2 : Ventes trimestrielles & moyenne mobile")
    plt.xlabel("Période")
    plt.ylabel("Ventes")
    plt.xticks(rotation=45, ha="right")
    plt.legend()
    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "part2_q2_quarter_sales_moving_avg.png"), dpi=200)
    plt.close()

if __name__ == "__main__":
    main()
