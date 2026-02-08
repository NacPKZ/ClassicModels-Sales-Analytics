import os
from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt
import mysql.connector
from dotenv import load_dotenv

# 1) Je charge .env
load_dotenv()

# 2) Dossier de sortie des images
OUT_DIR = Path("visualizations/part1")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# 3) Connexion MySQL
conn = mysql.connector.connect(
    host=os.getenv("MYSQL_HOST", "localhost"),
    user=os.getenv("MYSQL_USER", "root"),
    password=os.getenv("MYSQL_PASSWORD", ""),
    database=os.getenv("MYSQL_DATABASE", "classicmodels"),
)

# 4) Requête (Partie 1 - Q7)
query = """
SELECT country, COUNT(*) AS nb_clients
FROM customers
GROUP BY country
ORDER BY nb_clients DESC, country ASC;
"""

df = pd.read_sql(query, conn)
conn.close()

# On garde les 15 premiers pays (sinon illisible)
df_top = df.head(15).copy()

# 5) Graphique
plt.figure()
plt.bar(df_top["country"], df_top["nb_clients"])
plt.xticks(rotation=45, ha="right")
plt.title("Répartition des clients par pays (Top 15)")
plt.xlabel("Pays")
plt.ylabel("Nombre de clients")
plt.tight_layout()

# 6) Sauvegarde
out_file = OUT_DIR / "part1_q7_clients_par_pays_top15.png"
plt.savefig(out_file, dpi=200)
plt.close()

print(f"✅ Graphique généré : {out_file}")
print("\nAperçu des données (Top 10):")
print(df.head(10).to_string(index=False))
