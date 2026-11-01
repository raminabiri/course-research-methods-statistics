# =============================================================
# فصل ۵ — روایی و پایایی: CVR/CVI، آلفای کرونباخ، تحلیل گویه،
# KMO/بارتلت، تحلیل عاملی اکتشافی، کاپا، ICC، SEM و MDC (R پایه)
# اجرا از ریشه پروژه: Rscript 05_measurement_questionnaire/code/reliability_validity.R
# =============================================================
dat   <- read.csv("data/survey_data.csv")
items <- dat[, paste0("q", 1:10)]

## ---- ۱) روایی محتوا: CVR (لاوشه) و CVI (والتز-باسل/پولیت)
# ۱۰ متخصص؛ ضرورت: 1=ضروری، 0=غیرضروری | مرتبط بودن: مقیاس ۱ تا ۴
set.seed(5)
essential <- matrix(rbinom(10 * 10, 1, c(.9, .9, .8, .9, .7, .9, .8, .9, .9, .4)), nrow = 10)  # سطر = گویه، ستون = متخصص
relevance <- matrix(sample(2:4, 100, TRUE, prob = c(.1, .3, .6)), nrow = 10)
N   <- ncol(essential)                       # تعداد متخصصان
ne  <- rowSums(essential)
CVR <- (ne - N / 2) / (N / 2)                # حداقل قابل قبول برای ۱۰ متخصص = 0.62
I_CVI <- rowMeans(relevance >= 3)            # نسبت نمره ۳ یا ۴؛ ≥ 0.79 مناسب
cat("CVR  :", round(CVR, 2), "\nI-CVI:", round(I_CVI, 2),
    "\nS-CVI/Ave =", round(mean(I_CVI), 2), "\n\n")

## ---- ۲) آلفای کرونباخ
cronbach <- function(x) {
  x <- na.omit(x); k <- ncol(x)
  k / (k - 1) * (1 - sum(apply(x, 2, var)) / var(rowSums(x)))
}
cat("Cronbach alpha (10 items):", round(cronbach(items), 3), "\n")

## ---- ۳) تحلیل گویه: همبستگی اصلاح‌شده گویه-کل و آلفا در صورت حذف
item_stats <- t(sapply(names(items), function(v) {
  rest <- rowSums(items[, names(items) != v])
  c(corrected_item_total = cor(items[[v]], rest),
    alpha_if_deleted     = cronbach(items[, names(items) != v]))
}))
print(round(item_stats, 3))

## ---- ۴) کفایت نمونه: KMO و آزمون کرویت بارتلت
R  <- cor(items)
Ri <- solve(R)
P  <- -Ri / sqrt(outer(diag(Ri), diag(Ri)))  # همبستگی‌های جزئی
diag(P) <- 0; R0 <- R; diag(R0) <- 0
KMO <- sum(R0^2) / (sum(R0^2) + sum(P^2))
n <- nrow(items); p <- ncol(items)
bart_chi <- -(n - 1 - (2 * p + 5) / 6) * log(det(R))
cat("\nKMO =", round(KMO, 3), "| Bartlett chi2 =", round(bart_chi, 1),
    "df =", p * (p - 1) / 2, "p =", signif(pchisq(bart_chi, p * (p - 1) / 2, lower.tail = FALSE), 3), "\n")

## ---- ۵) تحلیل عاملی اکتشافی (حداکثر درست‌نمایی) — تعداد عامل با مقادیر ویژه
cat("Eigenvalues:", round(eigen(R)$values, 2), "\n")
efa <- factanal(items, factors = 1)
print(efa$loadings, cutoff = 0)

## ---- ۶) پایایی بین ارزیاب‌ها: کاپای کوهن (متغیر طبقه‌ای)
rt <- read.csv("data/raters.csv")
kappa_cohen <- function(r1, r2) {
  t  <- table(factor(r1, 1:3), factor(r2, 1:3))
  po <- sum(diag(t)) / sum(t)
  pe <- sum(rowSums(t) * colSums(t)) / sum(t)^2
  (po - pe) / (1 - pe)
}
cat("\nCohen kappa =", round(kappa_cohen(rt$rater1, rt$rater2), 3), "\n")

## ---- ۷) ICC برای ۳ ارزیاب (متغیر پیوسته) از جدول ANOVA دوطرفه
icc <- function(Y) {
  Y <- as.matrix(Y); n <- nrow(Y); k <- ncol(Y); gm <- mean(Y)
  MSR <- k * sum((rowMeans(Y) - gm)^2) / (n - 1)                     # بین افراد
  MSC <- n * sum((colMeans(Y) - gm)^2) / (k - 1)                     # بین ارزیاب‌ها
  MSE <- (sum((Y - gm)^2) - MSR * (n - 1) - MSC * (k - 1)) / ((n - 1) * (k - 1))
  c(`ICC(2,1) absolute agreement` = (MSR - MSE) / (MSR + (k - 1) * MSE + k * (MSC - MSE) / n),
    `ICC(3,1) consistency`        = (MSR - MSE) / (MSR + (k - 1) * MSE))
}
ic <- icc(rt[, c("score_r1", "score_r2", "score_r3")])
print(round(ic, 3))

## ---- ۸) خطای معیار اندازه‌گیری (SEM) و حداقل تغییر قابل تشخیص (MDC95)
SD  <- sd(unlist(rt[, c("score_r1", "score_r2", "score_r3")]))
SEM <- SD * sqrt(1 - ic[1])
cat("SEM =", round(SEM, 2), "| MDC95 =", round(1.96 * sqrt(2) * SEM, 2), "\n")

## ---- ۹) اختیاری: بسته‌های تخصصی
if (requireNamespace("psych", quietly = TRUE)) {
  print(psych::alpha(items)$total)          # آلفا با جزئیات
  print(psych::omega(items, nfactors = 1, plot = FALSE)$omega.tot)  # امگا
  print(psych::KMO(items)$MSA)
  print(psych::ICC(rt[, 4:6])$results)
}
if (requireNamespace("irr", quietly = TRUE)) {
  print(irr::kappa2(rt[, c("rater1", "rater2")], weight = "squared"))  # کاپای وزنی
}
