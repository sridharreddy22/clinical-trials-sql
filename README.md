# Why Do Clinical Trials Get Terminated? A SQL Analysis of ClinicalTrials.gov

> Most clinical trials that end early stop for operational reasons, not because the treatment failed: enrollment problems alone account for about 31% of terminations, and about 56% are operational or external.

## Business problem
Clinical trials are expensive, and many end early. This project uses SQL to look at which kinds of trials finish, which are terminated, how long they take, and what reasons are given when they stop, so a clinical research team could see where the risk is.

## Data
- **Source:** AACT, the public PostgreSQL copy of every study registered on ClinicalTrials.gov (https://aact.ctti-clinicaltrials.org)
- **Snapshot date:** October 7, 2026
- **Scope:** interventional Phase 1–4 trials (606,000 studies in the database, 224,037 in the Phase 1–4 set). "Not Applicable" phase trials (devices and behavioral studies) were excluded from phase analyses.

## Tools
PostgreSQL (AACT database), DBeaver, SQL (joins, CTEs, window functions, CASE, percentiles)

## Key findings
- Of 148,833 closed Phase 1–4 trials (completed or terminated), 13.8% were terminated. Rates were highest for Phase 1/2 (20.8%) and Phase 2 (17.6%), and lowest for Phase 1 (10.8%).
- The most common stated reason for termination was enrollment or recruitment (31.2% of 20,525 terminated trials). Enrollment, business decisions and funding together explained about 49%, while safety and efficacy together were about 15%.
- Median trial duration was 35.0 months for Phase 1/2 trials and 11.2 months for Phase 1. The longest phases were also the most often terminated.
- Termination was highest for trials with 6 to 20 sites (17.5%) and lowest for trials with 0 to 1 site (12.1%). The largest trials (21+ sites) were in between at 14.7% (association, not cause).
- About 34-43% of completed trials (2012-2024) posted results, depending on the year.

## Questions answered
| # | Question | File |
|---|---|---|
| Q1-Q2 | Trials per year by phase; top conditions | `sql/01_landscape.sql` |
| Q3, Q8 | Termination rate; trial duration | `sql/02_performance.sql` |
| Q4 | Why trials stop early; effect of site count | `sql/03_termination_risk.sql` |
| Q5-Q7 | Sponsor types, top sponsors, countries | `sql/04_sponsors_geography.sql` |
| Q9-Q10 | Enrollment size; results reporting | `sql/05_enrollment_results.sql` |

Full results and what they mean are in [`findings.md`](findings.md).

## Data quality notes
See `sql/00_data_quality.sql` and `findings.md`.
- Among interventional trials, start date was missing for 2,889, completion date for 11,468, enrollment for 3,845 and phase for 128.
- 73 trials had a completion date before their start date. I excluded them from duration calculations.
- "Not Applicable" phase (238,280 trials) is a valid label for devices and behavioral studies, not missing data, so I kept it out of phase analyses.
- For conditions, I used MeSH direct terms (`mesh-list`) so counts did not include broad parent categories.
- Stop reasons are free text. I first grouped them with keywords, then reviewed word frequencies in the "Other" group and added categories, reducing "Other" from 29.6% to 17.4%.

## Lesson learned: join duplication
A trial can have several conditions and sponsors, so joining those tables multiplies rows. Counting rows gave 1,875,257 while counting distinct trials gave 604,979 (about 3.1 times too many). All trial counts here use `COUNT(DISTINCT nct_id)`.

## Limitations
- The registry is self-reported, so some fields are missing or inconsistent.
- Ongoing trials are excluded from completion and termination rates.
- Stop reasons are free text, so the categories depend on my keyword choices and on the order of the rules.
- Duration uses completed trials only, so long trials still running are missing and durations are probably understated.
- Months-to-report-results only includes trials that have already reported, so recent years look faster than they are.
- The results show association, not cause.

## How to reproduce
1. Create a free AACT account and connect with `psql` or DBeaver.
2. Run `SET search_path = ctgov, public;`
3. Run the files in `sql/` in order.
