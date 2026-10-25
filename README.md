# E-commerce Sales and Delivery Analysis

End-to-end analysis of the Olist Brazilian E-Commerce dataset using PostgreSQL, SQL,
Python, statistics and an interactive dashboard.

**Main finding:** late deliveries (8.1% of orders) lower the average review score
from 4.29 to 2.57. Delays longer than 3 days hurt the most.

See `reports/final_report.md` for the full report and `reports/dashboard.html` for the dashboard.

## Folders
- `sql/` schema, load script, queries
- `notebooks/` EDA and statistics
- `src/` database connection, cleaning, plots, dashboard
- `tests/` Pytest tests
- `reports/` charts, report, dashboard

## How to run
1. Download the dataset from Kaggle into `data/raw/`.
2. Create a `.env` file with DB_USER, DB_PASSWORD, DB_HOST, DB_PORT and DB_NAME.
3. Run `sql/schema.sql`, then load the CSVs (see `sql/load.sql`).
4. `pip install -r requirements.txt`
5. Run the notebook, then `python src/dashboard.py`.
6. Run the tests with `python -m pytest`.