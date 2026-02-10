import os
from pathlib import Path
from dotenv import load_dotenv
import mysql.connector

load_dotenv(Path(__file__).resolve().parents[2] / "config" / ".env")

def get_connection():
    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "localhost"),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        database=os.getenv("MYSQL_DATABASE", "classicmodels"),
    )