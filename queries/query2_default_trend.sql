-- ============================================================
-- query2_default_trend.sql
-- Business question: How have default rates evolved year-over-
-- year across credit grade tiers from 2012 to 2018?
--
-- Analyst use: This query exposes whether credit quality
-- improved or deteriorated across origination vintages.
-- Rising default rates in lower grades (D/E) during a period
-- of loose underwriting standards is a leading indicator of
-- portfolio stress. Product and risk teams use vintage
-- analysis like this to decide whether to tighten grade
-- cutoffs or adjust pricing for future originations.
-- Plot issue_year on the X-axis, default_rate_pct on the
-- Y-axis, with one line per grade in Tableau.
-- ============================================================

SELECT
    issue_year,
    grade,
    COUNT(*)                                AS total_loans,
    ROUND(
        100.0 * SUM(is_default) / COUNT(*),
        2
    )                                       AS default_rate_pct

FROM loans

WHERE
    issue_year BETWEEN 2012 AND 2018
    AND grade IN ('A', 'B', 'C', 'D', 'E')

GROUP BY
    issue_year,
    grade

ORDER BY
    issue_year ASC,
    grade ASC;
