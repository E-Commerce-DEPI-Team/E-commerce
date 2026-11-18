# Setup

## Requirements
- Git
- Docker Desktop (running)
- The Olist dataset from Kaggle

## Steps

1. Clone the repo:
   ```
   git clone https://github.com/johnnaoum-creator/E-commerce.git
   cd E-commerce
   ```
2. Create your own branch from main:
   ```
   git checkout -b feature/your-task-name
   ```
3. Download the Olist dataset from Kaggle ("Brazilian E-Commerce Public Dataset by Olist")
   and put the 9 CSV files in `data/raw/` (they are not stored in Git).
4. Create your env file:
   ```
   copy .env.example .env      (Windows)
   cp .env.example .env        (Mac/Linux)
   ```
   Then edit `.env` and replace every `change_me` with a real password.
   Use letters and numbers only (no `$`, `#`, `@`, `/`), because special characters can break the database connection.
   Never commit `.env`.
5. Start everything:
   ```
   docker compose up -d
   docker compose ps
   ```
   The first run downloads the images and takes a few minutes.

## Services

- Data Warehouse (Postgres): `localhost:5433`
  - Database: `olist_dwh`
  - User: `olist_user`
  - Password: `DWH_PASSWORD` from your `.env`
  - Schemas: `raw`, `staging`, `marts`
- Airflow UI: http://localhost:8080 (user and password from `.env`)

## Stop and reset

- Stop (keeps your data): `docker compose stop`
- Start again: `docker compose up -d`
- Full reset (DELETES all database data): `docker compose down -v`

## Troubleshooting

- Port 5433 or 8080 already in use: stop the other service or change the port in `.env` / `docker-compose.yml`.
- Changed a password in `.env` after the first run: it will not take effect until you reset with `docker compose down -v`.
