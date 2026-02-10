# src/analysis/db.py
import os
from dotenv import load_dotenv
import mysql.connector

# IMPORTANT : charge le .env au bon endroit
load_dotenv("config/.env")

def get_connection():
    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "localhost"),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD"),          # pas de "" par défaut
        database=os.getenv("MYSQL_DATABASE", "classicmodels"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
    )
