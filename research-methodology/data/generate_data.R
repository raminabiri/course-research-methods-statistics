# =============================================================
# ساخت داده‌های شبیه‌سازی‌شده برای تمرین‌های درس روش تحقیق
# اجرا:  Rscript data/generate_data.R   (از ریشه پروژه)
# خروجی: survey_data.csv , raters.csv , meta_studies.csv
# همه کدهای R و SPSS درس از این فایل‌ها استفاده می‌کنند.
# =============================================================
set.seed(2026)
out_dir <- if (dir.exists("data")) "data" else "."

## ---- 1) داده پیمایش/کارآزمایی: ۴۰۰ نفر در ۴۰ مدرسه (خوشه) و ۵ منطقه (طبقه)
n        <- 400
school   <- rep(1:40, each = 10)
region   <- c("North", "South", "East", "West", "Center")[(school - 1) %/% 8 + 1]
school_e <- rnorm(40, 0, 3)[school]                 # اثر خوشه (ICC)
sex      <- rbinom(n, 1, 0.5)                       # 1 = زن
age      <- round(runif(n, 18, 65))
group    <- ifelse(rbinom(n, 1, 0.5) == 1, "intervention", "control")
pre      <- round(50 + 0.15 * age + school_e + rnorm(n, 0, 10), 1)
post     <- round(pre + ifelse(group == "intervention", 5, 0) + rnorm(n, 0, 8), 1)

# متغیر پنهان برای ۱۰ گویه لیکرت (برای روایی/پایایی)
latent <- rnorm(n)
likert <- sapply(1:10, function(k) {
  x <- 0.8 * latent + rnorm(n, 0, 0.7)
  if (k == 10) x <- rnorm(n)                        # گویه ۱۰ عمداً ضعیف است
  as.integer(cut(x, c(-Inf, -1.2, -0.4, 0.4, 1.2, Inf)))
})
colnames(likert) <- paste0("q", 1:10)

# مخدوش‌گری: سن هم سیگار کشیدن را زیاد می‌کند هم بیماری را
smoker  <- rbinom(n, 1, plogis(-4 + 0.09 * age))
disease <- rbinom(n, 1, plogis(-7 + 0.11 * age))       # سیگار در واقع اثری ندارد

# داده گمشده عمدی (برای تمرین پاک‌سازی)
post[sample(n, 12)] <- NA

survey <- data.frame(id = 1:n, region, school, sex, age, group,
                     pre_score = pre, post_score = post, likert,
                     smoker, disease)
write.csv(survey, file.path(out_dir, "survey_data.csv"), row.names = FALSE)

## ---- 2) داده توافق ارزیاب‌ها (کاپا و ICC)
m      <- 60
truth  <- sample(1:3, m, replace = TRUE, prob = c(.4, .35, .25))
noisy  <- function(t) ifelse(runif(m) < 0.8, t, sample(1:3, m, replace = TRUE))
true_s <- rnorm(m, 70, 10)
raters <- data.frame(id = 1:m, rater1 = noisy(truth), rater2 = noisy(truth),
                     score_r1 = round(true_s + rnorm(m, 0, 4), 1),
                     score_r2 = round(true_s + 2 + rnorm(m, 0, 4), 1),
                     score_r3 = round(true_s + rnorm(m, 0, 4), 1))
write.csv(raters, file.path(out_dir, "raters.csv"), row.names = FALSE)

## ---- 3) داده متاآنالیز: ۸ مطالعه با پیامد پیوسته
k    <- 8
n1   <- sample(20:120, k); n2 <- sample(20:120, k)
d    <- rnorm(k, 0.4, 0.15)
meta <- data.frame(study = paste0("Study_", LETTERS[1:k]),
                   n1, mean1 = round(50 + d * 10 + rnorm(k, 0, 1), 2), sd1 = round(runif(k, 8, 12), 2),
                   n2, mean2 = round(50 + rnorm(k, 0, 1), 2),         sd2 = round(runif(k, 8, 12), 2))
write.csv(meta, file.path(out_dir, "meta_studies.csv"), row.names = FALSE)

cat("Data written to", normalizePath(out_dir), "\n")
