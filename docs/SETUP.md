# Setup

1. Clone the repo and create your branch:
   git clone <repo-url>
   cd Olist_Data_Engineering
   git checkout develop
2. Download the Olist dataset from Kaggle ("Brazilian E-Commerce Public Dataset by Olist")
   and put the 9 CSV files in `data/raw/` (they are not stored in Git).
3. Create your env file:
   copy .env.example .env      (Windows)
   cp .env.example .env        (Mac/Linux)
   then edit .env and set real passwords.
4. Start everything:
   docker compose up -d
5. Services:
   - Data Warehouse (Postgres): localhost:5433  (schemas: raw, staging, marts)
   - Airflow UI: http://localhost:8080  (user/password from .env)
6. Stop:  docker compose down      Reset DB:  docker compose down -v
