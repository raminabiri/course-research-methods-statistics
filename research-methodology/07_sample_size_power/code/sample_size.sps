* =============================================================.
* فصل ۷ — تحلیل توان و حجم نمونه در SPSS (دستورات POWER از نسخه ۲۷ به بعد).
* نحو این دستورات بین نسخه‌ها کمی تفاوت دارد. اگر خطا گرفتید:
*   Analyze > Power Analysis > (Means / Proportions / Correlations / Regression)
*   را پر کنید و دکمه Paste را بزنید تا نحو دقیق نسخه خودتان تولید شود.
* =============================================================.

* ۱) دو میانگین مستقل: تفاوت ۵، SD = 10، توان ۰٫۸ (انتظار: حدود ۶۴ در هر گروه).
POWER MEANS INDEPENDENT
  /PARAMETERS TEST=NONDIRECTIONAL SIGNIFICANCE=0.05 POWER=0.8
    MEAN=55 50 SD=10 NRATIO=1.

* ۲) طرح زوجی: میانگین تفاوت ۳، SD تفاوت‌ها ۸ (انتظار: حدود ۵۸ جفت).
POWER MEANS RELATED
  /PARAMETERS TEST=NONDIRECTIONAL SIGNIFICANCE=0.05 POWER=0.8
    MEAN=3 SD=8.

* ۳) دو نسبت مستقل: ۰٫۳۰ در برابر ۰٫۴۵ (انتظار: حدود ۱۶۳ در هر گروه).
POWER PROPORTIONS INDEPENDENT
  /PARAMETERS TEST=NONDIRECTIONAL SIGNIFICANCE=0.05 POWER=0.8
    PROPORTIONS=0.45 0.30 NRATIO=1.

* ۴) همبستگی پیرسون r = 0.3 (انتظار: حدود ۸۵).
POWER PEARSON ONESAMPLE
  /PARAMETERS TEST=NONDIRECTIONAL SIGNIFICANCE=0.05 POWER=0.8
    NULL=0 ALTERNATIVE=0.3.

* ۵) ANOVA یک‌طرفه سه گروه (نسخه ۲۸ به بعد).
POWER ONEWAY ANOVA
  /PARAMETERS SIGNIFICANCE=0.05 POWER=0.8
    GROUP_MEANS=50 55 58 POOLED_SD=12.

* ۶) رگرسیون خطی چندگانه: از منو Analyze > Power Analysis > Regression > Univariate Linear.
*    مقدار f2 = 0.15 را به صورت R2 = f2/(1+f2) = 0.13 با ۵ پیش‌بین وارد کنید (انتظار: n = 92).

* ۷) منحنی توان: در همه دیالوگ‌ها گزینه Plot (Power by sample size) را فعال کنید.
