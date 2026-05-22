-- ============================================================
-- query1_default_by_grade.sql
-- Business question: Which credit grades carry the highest
-- default risk, and how does interest rate pricing reflect
-- that risk across the portfolio?
--
-- Analyst use: Use this output to validate whether the bank's
-- interest rate model correctly compensates for default risk
-- at each grade tier. A grade with a high default_rate_pct
-- but low avg_interest_rate signals under-pricing. Pipe the
-- result into Tableau to build the risk-vs-return bar chart
-- for the executive dashboard.
-- ============================================================

SELECT
    grade,
    COUNT(*)                                AS total_loans,
    SUM(is_default)                         AS total_defaults,
    ROUND(
        100.0 * SUM(is_default) / COUNT(*),
        2
    )                                       AS default_rate_pct,
    ROUND(AVG(loan_amnt), 0)                AS avg_loan_amount,
    ROUND(AVG(int_rate), 2)                 AS avg_interest_rate

FROM loans

WHERE grade IS NOT NULL

GROUP BY grade

ORDER BY grade ASC;
