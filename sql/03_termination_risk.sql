-- 03_termination_risk.sql
-- Story section 3: Why do trials stop early, and what differs between finished and terminated trials?
-- Before running: SET search_path = ctgov, public;
-- Scope: interventional Phase 1-4 trials ('NA' = Not Applicable is excluded).

-- Q4. Group the free-text "why_stopped" field into categories.
-- Refined after reviewing word frequencies in the 'Other' group (it shrank from 29.6% to 17.4%).
-- A trial is placed in the FIRST category it matches, so the order of WHEN lines matters.
-- Stop reasons are free text, so the categories depend on these keyword choices.
SELECT reason_group,
       COUNT(*) AS trials,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM (
    SELECT nct_id,
           CASE
             WHEN why_stopped IS NULL OR TRIM(why_stopped) = '' THEN 'No reason given'
             WHEN why_stopped ILIKE '%covid%' OR why_stopped ILIKE '%pandemic%' THEN 'COVID-19'
             WHEN why_stopped ILIKE '%enroll%' OR why_stopped ILIKE '%recruit%' OR why_stopped ILIKE '%accrual%'
               OR why_stopped ILIKE '%too few%' OR why_stopped ILIKE '%low patient%'
               OR why_stopped ILIKE '%lack of patients%' OR why_stopped ILIKE '%few patients%'
               OR why_stopped ILIKE '%lack of participants%' THEN 'Enrollment / recruitment'
             WHEN why_stopped ILIKE '%safety%' OR why_stopped ILIKE '%adverse%' OR why_stopped ILIKE '%toxic%' THEN 'Safety'
             WHEN why_stopped ILIKE '%efficacy%' OR why_stopped ILIKE '%futility%' OR why_stopped ILIKE '%benefit%'
               OR why_stopped ILIKE '%interim%' OR why_stopped ILIKE '%endpoint%' THEN 'Efficacy / futility / interim analysis'
             WHEN why_stopped ILIKE '%fund%' OR why_stopped ILIKE '%financ%' THEN 'Funding'
             WHEN why_stopped ILIKE '%supply%' OR why_stopped ILIKE '%availab%' OR why_stopped ILIKE '%manufactur%' THEN 'Drug supply / availability'
             WHEN why_stopped ILIKE '%investigator%' OR why_stopped ILIKE '%institution%' OR why_stopped ILIKE '% left%' THEN 'Investigator / site left'
             WHEN why_stopped ILIKE '%sponsor%' OR why_stopped ILIKE '%business%' OR why_stopped ILIKE '%strateg%'
               OR why_stopped ILIKE '%company%' OR why_stopped ILIKE '%decision%' OR why_stopped ILIKE '%development%'
               OR why_stopped ILIKE '%program%' OR why_stopped ILIKE '%priorit%' THEN 'Sponsor / business decision'
             ELSE 'Other'
           END AS reason_group
    FROM studies
    WHERE overall_status = 'TERMINATED'
      AND study_type = 'INTERVENTIONAL'
      AND phase <> 'NA'
) t
GROUP BY reason_group
ORDER BY trials DESC;

-- Q-extra. How does the termination rate change with the number of sites?
-- Fixed buckets are used instead of NTILE quartiles, because many trials have the same
-- number of sites (for example exactly 1) and quartile edges overlapped.
SELECT CASE WHEN cv.number_of_facilities <= 1 THEN '1. 0-1 sites'
            WHEN cv.number_of_facilities <= 5 THEN '2. 2-5 sites'
            WHEN cv.number_of_facilities <= 20 THEN '3. 6-20 sites'
            ELSE '4. 21+ sites' END AS site_group,
       COUNT(*) AS closed_trials,
       ROUND(100.0 * SUM(CASE WHEN s.overall_status = 'TERMINATED' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_terminated
FROM studies s
JOIN calculated_values cv ON cv.nct_id = s.nct_id
WHERE s.study_type = 'INTERVENTIONAL'
  AND s.phase <> 'NA'
  AND s.overall_status IN ('COMPLETED', 'TERMINATED')
  AND cv.number_of_facilities IS NOT NULL
GROUP BY 1
ORDER BY 1;