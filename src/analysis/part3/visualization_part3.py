import os
from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt
from dotenv import load_dotenv
from mysql.connector.pooling import MySQLConnectionPool

import plotly.express as px


# ============================================================
# CONFIG
# ============================================================
load_dotenv()

MYSQL_HOST = os.getenv("MYSQL_HOST", "localhost")
MYSQL_USER = os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "classicmodels")

OUT_DIR = Path("visualizations/part3")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Matplotlib look "pro" sans surcharger
try:
    plt.style.use("seaborn-v0_8")
except Exception:
    pass

POOL = MySQLConnectionPool(
    pool_name="classicmodels_pool",
    pool_size=5,
    host=MYSQL_HOST,
    user=MYSQL_USER,
    password=MYSQL_PASSWORD,
    database=MYSQL_DATABASE,
)


def fetch_df(sql: str, params=None) -> pd.DataFrame:
    """
    Exécute une requête SQL via pool + requête paramétrée.
    """
    conn = POOL.get_connection()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(sql, params or ())
        rows = cur.fetchall()
        return pd.DataFrame(rows)
    finally:
        try:
            cur.close()
        except Exception:
            pass
        conn.close()


def save_png(filename: str):
    path = OUT_DIR / filename
    plt.tight_layout()
    plt.savefig(path, dpi=220)
    plt.close()
    print(f"[OK] PNG saved: {path}")


def save_html(fig, filename: str):
    path = OUT_DIR / filename
    fig.write_html(str(path))
    print(f"[OK] HTML saved: {path}")


# ============================================================
# (1) Évolution temporelle des ventes (mois + trimestre)
# ============================================================
def sales_by_month():
    sql = """
    SELECT
        DATE_FORMAT(o.orderDate, '%Y-%m') AS month,
        SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY month
    ORDER BY month;
    """
    df = fetch_df(sql)
    df["month"] = pd.to_datetime(df["month"])
    df = df.sort_values("month")

    # Matplotlib PNG
    plt.figure(figsize=(10, 5))
    plt.plot(df["month"], df["total_sales"], marker="o", linewidth=2)
    plt.title("Évolution des ventes (par mois)")
    plt.xlabel("Mois")
    plt.ylabel("Chiffre d'affaires")
    plt.grid(alpha=0.25)
    save_png("p3_01_sales_by_month.png")

    # Plotly HTML
    fig = px.line(df, x="month", y="total_sales", markers=True,
                  title="Évolution des ventes (par mois)")
    fig.update_layout(xaxis_title="Mois", yaxis_title="Chiffre d'affaires")
    save_html(fig, "p3_01_sales_by_month.html")


def sales_by_quarter():
    sql = """
    SELECT
        YEAR(o.orderDate) AS year,
        QUARTER(o.orderDate) AS quarter,
        SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY year, quarter
    ORDER BY year, quarter;
    """
    df = fetch_df(sql)
    df["period"] = df["year"].astype(str) + "-Q" + df["quarter"].astype(str)

    # Matplotlib PNG
    plt.figure(figsize=(10, 5))
    plt.plot(df["period"], df["total_sales"], marker="o", linewidth=2)
    plt.title("Évolution des ventes (par trimestre)")
    plt.xlabel("Trimestre")
    plt.ylabel("Chiffre d'affaires")
    plt.xticks(rotation=45, ha="right")
    plt.grid(alpha=0.25)
    save_png("p3_02_sales_by_quarter.png")

    # Plotly HTML
    fig = px.line(df, x="period", y="total_sales", markers=True,
                  title="Évolution des ventes (par trimestre)")
    fig.update_layout(xaxis_title="Trimestre", yaxis_title="Chiffre d'affaires")
    save_html(fig, "p3_02_sales_by_quarter.html")


# ============================================================
# (2) Géographie : clients + ventes par pays
# ============================================================
def customers_by_country_top15():
    sql = """
    SELECT country, COUNT(*) AS nb_customers
    FROM customers
    GROUP BY country
    ORDER BY nb_customers DESC
    LIMIT 15;
    """
    df = fetch_df(sql)

    # Matplotlib PNG
    d = df.sort_values("nb_customers")
    plt.figure(figsize=(10, 6))
    plt.barh(d["country"], d["nb_customers"])
    plt.title("Top 15 pays - Nombre de clients")
    plt.xlabel("Nombre de clients")
    plt.ylabel("Pays")
    plt.grid(axis="x", alpha=0.25)
    save_png("p3_03_customers_by_country_top15.png")

    # Plotly HTML
    fig = px.bar(df, x="nb_customers", y="country", orientation="h",
                 title="Top 15 pays - Nombre de clients")
    fig.update_layout(xaxis_title="Nombre de clients", yaxis_title="Pays")
    save_html(fig, "p3_03_customers_by_country_top15.html")


def sales_by_country_top15():
    sql = """
    SELECT
        c.country,
        SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM customers c
    JOIN orders o ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY c.country
    ORDER BY total_sales DESC
    LIMIT 15;
    """
    df = fetch_df(sql)

    # Matplotlib PNG
    d = df.sort_values("total_sales")
    plt.figure(figsize=(10, 6))
    plt.barh(d["country"], d["total_sales"])
    plt.title("Top 15 pays - Ventes (CA)")
    plt.xlabel("Chiffre d'affaires")
    plt.ylabel("Pays")
    plt.grid(axis="x", alpha=0.25)
    save_png("p3_04_sales_by_country_top15.png")

    # Plotly HTML
    fig = px.bar(df, x="total_sales", y="country", orientation="h",
                 title="Top 15 pays - Ventes (CA)")
    fig.update_layout(xaxis_title="Chiffre d'affaires", yaxis_title="Pays")
    save_html(fig, "p3_04_sales_by_country_top15.html")


# ============================================================
# (3) Ventes par gamme (comparaison)
# ============================================================
def sales_by_productline():
    sql = """
    SELECT
        p.productLine,
        SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM orderdetails od
    JOIN orders o ON od.orderNumber = o.orderNumber
    JOIN products p ON od.productCode = p.productCode
    GROUP BY p.productLine
    ORDER BY total_sales DESC;
    """
    df = fetch_df(sql)

    # Matplotlib PNG
    d = df.sort_values("total_sales")
    plt.figure(figsize=(10, 6))
    plt.barh(d["productLine"], d["total_sales"])
    plt.title("Chiffre d'affaires par gamme de produits")
    plt.xlabel("Chiffre d'affaires")
    plt.ylabel("Gamme")
    plt.grid(axis="x", alpha=0.25)
    save_png("p3_05_sales_by_productline.png")

    # Plotly HTML
    fig = px.bar(df, x="total_sales", y="productLine", orientation="h",
                 title="Chiffre d'affaires par gamme de produits")
    fig.update_layout(xaxis_title="Chiffre d'affaires", yaxis_title="Gamme")
    save_html(fig, "p3_05_sales_by_productline.html")


# ============================================================
# (4) Top 10 produits (requête paramétrée)
# ============================================================
def top_products_qty(top_n: int = 10):
    sql = """
    SELECT
        p.productName,
        SUM(od.quantityOrdered) AS qty_sold
    FROM products p
    JOIN orderdetails od ON p.productCode = od.productCode
    GROUP BY p.productName
    ORDER BY qty_sold DESC
    LIMIT %s;
    """
    df = fetch_df(sql, (top_n,))

    # Matplotlib PNG
    d = df.sort_values("qty_sold")
    plt.figure(figsize=(10, 6))
    plt.barh(d["productName"], d["qty_sold"])
    plt.title(f"Top {top_n} produits - Quantité vendue")
    plt.xlabel("Quantité vendue")
    plt.ylabel("Produit")
    plt.grid(axis="x", alpha=0.25)
    save_png(f"p3_06_top{top_n}_products_qty.png")

    # Plotly HTML
    fig = px.bar(df, x="qty_sold", y="productName", orientation="h",
                 title=f"Top {top_n} produits - Quantité vendue")
    fig.update_layout(xaxis_title="Quantité vendue", yaxis_title="Produit")
    save_html(fig, f"p3_06_top{top_n}_products_qty.html")


# ============================================================
# (5) Stocks : rupture + stock faible (requête paramétrée)
# ============================================================
def stock_low(threshold: int = 1000):
    sql_low = """
    SELECT productName, quantityInStock
    FROM products
    WHERE quantityInStock >= 0 AND quantityInStock <= %s
    ORDER BY quantityInStock ASC
    LIMIT 20;
    """
    df = fetch_df(sql_low, (threshold,))

    # Matplotlib PNG
    d = df.sort_values("quantityInStock", ascending=True)
    plt.figure(figsize=(10, 6))
    plt.barh(d["productName"][::-1], d["quantityInStock"][::-1])
    plt.title(f"Top 20 produits - Stock faible (<= {threshold})")
    plt.xlabel("Quantité en stock")
    plt.ylabel("Produit")
    plt.grid(axis="x", alpha=0.25)
    save_png(f"p3_07_low_stock_le_{threshold}.png")

    # Plotly HTML
    fig = px.bar(df, x="quantityInStock", y="productName", orientation="h",
                 title=f"Top 20 produits - Stock faible (<= {threshold})")
    fig.update_layout(xaxis_title="Quantité en stock", yaxis_title="Produit")
    save_html(fig, f"p3_07_low_stock_le_{threshold}.html")


# ============================================================
# (6) CA clients : top vs autres (requête paramétrée)
# ============================================================
def revenue_top_vs_others(top_n: int = 10):
    sql = """
    SELECT
        c.customerName,
        SUM(od.quantityOrdered * od.priceEach) AS total_revenue
    FROM customers c
    JOIN orders o ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY c.customerName
    ORDER BY total_revenue DESC;
    """
    df = fetch_df(sql)

    df["rank"] = range(1, len(df) + 1)
    df["group"] = df["rank"].apply(lambda r: f"Top {top_n}" if r <= top_n else "Autres")
    agg = df.groupby("group", as_index=False)["total_revenue"].sum()

    # Matplotlib PNG
    plt.figure(figsize=(7, 5))
    plt.bar(agg["group"], agg["total_revenue"])
    plt.title(f"Répartition du CA : Top {top_n} clients vs Autres")
    plt.xlabel("Groupe")
    plt.ylabel("Chiffre d'affaires")
    plt.grid(axis="y", alpha=0.25)
    save_png(f"p3_08_revenue_top{top_n}_vs_others.png")

    # Plotly HTML
    fig = px.bar(agg, x="group", y="total_revenue",
                 title=f"Répartition du CA : Top {top_n} clients vs Autres")
    fig.update_layout(xaxis_title="Groupe", yaxis_title="Chiffre d'affaires")
    save_html(fig, f"p3_08_revenue_top{top_n}_vs_others.html")


def main():
    sales_by_month()
    sales_by_quarter()

    customers_by_country_top15()
    sales_by_country_top15()

    sales_by_productline()

    top_products_qty(top_n=10)

    stock_low(threshold=1000)

    revenue_top_vs_others(top_n=10)



if __name__ == "__main__":
    main()