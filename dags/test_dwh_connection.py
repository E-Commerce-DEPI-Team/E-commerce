"""Test DAG: checks that Airflow can reach the Data Warehouse.

Trigger it manually from the Airflow UI. It connects to Postgres using the
DWH_* environment variables from docker-compose.yml and verifies that the
raw, staging and marts schemas exist.
"""

import os
from datetime import datetime

import psycopg2
from airflow import DAG
from airflow.operators.python import PythonOperator

EXPECTED_SCHEMAS = {"raw", "staging", "marts"}


def check_dwh_connection():
    conn = psycopg2.connect(
        host=os.environ["DWH_HOST"],
        port=os.environ["DWH_PORT"],
        dbname=os.environ["DWH_DB"],
        user=os.environ["DWH_USER"],
        password=os.environ["DWH_PASSWORD"],
    )
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT version();")
            print("Connected to:", cur.fetchone()[0])

            cur.execute("SELECT schema_name FROM information_schema.schemata;")
            schemas = {row[0] for row in cur.fetchall()}
            print("Schemas found:", sorted(schemas))
    finally:
        conn.close()

    missing = EXPECTED_SCHEMAS - schemas
    if missing:
        raise ValueError(f"Missing schemas: {sorted(missing)}")
    print("OK: raw, staging and marts all exist.")


with DAG(
    dag_id="test_dwh_connection",
    description="Checks the Airflow -> DWH connection and the 3 schemas",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["test", "infrastructure"],
) as dag:
    PythonOperator(
        task_id="check_dwh_connection",
        python_callable=check_dwh_connection,
    )
