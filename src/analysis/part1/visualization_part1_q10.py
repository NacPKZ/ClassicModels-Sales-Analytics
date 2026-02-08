import os
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import mysql.connector
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

# Dossier de sortie
OUT_DIR = Path("visualizations/part1")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Connexion MySQL
conn = mysql.connector.connect(
    host=os.getenv("MYSQL_HOST"),
    user=os.getenv("MYSQL_USER"),
    password=os.getenv("MYSQL_PASSWORD"),
    database=os.getenv("MYSQL_DATABASE"),
)

# =============================
# PARTIE 1 - Q10 : Top 10 produits les plus vendus (quantité)
# =============================
query = """
SELECT
  p.productCode,
  p.productName,
  SUM(od.quantityOrdered) AS total_quantity_sold
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.productName
ORDER BY total_quantity_sold DESC
LIMIT 10;
"""

df = pd.read_sql(query, conn)

# Graphique
plt.figure()
plt.barh(df["productName"], df["total_quantity_sold"])
plt.title("Top 10 produits les plus vendus (quantité)")
plt.xlabel("Quantité vendue")
plt.ylabel("Produit")
plt.gca().invert_yaxis()  # top 1 en haut
plt.tight_layout()

output_file = OUT_DIR / "part1_q10_top10_produits_quantite.png"
plt.savefig(output_file, dpi=200)
plt.close()

conn.close()

print("✅ Graphique généré :", output_file)
print("\nRésultats SQL :")
print(df.to_string(index=False))
