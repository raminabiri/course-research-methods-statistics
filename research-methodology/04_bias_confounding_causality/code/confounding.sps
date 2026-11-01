* =============================================================.
* فصل ۴ — کنترل مخدوش‌گری در SPSS: طبقه‌بندی (Mantel–Haenszel) و رگرسیون لجستیک.
* فقط مسیر FILE HANDLE را تغییر دهید.
* =============================================================.
FILE HANDLE datadir /NAME='C:/research_methods/data'.
INSERT FILE='datadir/load_survey.sps'.

RECODE age (18 THRU 35=1) (36 THRU 50=2) (51 THRU 65=3) INTO age_grp.
VALUE LABELS age_grp 1 '18-35' 2 '36-50' 3 '51-65'.
RECODE smoker (1=1) (0=2) INTO smoker_r.
RECODE disease (1=1) (0=2) INTO disease_r.
EXECUTE.

* ۱) OR خام.
CROSSTABS /TABLES=smoker_r BY disease_r /STATISTICS=CHISQ RISK /CELLS=COUNT ROW.

* ۲) OR در هر طبقه سنی + OR مشترک Mantel–Haenszel + آزمون همگنی Breslow–Day.
CROSSTABS /TABLES=smoker_r BY disease_r BY age_grp
  /STATISTICS=RISK CMH(1)
  /CELLS=COUNT ROW.

* ۳) رگرسیون لجستیک: خام و تعدیل‌شده برای سن (Exp(B) = OR).
LOGISTIC REGRESSION VARIABLES disease
  /METHOD=ENTER smoker
  /PRINT=CI(95).
LOGISTIC REGRESSION VARIABLES disease
  /METHOD=ENTER smoker age
  /PRINT=CI(95).

* ۴) آزمون تعدیل اثر (تعامل سیگار × سن).
LOGISTIC REGRESSION VARIABLES disease
  /METHOD=ENTER smoker age smoker*age
  /PRINT=CI(95).
