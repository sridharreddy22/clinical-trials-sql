-- 00_data_quality.sql
-- Run these FIRST and record the results in findings.md.
-- Before running: SET search_path = ctgov, public;
-- Check every column name against the AACT data dictionary:
-- https://aact.ctti-clinicaltrials.org/data_dictionary

-- DQ1. How big is the dataset, and how are study types split?
SELECT study_type, COUNT(*) AS studies
FROM studies
GROUP BY study_type
ORDER BY studies DESC;

-- DQ2. Missing values in the fields the analysis depends on (interventional trials only)
SELECT COUNT(*) AS interventional_trials,
       SUM(CASE WHEN start_date IS NULL THEN 1 ELSE 0 END) AS missing_start_date,
       SUM(CASE WHEN completion_date IS NULL THEN 1 ELSE 0 END) AS missing_completion_date,
       SUM(CASE WHEN enrollment IS NULL THEN 1 ELSE 0 END) AS missing_enrollment,
       SUM(CASE WHEN phase IS NULL THEN 1 ELSE 0 END) AS missing_phase
FROM studies
WHERE study_type = 'INTERVENTIONAL';

-- DQ3. Impossible dates: completion before start
SELECT COUNT(*) AS completion_before_start
FROM studies
WHERE start_date IS NOT NULL
  AND completion_date IS NOT NULL
  AND completion_date < start_date;

-- DQ4. Phase labels: what values exist, and how common are the combined phases?

SELECT phase, COUNT(*) AS studies
FROM studies
WHERE study_type = 'INTERVENTIONAL'
GROUP BY phase
ORDER BY studies DESC;

-- DQ5. Messy free-text conditions: same condition, different spellings
SELECT LOWER(name) AS condition_lower,
       COUNT(DISTINCT name) AS spellings
FROM conditions
GROUP BY LOWER(name)
HAVING COUNT(DISTINCT name) > 1
ORDER BY spellings DESC
LIMIT 20;

-- DQ6. Join duplication demo: the SAME question answered two ways.
-- Row count is inflated because one trial has several conditions and sponsors.
SELECT COUNT(*) AS inflated_row_count
FROM studies s
JOIN conditions c ON c.nct_id = s.nct_id
JOIN sponsors sp ON sp.nct_id = s.nct_id;

SELECT COUNT(DISTINCT s.nct_id) AS correct_trial_count
FROM studies s
JOIN conditions c ON c.nct_id = s.nct_id
JOIN sponsors sp ON sp.nct_id = s.nct_id;
