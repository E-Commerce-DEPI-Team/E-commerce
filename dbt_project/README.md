# Olist Data Warehouse – Data Modeling & Transformation

A SQL Server data warehouse project built with **dbt** to transform the Brazilian E-Commerce Public Dataset (Olist) into an analytics-ready dimensional model.

The project separates the source database from the analytical warehouse:

- **Source database:** `OlistDB`
- **Data warehouse database:** `DataWareHouse`
- **Source schema:** `dbo`
- **Staging schema:** `staging`
- **Analytics schema:** `analytics`

## 1. Project Overview

This project implements the data modeling and transformation layer of an Olist analytics solution.

It uses dbt and SQL Server to:

- Read prepared source tables from SQL Server.
- Build staging views to standardize and prepare source data.
- Create reusable dimension tables.
- Build fact tables at clearly defined business grains.
- Apply data quality tests to validate the resulting models.
- Support incremental processing for fact tables.

The final warehouse follows a dimensional modeling approach with shared dimensions and multiple fact tables.

## 2. Architecture

The data flow is:

```text
                  Olist Source Data
                         |
                         v
               SQL Server: OlistDB
                        dbo
                         |
                         v
                  dbt Source Models
                         |
                         v
                  Staging Views (9)
               DataWareHouse.staging
                         |
                         v
              Dimension Tables (6)
                         |
                         v
                  Fact Tables (4)
                         |
                         v
                Analytics-ready DWH
              DataWareHouse.analytics
```

**Database responsibilities**

| Database | Schema | Responsibility |
|---|---|---|
| OlistDB | dbo | Prepared source and staging tables |
| DataWareHouse | staging | dbt staging views |
| DataWareHouse | analytics | Dimension and fact tables |

The dbt source definitions reference `OlistDB.dbo`, while dbt materializes its staging models in `DataWareHouse.staging` and its dimensional models in `DataWareHouse.analytics`.

## 3. Technology Stack

- **Database:** Microsoft SQL Server
- **Transformation:** dbt Core
- **Adapter:** dbt-sqlserver
- **Package management:** uv
- **Python:** Python 3.14
- **SQL connectivity:** ODBC Driver for SQL Server
- **Additional dbt package:** dbt_utils

## 4. Repository Structure

```text
DBT/
├── analyses/
│   └── .gitkeep
├── database/
│   ├── 01_create_staging_schema_and_tables.sql
│   ├── 02_check_staging_row_counts.sql
│   └── 03_analytics_examples.sql
├── data_reference/
│   └── source_data_validation_report.csv
├── macros/
│   ├── clean_text.sql
│   └── generate_schema_name.sql
├── models/
│   ├── staging/
│   │   ├── stg_category_translation.sql
│   │   ├── stg_customers.sql
│   │   ├── stg_geolocation.sql
│   │   ├── stg_order_items.sql
│   │   ├── stg_order_payments.sql
│   │   ├── stg_order_reviews.sql
│   │   ├── stg_orders.sql
│   │   ├── stg_products.sql
│   │   ├── stg_sellers.sql
│   │   └── schema.yml
│   ├── DWH/
│   │   ├── dim_customer.sql
│   │   ├── dim_date.sql
│   │   ├── dim_order_status.sql
│   │   ├── dim_payment_type.sql
│   │   ├── dim_product.sql
│   │   ├── dim_seller.sql
│   │   ├── fact_orders.sql
│   │   ├── fact_payments.sql
│   │   ├── fact_reviews.sql
│   │   ├── fact_sales.sql
│   │   └── schema.yml
│   └── sources.yml
├── seeds/
│   └── .gitkeep
├── snapshots/
│   └── .gitkeep
├── tests/
│   ├── fact_orders_unique_grain.sql
│   ├── fact_payments_unique_grain.sql
│   ├── fact_reviews_unique_grain.sql
│   ├── fact_sales_non_negative_amounts.sql
│   ├── fact_sales_unique_grain.sql
│   ├── order_items_have_parent_order.sql
│   ├── payments_have_parent_order.sql
│   └── reviews_have_parent_order.sql
├── .vscode/
│   └── settings.json
├── .gitignore
├── dbt_project.yml
├── package-lock.yml
├── packages.yml
├── profiles.yml.example
├── pyproject.toml
├── README.md
├── RUN_ON_WINDOWS.bat
└── uv.lock
```

## 5. Source Data

The project uses nine prepared Olist source tables in `OlistDB.dbo`.

| Source table | Description |
|---|---|
| olist_customers_staging | Customer information |
| olist_orders_staging | Order details and statuses |
| olist_order_items_staging | Items belonging to each order |
| olist_order_payments_staging | Payment records |
| olist_order_reviews_staging | Customer reviews |
| olist_products_staging | Product information |
| olist_sellers_staging | Seller information |
| olist_geolocation_staging | Brazilian geolocation data |
| olist_category_translation_staging | Product category translations |

The source tables must be populated in SQL Server before running dbt.

## 6. Dimensional Data Model

The warehouse contains **six dimensions** and **four fact tables**.

### 6.1 Dimension Tables

| Dimension | Description |
|---|---|
| dim_customer | Customer attributes and identifiers |
| dim_product | Product attributes and English category names |
| dim_seller | Seller identifiers and attributes |
| dim_order_status | Order status reference values |
| dim_payment_type | Payment type reference values |
| dim_date | Calendar attributes and date keys |

### 6.2 Fact Tables

| Fact table | Grain | Description |
|---|---|---|
| fact_sales | One row per order item (`order_id`, `order_item_id`) | Order-item sales and related attributes |
| fact_orders | One row per order (`order_id`) | Order-level metrics and delivery information |
| fact_payments | One row per payment (`order_id`, `payment_sequential`) | Payment-level information |
| fact_reviews | One row per review (`review_id`, `order_id`) | Customer review information |

### 6.3 Dimension Relationships

The fact tables share dimensions where the business context requires them.

| Dimension | fact_sales | fact_orders | fact_payments | fact_reviews |
|---|---|---|---|---|
| dim_customer | Yes | Yes | Yes | Yes |
| dim_product | Yes | No | No | No |
| dim_seller | Yes | No | No | No |
| dim_order_status | Yes | Yes | Yes | Yes |
| dim_payment_type | No | No | Yes | No |
| dim_date | Yes | Yes | Yes | Yes |

The `dim_date` dimension supports multiple date roles, such as purchase, approval, carrier handoff, delivery, and estimated delivery dates where applicable.

## 7. Modeling and Transformation Decisions

### Separate Fact Tables

Sales, orders, payments, and reviews represent different business processes and have different grains.

They are modeled separately to avoid row multiplication when joining one-to-many business events.

### Fact Table Grain

Each fact table has a defined unique grain:

- `fact_sales`: `order_id` + `order_item_id`
- `fact_orders`: `order_id`
- `fact_payments`: `order_id` + `payment_sequential`
- `fact_reviews`: `review_id` + `order_id`

### Date Dimension

The shared `dim_date` table provides reusable calendar attributes and supports multiple date relationships.

### Incremental Models

The four fact tables use incremental materialization with configured unique keys and a 30-day lookback window.

The incremental strategy is designed to process recent data changes without rebuilding the entire fact table on every run.

**Incremental limitation:** Changes to records older than the configured lookback window, as well as source deletions, are not automatically guaranteed to be captured by a normal incremental run. A full refresh or a dedicated correction process may be required when historical corrections are needed.

## 8. Data Quality and Testing

The project includes dbt tests for:

- Not-null constraints.
- Unique keys.
- Accepted values.
- Relationships between fact and dimension tables.
- Referential integrity.
- Composite unique grains.
- Business-specific validation rules.

Custom tests are also used to validate fact table grain and business conditions.

### Latest Build Validation

The final build was executed successfully against the separated warehouse schemas.

| Validation | Result |
|---|---:|
| Models discovered | 19 |
| Staging views | 9 |
| Dimension tables | 6 |
| Fact tables | 4 |
| Data tests | 105 |
| Total build operations | 124 |
| Passed | 124 |
| Warnings | 0 |
| Errors | 0 |

**Build status:** Completed successfully.

### Fact Grain Validation

Duplicate checks were executed against the four fact tables in `DataWareHouse.analytics`.

| Fact table | Duplicate groups |
|---|---:|
| fact_sales | 0 |
| fact_orders | 0 |
| fact_payments | 0 |
| fact_reviews | 0 |

All four fact tables passed the duplicate-grain validation.

## 9. Warehouse Row Counts

The following row counts were verified in `DataWareHouse.analytics`.

| Model | Rows |
|---|---:|
| dim_customer | 99,441 |
| dim_product | 32,951 |
| dim_seller | 3,095 |
| dim_order_status | 8 |
| dim_payment_type | 5 |
| dim_date | 1,314 |
| fact_sales | 112,650 |
| fact_orders | 99,441 |
| fact_payments | 103,886 |
| fact_reviews | 99,224 |

The warehouse contains 19 dbt models in total:

- 9 staging views in `DataWareHouse.staging`.
- 10 dimension and fact tables in `DataWareHouse.analytics`.

## 10. How to Run the Project

### Prerequisites

- Windows
- Python 3.14
- uv
- Microsoft SQL Server
- SQL Server ODBC Driver
- The nine prepared Olist source tables loaded into `OlistDB.dbo`

### Step 1: Configure the dbt Profile

Copy `profiles.yml.example` to:

```text
%USERPROFILE%\.dbt\profiles.yml
```

Configure the SQL Server connection using your local environment details.

The profile must target the warehouse database:

```yaml
olist_dbt:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 18 for SQL Server'
      server: YOUR_SQL_SERVER_HOST_OR_INSTANCE
      port: 1433
      database: DataWareHouse
      schema: analytics
      user: YOUR_SQL_USERNAME
      password: YOUR_SQL_PASSWORD
      encrypt: true
      trust_cert: false
      threads: 4
```

Use the appropriate installed ODBC driver and SQL Server authentication settings for your environment.

**Important:** Keep actual credentials in the local profile. Never commit real passwords or credentials to the repository.

### Step 2: Install Project Dependencies

From the project directory:

```powershell
uv sync
```

Install dbt packages:

```powershell
uv run dbt deps
```

### Step 3: Verify the Connection

```powershell
uv run dbt debug
```

Confirm that the target database is `DataWareHouse` and that the connection test succeeds.

### Step 4: Build Models and Run Tests

```powershell
uv run dbt build
```

This command builds the staging views in `staging`, the dimensions and facts in `analytics`, and runs the configured data tests.

### Alternative: Run the Windows Batch File

After configuring the profile and loading the source tables, run:

```powershell
.\RUN_ON_WINDOWS.bat
```

The batch file executes the connection check, dependency installation, project parsing, and dbt build.

## 11. Useful dbt Commands

| Command | Purpose |
|---|---|
| `uv run dbt debug` | Verify project and database connection |
| `uv run dbt deps` | Install dbt packages |
| `uv run dbt parse` | Validate project parsing |
| `uv run dbt run` | Build models without running tests |
| `uv run dbt test` | Run data tests |
| `uv run dbt build` | Build models and run tests |
| `uv run dbt compile` | Compile SQL models |

To run only the fact models:

```powershell
uv run dbt run --select fact_sales fact_orders fact_payments fact_reviews
```

## 12. Example Warehouse Queries

Run the following queries in SQL Server against `DataWareHouse`.

### Sales Summary

```sql
USE DataWareHouse;
GO

SELECT
    COUNT(*) AS order_item_count,
    SUM(item_total_amount) AS total_sales_amount
FROM analytics.fact_sales;
```

### Orders by Status

```sql
USE DataWareHouse;
GO

SELECT
    order_status,
    COUNT(*) AS order_count
FROM analytics.fact_orders
GROUP BY order_status
ORDER BY order_count DESC;
```

### Payments by Type

```sql
USE DataWareHouse;
GO

SELECT
    payment_type,
    COUNT(*) AS payment_count,
    SUM(payment_value) AS total_payment_value
FROM analytics.fact_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;
```

## 13. Security and Repository Notes

- Actual database credentials must remain outside the repository.
- `profiles.yml.example` contains placeholder values only.
- The local `profiles.yml` should not be committed.
- Generated dbt artifacts, logs, installed packages, and virtual environments are excluded through `.gitignore`.
- Source data and warehouse database contents are managed in SQL Server, not stored as generated database files in this repository.

## 14. Known Limitations

- Incremental fact models use a configured 30-day lookback window.
- Historical changes outside the lookback window may require a full refresh or a dedicated correction process.
- Source deletions are not automatically propagated by the configured incremental strategy.
- The project expects the prepared source tables to exist before dbt execution.

## 15. Final Project Status

The dbt transformation layer has been successfully built and validated in the dedicated `DataWareHouse` database.

Final verified results:

- 19 dbt models created.
- 9 staging views in `DataWareHouse.staging`.
- 6 dimension tables in `DataWareHouse.analytics`.
- 4 fact tables in `DataWareHouse.analytics`.
- 105 data tests passed.
- 0 build errors.
- 0 duplicate fact-grain groups.
- All 10 warehouse table row counts verified.
- Old duplicate staging views removed from `DataWareHouse.analytics`.

**Source database:** `OlistDB.dbo`

**Staging schema:** `DataWareHouse.staging`

**Analytics schema:** `DataWareHouse.analytics`
