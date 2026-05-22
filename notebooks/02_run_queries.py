"""
02_run_queries.py
Connects to loans.db, executes the three analysis queries,
saves each result as a CSV to /outputs, and prints a preview.
"""

import os
import pandas as pd
from sqlalchemy import create_engine

# ── Paths ────────────────────────────────────────────────────────────────────

BASE_DIR    = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH     = os.path.join(BASE_DIR, 'data',    'loans.db')
QUERIES_DIR = os.path.join(BASE_DIR, 'queries')
OUTPUTS_DIR = os.path.join(BASE_DIR, 'outputs')

os.makedirs(OUTPUTS_DIR, exist_ok=True)

# ── Database connection ───────────────────────────────────────────────────────

engine = create_engine(f'sqlite:///{DB_PATH}')
print(f'Connected to {DB_PATH}\n{"-" * 60}')

# ── Query registry ────────────────────────────────────────────────────────────

QUERIES = [
    {
        'label':   'Query 1 — Default Rate by Grade',
        'sql':     'query1_default_by_grade.sql',
        'output':  'query1_default_by_grade.csv',
    },
    {
        'label':   'Query 2 — Default Trend by Year & Grade',
        'sql':     'query2_default_trend.sql',
        'output':  'query2_default_trend.csv',
    },
    {
        'label':   'Query 3 — Term & Purpose Outcomes',
        'sql':     'query3_term_purpose.sql',
        'output':  'query3_term_purpose.csv',
    },
]

# ── Execute and export ────────────────────────────────────────────────────────

for q in QUERIES:
    sql_path = os.path.join(QUERIES_DIR, q['sql'])
    out_path = os.path.join(OUTPUTS_DIR, q['output'])

    with open(sql_path, 'r') as f:
        sql = f.read()

    df = pd.read_sql(sql, con=engine)

    df.to_csv(out_path, index=False)

    print(f"\n{q['label']}")
    print(f"  Rows returned : {len(df):,}")
    print(f"  Saved to      : {out_path}")
    print(f"\n{df.head(5).to_string(index=False)}")
    print(f'\n{"-" * 60}')

print('\nAll queries complete. CSVs are ready in /outputs.')
