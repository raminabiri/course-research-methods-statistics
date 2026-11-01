* =============================================================.
* فصل ۶ — نمونه‌گیری در SPSS.
* فقط مسیر FILE HANDLE را تغییر دهید.
* =============================================================.
FILE HANDLE datadir /NAME='C:/research_methods/data'.
INSERT FILE='datadir/load_survey.sps'.
SET SEED=123.

* ۱) تصادفی ساده: دقیقاً ۸۰ نفر از ۴۰۰ (در یک کپی از داده).
DATASET COPY srs.
DATASET ACTIVATE srs.
SAMPLE 80 FROM 400.
DESCRIPTIVES pre_score.

* ۲) سیستماتیک: k = 5 با شروع تصادفی بین ۱ تا ۵.
DATASET ACTIVATE survey.
* شروع تصادفی فقط یک بار (سطر اول) ساخته و با LEAVE به همه سطرها منتقل می‌شود.
DO IF $CASENUM = 1.
  COMPUTE start = TRUNC(RV.UNIFORM(1, 6)).
END IF.
LEAVE start.
EXECUTE.
DATASET COPY sys.
DATASET ACTIVATE sys.
SELECT IF MOD(id - start, 5) = 0.
DESCRIPTIVES pre_score.

* ۳) طبقه‌ای متناسب: ۲۰٪ از هر منطقه.
* (عدد تصادفی + رتبه درون طبقه؛ نتیجه دقیقاً ۱۶ نفر از هر منطقه ۸۰ نفری).
DATASET ACTIVATE survey.
COMPUTE u = RV.UNIFORM(0, 1).
RANK VARIABLES=u BY region /RANK INTO r_in_stratum.
DATASET COPY strat.
DATASET ACTIVATE strat.
SELECT IF r_in_stratum <= 16.
FREQUENCIES region.
DESCRIPTIVES pre_score.

* ۴) خوشه‌ای یک‌مرحله‌ای: ۸ مدرسه از ۴۰.
DATASET ACTIVATE survey.
AGGREGATE /OUTFILE=* MODE=ADDVARIABLES /BREAK=school /u_school = FIRST(u).
DATASET COPY clus.
DATASET ACTIVATE clus.
RANK VARIABLES=u_school /RANK INTO r_school /TIES=CONDENSE.
SELECT IF r_school <= 8.
FREQUENCIES school.
DESCRIPTIVES pre_score.

* ۵) طرح‌های پیچیده و برآورد با وزن: ماژول Complex Samples.
* Analyze > Complex Samples > Prepare for Analysis (CSPLAN) سپس CSDESCRIPTIVES.
* مثال (نیازمند ماژول Complex Samples):
* CSPLAN ANALYSIS /PLAN FILE='datadir/cluster.csaplan'
*   /PLANVARS ANALYSISWEIGHT=wt /DESIGN CLUSTER=school /ESTIMATOR TYPE=WR.
* CSDESCRIPTIVES /PLAN FILE='datadir/cluster.csaplan' /SUMMARY VARIABLES=pre_score /MEAN /STATISTICS SE DEFF.
