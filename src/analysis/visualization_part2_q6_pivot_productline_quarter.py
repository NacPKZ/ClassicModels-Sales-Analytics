import os
import pandas as pd
import matplotlib.pyplot as plt
from db import get_connection

OUT_DIR = os.path.join("visualizations", "part2")
os.makedirs(OUT_DIR, exist_ok=True)

SQL = """
SELECT
    pl.productLine,
    SUM(CASE WHEN QUARTER(o.orderDate) = 1 THEN od.quantityOrdered * od.priceEach ELSE 0 END) AS Q1_sales,
    SUM(CASE WHEN QUARTER(o.orderDate) = 2 THEN od.quantityOrdered * od.priceEach ELSE 0 END) AS Q2_sales,
    SUM(CASE WHEN QUARTER(o.orderDate) = 3 THEN od.quantityOrdered * od.priceEach ELSE 0 END) AS Q3_sales,
    SUM(CASE WHEN QUARTER(o.orderDate) = 4 THEN od.quantityOrdered * od.priceEach ELSE 0 END) AS Q4_sales,
    SUM(od.quantityOrdered * od.priceEach) AS total_sales
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
JOIN productlines pl ON p.productLine = pl.productLine
GROUP BY pl.productLine
ORDER BY total_sales DESC;
"""

def main():
    cnx = get_connection()
    df = pd.read_sql(SQL, cnx)
    cnx.close()

    quarters = ["Q1_sales", "Q2_sales", "Q3_sales", "Q4_sales"]
    mat = df[quarters].values
    labels = df["productLine"].tolist()

    plt.figure()
    plt.imshow(mat, aspect="auto")
    plt.title("Partie 2 - Q6 : Ventes par gamme et trimestre (heatmap)")
    plt.yticks(range(len(labels)), labels)
    plt.xticks(range(4), ["Q1", "Q2", "Q3", "Q4"])
    plt.xlabel("Trimestre")
    plt.ylabel("Gamme")
    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "part2_q6_heatmap_productline_quarters.png"), dpi=200)
    plt.close()

if __name__ == "__main__":
    main()
