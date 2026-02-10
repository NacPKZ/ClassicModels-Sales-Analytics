import os
import pandas as pd
import matplotlib.pyplot as plt
from src.analysis.db import get_connection

OUT_DIR = os.path.join("visualizations", "part2")
os.makedirs(OUT_DIR, exist_ok=True)

SQL = """
WITH RECURSIVE employee_hierarchy AS (
    SELECT employeeNumber, reportsTo, 0 AS level
    FROM employees
    WHERE reportsTo IS NULL
    UNION ALL
    SELECT e.employeeNumber, e.reportsTo, eh.level + 1
    FROM employees e
    JOIN employee_hierarchy eh ON e.reportsTo = eh.employeeNumber
)
SELECT level, COUNT(*) AS nb_employees
FROM employee_hierarchy
GROUP BY level
ORDER BY level;
"""

def main():
    cnx = get_connection()
    df = pd.read_sql(SQL, cnx)
    cnx.close()

    plt.figure()
    plt.bar(df["level"].astype(str), df["nb_employees"])
    plt.title("Partie 2 - Q3 : Nombre d'employés par niveau hiérarchique")
    plt.xlabel("Niveau (0 = top management)")
    plt.ylabel("Nombre d'employés")
    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "part2_q3_hierarchy_levels.png"), dpi=200)
    plt.close()

if __name__ == "__main__":
    main()
