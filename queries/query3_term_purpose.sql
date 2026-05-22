-- ============================================================
-- query3_term_purpose.sql
-- Business question: Which loan purpose categories carry the
-- highest default risk within each term length, and which
-- purposes have the strongest payoff performance?
--
-- Analyst use: This reveals where the bank's risk is
-- concentrated by product type. A high default_rate_pct on
-- 60-month small_business loans vs. low default on 36-month
-- debt_consolidation loans, for example, directly informs
-- product eligibility rules and term-length restrictions by
-- purpose. Use payoff_rate_pct alongside default_rate_pct —
-- a low payoff rate that doesn't match a high default rate
-- indicates a large "current / in-progress" loan population
-- that has not yet resolved, not necessarily better outcomes.
-- ============================================================

SELECT
    term,
    purpose,
    COUNT(*)                                AS total_loans,
    ROUND(
        100.0 * SUM(is_paid) / COUNT(*),
        2
    )                                       AS payoff_rate_pct,
    ROUND(
        100.0 * SUM(is_default) / COUNT(*),
        2
    )                                       AS default_rate_pct,
    ROUND(AVG(loan_amnt), 0)                AS avg_loan_amount

FROM loans

WHERE
    term    IS NOT NULL
    AND purpose IS NOT NULL

GROUP BY
    term,
    purpose

HAVING COUNT(*) > 500

ORDER BY
    term ASC,
    default_rate_pct DESC;
