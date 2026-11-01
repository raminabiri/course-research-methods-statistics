* =============================================================.
* فصل ۵ — روایی و پایایی در SPSS.
* فقط مسیر FILE HANDLE را تغییر دهید.
* =============================================================.
FILE HANDLE datadir /NAME='C:/research_methods/data'.
INSERT FILE='datadir/load_survey.sps'.

* ۱) آلفای کرونباخ + آماره‌های گویه (همبستگی اصلاح‌شده گویه-کل و آلفا در صورت حذف).
RELIABILITY /VARIABLES=q1 TO q10
  /SCALE('All items') ALL
  /MODEL=ALPHA
  /STATISTICS=DESCRIPTIVE SCALE CORR
  /SUMMARY=TOTAL.

* امگای مک‌دونالد (نسخه‌های جدید SPSS؛ اگر نسخه شما MODEL=OMEGA ندارد، از کد R استفاده کنید).
RELIABILITY /VARIABLES=q1 TO q9
  /SCALE('Without q10') ALL
  /MODEL=OMEGA.

* ۲) دونیمه‌سازی (اسپیرمن-براون).
RELIABILITY /VARIABLES=q1 TO q9 /MODEL=SPLIT.

* ۳) تحلیل عاملی اکتشافی: KMO، بارتلت، نمودار سنگ‌ریزه، حداکثر درست‌نمایی، چرخش مایل.
FACTOR /VARIABLES q1 TO q10
  /PRINT=INITIAL KMO EXTRACTION ROTATION
  /FORMAT=SORT BLANK(.30)
  /PLOT=EIGEN
  /CRITERIA=MINEIGEN(1) ITERATE(50)
  /EXTRACTION=ML
  /ROTATION=PROMAX(4).

* ۴) پایایی بین ارزیاب.
GET DATA /TYPE=TXT /FILE='datadir/raters.csv' /DELIMITERS="," /ARRANGEMENT=DELIMITED /FIRSTCASE=2
  /VARIABLES= id F3 rater1 F1 rater2 F1 score_r1 F6.1 score_r2 F6.1 score_r3 F6.1.
DATASET NAME raters.

* کاپای کوهن (دو ارزیاب، متغیر طبقه‌ای).
CROSSTABS /TABLES=rater1 BY rater2 /STATISTICS=KAPPA /CELLS=COUNT.

* ICC(2,1): دوطرفه تصادفی، توافق مطلق — سطر Single Measures را گزارش کنید.
RELIABILITY /VARIABLES=score_r1 score_r2 score_r3
  /SCALE('ICC') ALL
  /MODEL=ALPHA
  /ICC=MODEL(RANDOM) TYPE(ABSOLUTE) CIN=95 TESTVAL=0.

* ICC(3,1): دوطرفه مختلط، سازگاری.
RELIABILITY /VARIABLES=score_r1 score_r2 score_r3
  /SCALE('ICC') ALL
  /MODEL=ALPHA
  /ICC=MODEL(MIXED) TYPE(CONSISTENCY) CIN=95 TESTVAL=0.

* کاپای وزنی (SPSS 27 به بعد): Analyze > Scale > Weighted Kappa.
* کاپای فلایس برای بیش از دو ارزیاب (SPSS 26 به بعد): Analyze > Scale > Reliability Analysis > Statistics > Fleiss Kappa.
