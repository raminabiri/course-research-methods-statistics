# =============================================================
# فصل ۳ — شاخص‌های اپیدمیولوژیک و دقت تشخیصی (R پایه)
# اجرا از ریشه پروژه: Rscript 03_study_designs/code/epi_measures.R
# =============================================================

## ---- تابع: RR، OR، RD، NNT با فاصله اطمینان ۹۵٪ از جدول ۲×۲
epi2x2 <- function(a, b, c, d, conf = 0.95) {
  z  <- qnorm(1 - (1 - conf) / 2)
  r1 <- a / (a + b); r0 <- c / (c + d)
  RR <- r1 / r0;  se_lrr <- sqrt(1/a - 1/(a + b) + 1/c - 1/(c + d))
  OR <- (a * d) / (b * c); se_lor <- sqrt(1/a + 1/b + 1/c + 1/d)
  RD <- r1 - r0;  se_rd <- sqrt(r1 * (1 - r1) / (a + b) + r0 * (1 - r0) / (c + d))
  out <- rbind(
    RR = c(RR, exp(log(RR) + c(-1, 1) * z * se_lrr)),
    OR = c(OR, exp(log(OR) + c(-1, 1) * z * se_lor)),
    RD = c(RD, RD + c(-1, 1) * z * se_rd))
  colnames(out) <- c("estimate", "lower", "upper")
  print(round(out, 3))
  cat("NNT/NNH =", round(1 / abs(RD), 1), "\n")
  invisible(out)
}

## ---- مثال ۱: همگروهی سیگار و بیماری از داده درس
dat <- read.csv("data/survey_data.csv")
tab <- table(smoker = factor(dat$smoker, 1:0), disease = factor(dat$disease, 1:0))
print(tab)
epi2x2(tab[1, 1], tab[1, 2], tab[2, 1], tab[2, 2])
print(chisq.test(tab))

## ---- مثال ۲: کارآزمایی — بهبود در ۶۰ از ۱۰۰ (مداخله) در برابر ۴۵ از ۱۰۰ (کنترل)
epi2x2(60, 40, 45, 55)

## ---- تابع: دقت تشخیصی
diag_acc <- function(tp, fp, fn, tn) {
  se <- tp / (tp + fn); sp <- tn / (tn + fp)
  res <- c(sensitivity = se, specificity = sp,
           PPV = tp / (tp + fp), NPV = tn / (tn + fn),
           LR_pos = se / (1 - sp), LR_neg = (1 - se) / sp,
           accuracy = (tp + tn) / (tp + fp + fn + tn))
  round(res, 3)
}
# مثال: آزمون سریع در برابر استاندارد مرجع
print(diag_acc(tp = 90, fp = 30, fn = 10, tn = 270))

## ---- اثر شیوع بر PPV (حساسیت ۰٫۹، ویژگی ۰٫۹)
prev <- c(0.01, 0.05, 0.10, 0.30, 0.50)
ppv  <- 0.9 * prev / (0.9 * prev + 0.1 * (1 - prev))
print(data.frame(prevalence = prev, PPV = round(ppv, 3)))
