* =============================================================.
* بارگذاری survey_data.csv در SPSS — همه فایل‌های .sps درس این را INSERT می‌کنند.
* پیش از INSERT باید FILE HANDLE datadir تعریف شده باشد، مثلاً:.
*   FILE HANDLE datadir /NAME='C:/research_methods/data'.
* =============================================================.
GET DATA /TYPE=TXT
  /FILE='datadir/survey_data.csv'
  /ENCODING='UTF8'
  /DELIMITERS=","  /QUALIFIER='"'  /ARRANGEMENT=DELIMITED  /FIRSTCASE=2
  /VARIABLES= id F4 region A10 school F3 sex F1 age F3 group A15
    pre_score F6.1 post_score F6.1
    q1 F1 q2 F1 q3 F1 q4 F1 q5 F1 q6 F1 q7 F1 q8 F1 q9 F1 q10 F1
    smoker F1 disease F1.
DATASET NAME survey.
VALUE LABELS sex 0 'Male' 1 'Female'
  /smoker 1 'Smoker' 0 'Non-smoker'
  /disease 1 'Disease' 0 'No disease'.
VARIABLE LEVEL id school (NOMINAL) region group sex smoker disease (NOMINAL)
  age pre_score post_score (SCALE) q1 q2 q3 q4 q5 q6 q7 q8 q9 q10 (ORDINAL).
EXECUTE.
