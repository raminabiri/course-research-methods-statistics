* =============================================================.
* فصل ۸ — پاک‌سازی، توصیف و تحلیل در SPSS (معادل analysis.R).
* فقط مسیر FILE HANDLE را تغییر دهید.
* =============================================================.
FILE HANDLE datadir /NAME='C:/research_methods/data'.
INSERT FILE='datadir/load_survey.sps'.

* ۱) کیفیت داده: گمشده‌ها، دامنه، تکراری‌ها.
FREQUENCIES VARIABLES=q1 TO q10 /FORMAT=NOTABLE /STATISTICS=MINIMUM MAXIMUM.
DESCRIPTIVES VARIABLES=age pre_score post_score /STATISTICS=MEAN STDDEV MIN MAX.
COMPUTE miss_post = MISSING(post_score).
CROSSTABS /TABLES=group BY miss_post.
SORT CASES BY id.
MATCH FILES /FILE=* /BY id /FIRST=first_id.
FREQUENCIES first_id.
EXAMINE VARIABLES=pre_score post_score BY group
  /PLOT BOXPLOT HISTOGRAM NPPLOT /STATISTICS DESCRIPTIVES.

* ۲) نمره مقیاس (بدون q10).
COMPUTE scale = SUM(q1 TO q9).
EXECUTE.

* ۳) جدول ۱ به تفکیک گروه.
MEANS TABLES=age pre_score BY group /CELLS=MEAN STDDEV COUNT.
CROSSTABS /TABLES=sex BY group /CELLS=COUNT COLUMN.

* ۴) t مستقل (خروجی Levene و Welch هر دو را می‌دهد) و من-ویتنی.
T-TEST GROUPS=group('control' 'intervention') /VARIABLES=post_score /CRITERIA=CI(.95).
NPAR TESTS /M-W=post_score BY group('control' 'intervention').

* ۵) ANCOVA: پس‌آزمون ~ گروه + پیش‌آزمون.
UNIANOVA post_score BY group WITH pre_score
  /METHOD=SSTYPE(3)
  /EMMEANS=TABLES(group) WITH(pre_score=MEAN) COMPARE ADJ(SIDAK)
  /PRINT=ETASQ PARAMETER
  /DESIGN=pre_score group.

* ۶) t زوجی در گروه مداخله.
TEMPORARY.
SELECT IF group = 'intervention'.
T-TEST PAIRS=pre_score WITH post_score (PAIRED).

* ۷) کای‌اسکوئر، ANOVA با توکی، کروسکال-والیس.
CROSSTABS /TABLES=region BY smoker /STATISTICS=CHISQ /CELLS=COUNT EXPECTED.
AUTORECODE VARIABLES=region /INTO region_n.
ONEWAY pre_score BY region_n /STATISTICS=DESCRIPTIVES HOMOGENEITY WELCH /POSTHOC=TUKEY.
NPAR TESTS /K-W=pre_score BY region_n(1 5).

* ۸) همبستگی و رگرسیون.
CORRELATIONS /VARIABLES=age pre_score.
NONPAR CORR /VARIABLES=age scale /PRINT=SPEARMAN.
REGRESSION /STATISTICS COEFF CI(95) R ANOVA COLLIN TOL
  /DEPENDENT pre_score /METHOD=ENTER age sex
  /RESIDUALS HISTOGRAM(ZRESID) NORMPROB(ZRESID).
LOGISTIC REGRESSION VARIABLES disease /METHOD=ENTER smoker age sex /PRINT=CI(95).

* ۹) مدل آمیخته برای داده خوشه‌ای (دانش‌آموز درون مدرسه).
MIXED post_score BY group WITH pre_score
  /FIXED=group pre_score
  /RANDOM=INTERCEPT | SUBJECT(school)
  /PRINT=SOLUTION TESTCOV.

* ۱۰) جانهی چندگانه: Analyze > Multiple Imputation (ماژول Missing Values).
