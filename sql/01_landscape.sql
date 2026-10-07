-- 01_landscape.sql
-- Story section 1: What does the clinical trial landscape look like?
-- Before running: SET search_path = ctgov, public;

-- Q1. How many interventional Phase 1-4 trials start each year, by phase?
-- ('NA' = Not Applicable, i.e. device/behavioral studies, is excluded.)
SELECT EXTRACT(YEAR FROM start_date) AS start_year,
       phase,
       COUNT(*) AS trials
FROM studies
WHERE study_type = 'INTERVENTIONAL'
  AND phase <> 'NA'
  AND start_date >= DATE '2010-01-01'
  AND start_date <  DATE '2026-01-01'
GROUP BY 1, 2
ORDER BY 1, 2;

-- Q2. Which conditions (MeSH terms) have the most trials from 2020 to 2025,
--     and how did the count change year by year? (CTE + RANK window function)
-- mesh_type = 'mesh-list' keeps only the directly assigned MeSH terms, so broad
-- parent categories (ancestors) do not overlap with specific conditions.
WITH yearly AS (
  SELECT bc.mesh_term AS condition,
         EXTRACT(YEAR FROM s.start_date) AS start_year,
         COUNT(DISTINCT s.nct_id) AS trials
  FROM studies s
  JOIN browse_conditions bc ON bc.nct_id = s.nct_id
  WHERE s.study_type = 'INTERVENTIONAL'
    AND bc.mesh_type = 'mesh-list'
    AND s.start_date >= DATE '2020-01-01'
    AND s.start_date <  DATE '2026-01-01'
  GROUP BY 1, 2
),
ranked AS (
  SELECT condition,
         SUM(trials) AS total_trials,
         RANK() OVER (ORDER BY SUM(trials) DESC) AS rnk
  FROM yearly
  GROUP BY condition
)
SELECT y.condition, y.start_year, y.trials, r.rnk
FROM yearly y
JOIN ranked r ON r.condition = y.condition
WHERE r.rnk <= 10
ORDER BY r.rnk, y.start_year;