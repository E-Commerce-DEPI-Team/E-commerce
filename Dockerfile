FROM apache/airflow:2.10.4
USER airflow
RUN pip install --no-cache-dir pandas sqlalchemy psycopg2-binary \
    dbt-core==1.12.6 dbt-postgres==1.11.0
