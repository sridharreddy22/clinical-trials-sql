-- 05_enrollment_results.sql
-- Story section 4: trial size and transparency
-- Before running: SET search_path = ctgov, public;
-- Scope: interventional Phase 1-4 trials ('NA' = Not Applicable is excluded).

-- Q9. Typical (median) enrollment by phase, next to the average and the maximum.
-- A few very large trials pull the average far above the median, so the median is the better
-- measure of a typical trial. The maximum is shown to expose outliers.
SELECT phase,
       COUNT(*) AS trials,
       ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY enrollment))::numeric, 0) AS median_enrollment,
       ROUND(AVG(enrollment), 0) AS avg_enrollment,
       MAX(enrollment) AS max_enrollment
FROM studies
WHERE study_type = 'INTERVENTIONAL'
  AND phase <> 'NA'
  AND enrollment IS NOT NULL
  AND enrollment > 0
GROUP BY phase
HAVING COUNT(*) > 200
ORDER BY median_enrollment DESC;

-- Q10. What share of completed trials posted results, by completion year?
-- Note: not every trial is legally required to post results, so this is not a compliance rate.
-- avg_months_to_report only includes trials that have already reported, so recent years
-- look faster than they really are (late reporters are missing).
SELECT EXTRACT(YEAR FROM s.completion_date) AS completion_year,
       COUNT(*) AS completed_trials,
       ROUND(100.0 * SUM(CASE WHEN cv.were_results_reported THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_with_results,
       ROUND(AVG(cv.months_to_report_results), 1) AS avg_months_to_report
FROM studies s
LEFT JOIN calculated_values cv ON cv.nct_id = s.nct_id
WHERE s.overall_status = 'COMPLETED'
  AND s.study_type = 'INTERVENTIONAL'
  AND s.phase <> 'NA'
  AND s.completion_date >= DATE '2012-01-01'
  AND s.completion_date <  DATE '2025-01-01'
GROUP BY 1
ORDER BY 1;