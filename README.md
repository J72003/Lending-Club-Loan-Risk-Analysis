# Banking Analytics Dashboard

SQL analysis and product analyst readout on 887K+ LendingClub loans (2015–2018), built to demonstrate financial data analysis and product analyst thinking for banking and fintech roles.

---

## Business question

Which loan attributes are the strongest predictors of default, and where does the pricing model break down?

---

## Key findings

1. **The pricing model breaks at grade D.** Grade D loans average 17.93% interest but default at 19.96% — the interest rate does not cover expected losses before operating costs, meaning every grade D–G origination requires a subsidy from grade A–B profits to stay net positive.

2. **The 2017–2018 apparent improvement in default rates is vintage immaturity bias, not genuine credit quality improvement.** Grade E defaults appear to drop from 34.22% in 2015 to 6.62% in 2018 — but 2018 loans are only 1–2 years old and have not had sufficient time to default.

3. **60-month small business loans are the highest-risk product combination in the portfolio.** This term–purpose combination carries a 22.15% default rate vs. 16.53% on 36-month small business loans — a 34% relative increase in default risk from term extension alone.

---

## Data quality flag

The source file (`accepted_2007_to_2018Q4.xlsx`) loaded exactly 1,048,575 rows — Excel's hard row limit. Pre-2015 origination records were silently truncated during the Excel export. This was identified and flagged in the analyst readout before publication. For a complete vintage analysis covering 2007–2014, the raw CSV from Kaggle is required.

---

## Tech stack

| Tool | Purpose |
|---|---|
| Python | Data pipeline and automation |
| pandas | DataFrame manipulation and cleaning |
| SQLite | Lightweight local analytical database |
| SQL | Aggregation and business logic queries |
| Jupyter Notebook | Exploratory data prep and cleaning |
| Tableau | Interactive dashboard and visualisations |

---

## Project structure

```
banking-analytics/
├── data/                        # Raw and processed data (excluded from git)
├── queries/
│   ├── query1_default_by_grade.sql
│   ├── query2_default_trend.sql
│   └── query3_term_purpose.sql
├── notebooks/
│   ├── 01_clean_load.ipynb      # Ingest, clean, and write to SQLite
│   └── 02_run_queries.py        # Run all queries, export CSVs
├── outputs/
│   ├── query1_default_by_grade.csv
│   ├── query2_default_trend.csv
│   ├── query3_term_purpose.csv
│   ├── readout.md               # Full product analyst readout
│   └── interview_cheatsheet.md
├── .gitignore
├── requirements.txt
└── README.md
```

---

## How to run

**Prerequisites:** Python 3.10+, pip, the raw source file placed at `data/accepted_2007_to_2018Q4.xlsx`.

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Run the data pipeline (reads XLSX, cleans, writes loans.db)
#    Open notebooks/01_clean_load.ipynb in VS Code and run all cells
#    OR run the pipeline inline:
python -c "
import pandas as pd
from sqlalchemy import create_engine
df = pd.read_excel('data/accepted_2007_to_2018Q4.xlsx')
keep = ['loan_amnt','grade','loan_status','int_rate','term',
        'issue_d','annual_inc','purpose']
df = df[keep].dropna(subset=['grade','loan_status','issue_d'])
df['issue_d'] = pd.to_datetime(df['issue_d'], format='%b-%Y', errors='coerce')
df['issue_year'] = df['issue_d'].dt.year.astype(int)
df['issue_month'] = df['issue_d'].dt.month.astype(int)
df['is_default'] = df['loan_status'].isin(
    {'Charged Off','Default',
     'Does not meet the credit policy. Status:Charged Off'}).astype(int)
df['is_paid'] = (df['loan_status'] == 'Fully Paid').astype(int)
engine = create_engine('sqlite:///data/loans.db')
df.to_sql('loans', con=engine, if_exists='replace', index=False, chunksize=10000)
print(f'Written {len(df):,} rows to loans.db')
"

# 3. Run the three SQL queries and export CSVs
cd banking-analytics
python notebooks/02_run_queries.py
```

Output CSVs are written to `outputs/`. The full analyst readout is at `outputs/readout.md`.

---

## Dashboard

Dashboard: [LendingClub Loan Risk Analysis — Tableau Public](https://public.tableau.com/views/Project2_17794091604310/Dashboard1)

---

## Portfolio context

This project was built to demonstrate end-to-end product analytics skills in a financial services context: writing a data pipeline from raw source to structured database, expressing business logic in SQL, identifying a material data quality issue before it distorted published findings, and translating query results into product recommendations a PM or risk team could act on. The target audience for this work is product analyst and data analyst roles at banks, lenders, and fintech companies.
