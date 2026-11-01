# فاز ۱ — مبانی مرور نظام‌مند

**مدت:** ۸ جلسه‌ی ۳ ساعته
**پیش‌نیاز:** فاز ۰ (اپیدمیولوژی و آمار پایه، نصب Zotero و Rayyan و R)
**خروجی فاز:** پروتکل ثبت‌شدنی، راهبرد جست‌وجوی کامل، فایل غربالگری، فرم استخراج آزموده‌شده و جدول خطر سوگیری برای پرسش شخصی دانشجو

## چرا این فاز مهم‌ترین فاز است؟

متاآنالیز فقط به اندازه‌ی مرور نظام‌مندی که زیر آن قرار دارد معتبر است. پیچیده‌ترین مدل آماری هم نمی‌تواند جست‌وجوی ناقص، غربالگری یک‌نفره یا استخراج اشتباه را جبران کند. بیشتر نقدهای داوران به مقاله‌های مرور نظام‌مند به همین مرحله‌ها مربوط است، نه به آمار.

## ماژول‌ها

| کد | عنوان | پوشه | کد R (برنامه‌ریزی) | وضعیت |
|---|---|---|---|---|
| P1-M01 | انواع مرور و جایگاه مرور نظام‌مند | [M01_review_types](M01_review_types/) | — | نوشته شده |
| P1-M02 | تدوین پرسش پژوهش | [M02_research_question](M02_research_question/) | — | نوشته شده |
| P1-M03 | پروتکل و ثبت آن | [M03_protocol_registration](M03_protocol_registration/) | — | خالی |
| P1-M04 | جست‌وجوی نظام‌مند | [M04_systematic_search](M04_systematic_search/) | `rentrez` | خالی |
| P1-M05 | مدیریت منابع و غربالگری | [M05_screening](M05_screening/) | `irr`، `PRISMA2020`، `synthesisr` | خالی |
| P1-M06 | استخراج داده | [M06_data_extraction](M06_data_extraction/) | `estmeansd` | خالی |
| P1-M07 | ارزیابی خطر سوگیری | [M07_risk_of_bias](M07_risk_of_bias/) | `robvis` | خالی |
| P1-M08 | گزارش‌دهی، نقد و اخلاق | [M08_reporting_appraisal](M08_reporting_appraisal/) | — | خالی |

## مسیر کار دانشجو در این فاز

```
M01 نوع مرور ─► M02 پرسش ─► M03 پروتکل ─► M04 جست‌وجو ─► M05 غربالگری
                                                              │
                         M08 گزارش و نقد ◄─ M07 سوگیری ◄─ M06 استخراج
```

## منابع اصلی فاز

1. Higgins JPT, Thomas J, Chandler J, et al. (editors). *Cochrane Handbook for Systematic Reviews of Interventions*. Current version. Cochrane. https://training.cochrane.org/handbook/current
2. Page MJ, McKenzie JE, Bossuyt PM, et al. The PRISMA 2020 statement. *BMJ* 2021;372:n71. https://doi.org/10.1136/bmj.n71
3. Aromataris E, Lockwood C, Porritt K, Pilla B, Jordan Z (editors). *JBI Manual for Evidence Synthesis*. JBI. https://synthesismanual.jbi.global
4. Boland A, Cherry MG, Dickson R (editors). *Doing a Systematic Review: A Student's Guide*. 2nd ed. SAGE; 2017. (کتاب درسی کمکی و مناسب برای شروع)

## اجرای کدها

کدهای R هر ماژول در پوشه‌ی `code/` همان ماژول قرار دارند و با داده‌های [data/phase1](../data/phase1/) کار می‌کنند. برای نصب همه‌ی بسته‌های این فاز:

```r
install.packages(c("rentrez", "synthesisr", "irr", "PRISMA2020",
                   "estmeansd", "robvis", "dplyr", "readr"))
```

کدها را از **ریشه‌ی مخزن** اجرا کنید (پوشه‌ی کاری RStudio = `SRMA/`).
