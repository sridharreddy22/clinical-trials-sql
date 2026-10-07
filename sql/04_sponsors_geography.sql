-- 04_sponsors_geography.sql
-- Story section 3: who runs the trials and where?
-- Before running: SET search_path = ctgov, public;
-- Scope: interventional Phase 1-4 trials that are closed (COMPLETED or TERMINATED).
-- 'NA' (Not Applicable) phase is excluded. Each trial has one lead sponsor, so
-- filtering on 'lead' avoids double counting collaborators.

-- Q5. Termination rate by sponsor type (industry, academic/other, NIH, etc.)
SELECT sp.agency_class AS sponsor_type,
       COUNT(DISTINCT s.nct_id) AS closed_trials,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN s.overall_status = 'TERMINATED' THEN s.nct_id END)
             / COUNT(DISTINCT s.nct_id), 1) AS pct_terminated
FROM studies s
JOIN sponsors sp ON sp.nct_id = s.nct_id AND sp.lead_or_collaborator = 'lead'
WHERE s.study_type = 'INTERVENTIONAL'
  AND s.phase <> 'NA'
  AND s.overall_status IN ('COMPLETED', 'TERMINATED')
GROUP BY sp.agency_class
ORDER BY closed_trials DESC;

-- Q6. Which sponsors with at least 300 closed trials have the highest termination rate?
-- The 300-trial minimum keeps tiny sponsors from dominating the ranking.
SELECT sp.name AS sponsor,
       sp.agency_class AS sponsor_type,
       COUNT(DISTINCT s.nct_id) AS closed_trials,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN s.overall_status = 'TERMINATED' THEN s.nct_id END)
             / COUNT(DISTINCT s.nct_id), 1) AS pct_terminated
FROM studies s
JOIN sponsors sp ON sp.nct_id = s.nct_id AND sp.lead_or_collaborator = 'lead'
WHERE s.study_type = 'INTERVENTIONAL'
  AND s.phase <> 'NA'
  AND s.overall_status IN ('COMPLETED', 'TERMINATED')
GROUP BY sp.name, sp.agency_class
HAVING COUNT(DISTINCT s.nct_id) >= 300
ORDER BY pct_terminated DESC
LIMIT 15;

-- Q7. Termination rate by country (countries with at least 1,000 closed trials).
-- A trial with sites in several countries is counted once in each country.
SELECT c.name AS country,
       COUNT(DISTINCT s.nct_id) AS closed_trials,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN s.overall_status = 'TERMINATED' THEN s.nct_id END)
             / COUNT(DISTINCT s.nct_id), 1) AS pct_terminated
FROM studies s
JOIN countries c ON c.nct_id = s.nct_id AND c.removed IS NOT TRUE
WHERE s.study_type = 'INTERVENTIONAL'
  AND s.phase <> 'NA'
  AND s.overall_status IN ('COMPLETED', 'TERMINATED')
GROUP BY c.name
HAVING COUNT(DISTINCT s.nct_id) >= 1000
ORDER BY closed_trials DESC;