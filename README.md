# E-commerce
# E-Commerce Data Engineering Project

## Project Overview

This project focuses on building a data engineering pipeline using the Brazilian E-Commerce Public Dataset by Olist.

The first stage covers data ingestion, data exploration, quality validation, standardization, and preparation of raw data for downstream processing.

External economic data is also collected from the World Bank API to enrich the project.

## Data Sources

### Olist Dataset
- Customers
- Orders
- Order Items
- Order Payments
- Order Reviews
- Products
- Sellers
- Geolocation
- Product Category Translation

### World Bank API
Brazilian economic indicators (2016–2018):
- Population
- GDP (current US$)
- Annual Inflation Rate (%)

## Technologies

- Python
- Pandas
- Requests
- REST APIs
- Git & GitHub

## Project Structure

```text
E-commerce/
├── data/
│   ├── raw/
│   │   └── external/
│   ├── staging/
│   └── processed/
├── docs/
├── src/
├── .gitignore
└── README.md
```

## Setup

Clone the repository:

```bash
git clone <repository-url>
cd E-commerce
```

Install the required Python packages:

```bash
pip install pandas requests
```

Place the nine original Olist CSV files inside:

```text
data/raw/
```

The original Olist CSV files are not included in this repository.

## Pipeline Execution

Run the following scripts from the project root directory:

### 1. Extract External Data

```bash
python src/extract_world_bank.py
```

Retrieves Brazil's population, GDP, and inflation indicators from the World Bank API and saves the responses as JSON files.

### 2. Transform External Data

```bash
python src/transform_world_bank.py
```

Transforms the extracted JSON data into a structured CSV file.

### 3. Prepare Olist Data

```bash
python src/prepare_olist_staging.py
```

This step:
- Loads the Olist datasets.
- Standardizes column names and data types.
- Handles whitespace and empty values.
- Preserves identifiers and ZIP code formatting.
- Parses date columns.
- Validates configured keys and duplicate records.
- Translates product category names into English where available.
- Generates staging datasets and a validation report.

## Outputs

- Prepared Olist staging datasets.
- Data validation report.
- World Bank economic data in CSV format.

Generated CSV files and original Olist CSV datasets are excluded from Git.

## Data Quality Notes

- Missing values are retained when they represent legitimate missing information.
- Exact duplicate geolocation records are reported and preserved.
- Review records are validated using the composite key (`review_id`, `order_id`).
- Products without available English category translations are retained.
- No records are arbitrarily deleted during preparation.

For more details, check the documentation in the `docs/` directory.

## Running the Platform with Docker

### Prerequisites
- Docker Desktop (running) and Git

### Quick start
```bash
git clone <repository-url>
cd E-commerce
cp .env.example .env        # Windows: copy .env.example .env
# edit .env and set real passwords
docker compose up -d --build
```
The first build takes a few minutes; later starts take about 30 seconds.

### Services

| Service | Container | URL / Port |
|---|---|---|
| Data Warehouse (PostgreSQL 16) | olist_dwh | localhost:5433 |
| Airflow metadata DB | olist_airflow_db | internal only |
| Airflow web UI | olist_airflow_web | http://localhost:8080 |
| Airflow scheduler | olist_airflow_scheduler | internal only |

Log in to Airflow with `AIRFLOW_ADMIN_USER` / `AIRFLOW_ADMIN_PASSWORD` from `.env`.
`olist_airflow_init` runs once and exits with code 0; this is expected.

### Connecting to the Data Warehouse
- From your machine (Python scripts, Power BI): host `localhost`, port `5433`, with `DWH_USER`, `DWH_PASSWORD`, `DWH_DB` from `.env`.
- From inside Docker (Airflow, dbt): host `dwh-db`, port `5432`.

Schemas created automatically on first start: `raw`, `staging`, `core`, `analytics`.

### dbt
dbt is installed in the Airflow image. The project is in `dbt_project/` and reads credentials from environment variables (`profiles.yml`).
```bash
docker exec -u airflow -w /opt/airflow/dbt_project olist_airflow_scheduler dbt debug
```

### Useful commands
```bash
docker compose ps -a          # status of all services
docker compose logs -f airflow-scheduler
docker compose down           # stop (data is kept)
docker compose down -v        # stop and DELETE all data (full reset)
```
Init SQL scripts only run when the DWH volume is empty, so after changing `docker/postgres/init/` run `docker compose down -v` once.

### CI
GitHub Actions (`.github/workflows/ci.yml`) runs on every pull request and on pushes to `main`: ruff lint, pytest (when `tests/` exists), `dbt parse`, and a Docker image build.