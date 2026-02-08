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
# PARTIE 1 - Q8 : Commandes par statut
# =============================
query = """
SELECT status, COUNT(*) AS nb_orders
FROM orders
GROUP BY status
ORDER BY nb_orders DESC;
"""

df = pd.read_sql(query, conn)

# Graphique
plt.figure()
plt.bar(df["status"], df["nb_orders"])
plt.title("Nombre de commandes par statut")
plt.xlabel("Statut")
plt.ylabel("Nombre de commandes")
plt.tight_layout()

output_file = OUT_DIR / "part1_q8_orders_par_statut.png"
plt.savefig(output_file, dpi=200)
plt.close()

conn.close()

print("✅ Graphique généré :", output_file)
print("\nRésultats SQL :")
print(df.to_string(index=False))
