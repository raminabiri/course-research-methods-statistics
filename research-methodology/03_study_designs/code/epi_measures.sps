* =============================================================.
* فصل ۳ — شاخص‌های اپیدمیولوژیک در SPSS.
* فقط مسیر FILE HANDLE را به محل پوشه data روی سیستم خود تغییر دهید.
* =============================================================.

FILE HANDLE datadir /NAME='C:/research_methods/data'.
INSERT FILE='datadir/load_survey.sps'.

* RISK خروجی OR و RR (برای هر ستون پیامد) را با فاصله اطمینان می‌دهد.
* SPSS سطرها را صعودی مرتب می‌کند؛ با بازکد، مواجهه‌یافته و بیمار در سطر/ستون اول قرار می‌گیرند.
RECODE smoker (1=1) (0=2) INTO smoker_r.
RECODE disease (1=1) (0=2) INTO disease_r.
VALUE LABELS smoker_r 1 'Smoker' 2 'Non-smoker' /disease_r 1 'Disease' 2 'No disease'.
CROSSTABS /TABLES=smoker_r BY disease_r
  /STATISTICS=CHISQ RISK
  /CELLS=COUNT ROW.

* دقت تشخیصی: داده تجمیعی را با WEIGHT وارد کنید.
DATA LIST FREE / test disease n.
BEGIN DATA
1 1 90
1 2 30
2 1 10
2 2 270
END DATA.
DATASET NAME diag.
VALUE LABELS test 1 'Positive' 2 'Negative' /disease 1 'Disease' 2 'Healthy'.
WEIGHT BY n.
* حساسیت و ویژگی = درصد ستونی؛ PPV و NPV = درصد سطری.
CROSSTABS /TABLES=test BY disease /CELLS=COUNT ROW COLUMN.
WEIGHT OFF.
