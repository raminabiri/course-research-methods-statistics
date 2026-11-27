* Educational example using the synthetic data file.
* Run from the research-methodology directory or edit the path below.

GET DATA
  /TYPE=TXT
  /FILE='08_data_management_analysis/data/synthetic_followup.csv'
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /VARIABLES=
    participant_id A8
    site_id A3
    group A12
    age_years F3.0
    sex A1
    baseline_sbp_mmhg F8.1
    week12_sbp_mmhg F8.1
    adverse_event F1.0.
EXECUTE.

VARIABLE LABELS
  participant_id "Synthetic participant identifier"
  site_id "Synthetic study site"
  group "Synthetic assigned group"
  age_years "Age in years"
  baseline_sbp_mmhg "Baseline systolic pressure in mmHg"
  week12_sbp_mmhg "Week-12 systolic pressure in mmHg"
  adverse_event "Synthetic adverse event indicator".

VALUE LABELS group
  "control" "Control"
  "intervention" "Intervention".
VALUE LABELS adverse_event
  0 "No"
  1 "Yes".
EXECUTE.

FREQUENCIES VARIABLES=group site_id sex adverse_event.
DESCRIPTIVES VARIABLES=age_years baseline_sbp_mmhg week12_sbp_mmhg
  /STATISTICS=MEAN STDDEV MIN MAX.

COMPUTE week12_missing = MISSING(week12_sbp_mmhg).
COMPUTE group_intervention = (group = "intervention").
EXECUTE.

* Missingness summaries describe the observed file; they do not prove a mechanism.
CROSSTABS
  /TABLES=group BY week12_missing
  /CELLS=COUNT ROW.

T-TEST GROUPS=group("control" "intervention")
  /VARIABLES=week12_sbp_mmhg
  /CRITERIA=CI(.95).

* Complete-case model for teaching only; justify assumptions before real use.
REGRESSION
  /DEPENDENT week12_sbp_mmhg
  /METHOD=ENTER group_intervention baseline_sbp_mmhg age_years.
