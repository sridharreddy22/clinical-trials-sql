-- 02_performance.sql
-- Story section 2: How do trials perform? Do they finish, and how long do they take?
-- Before running: SET search_path = ctgov, public;
-- Scope: interventional Phase 1-4 trials ('NA' = Not Applicable is excluded).

-- Q3. What share of closed trials (completed or terminated) were terminated, by phase?
SELECT phase,
       COUNT(*) AS closed_trials,
       ROUND(100.0 * SUM(CASE WHEN overall_status = 'TERMINATED' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_terminated
FROM studies
WHERE study_type = 'INTERVENTIONAL'
  AND phase <> 'NA'
  AND overall_status IN ('COMPLETED', 'TERMINATED')
GROUP BY phase
HAVING COUNT(*) > 500
ORDER BY pct_terminated DESC;

-- Q8. How long do completed trials take, by phase? Show median AND average.
-- Trials with missing dates or a completion date before the start date are excluded.
-- Only completed trials are used, so long trials still running are not counted.
SELECT phase,
       COUNT(*) AS completed_trials,
       ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (completion_date - start_date) / 30.4375))::numeric, 1) AS median_months,
       ROUND(AVG((completion_date - start_date) / 30.4375)::numeric, 1) AS avg_months
FROM studies
WHERE study_type = 'INTERVENTIONAL'
  AND phase <> 'NA'
  AND overall_status = 'COMPLETED'
  AND start_date IS NOT NULL
  AND completion_date IS NOT NULL
  AND completion_date >= start_date
GROUP BY phase
HAVING COUNT(*) > 200
ORDER BY median_months DESC;