# =============================================================
# فصل ۸ — از داده خام تا تحلیل: بررسی کیفیت، داده گمشده، توصیف،
# انتخاب آزمون، ANCOVA، رگرسیون، اصلاح مقایسه‌های چندگانه (R پایه)
# اجرا از ریشه پروژه: Rscript 08_data_management_analysis/code/analysis.R
# =============================================================
dat <- read.csv("data/survey_data.csv", stringsAsFactors = TRUE)

## ---- ۱) بررسی ساختار و کیفیت داده
str(dat[, 1:8])
cat("\nMissing values per variable:\n"); print(colSums(is.na(dat))[colSums(is.na(dat)) > 0])
cat("Out-of-range Likert values:", sum(dat[, paste0("q", 1:10)] < 1 | dat[, paste0("q", 1:10)] > 5), "\n")
cat("Duplicated IDs:", sum(duplicated(dat$id)), "\n")
summary(dat[, c("age", "pre_score", "post_score")])

# پرت‌ها: قاعده IQR
out <- boxplot.stats(dat$pre_score)$out
cat("Outliers in pre_score (IQR rule):", length(out), "\n")

# آیا گمشدگی به گروه بستگی دارد؟ (کنترل ساده MCAR)
print(table(group = dat$group, missing_post = is.na(dat$post_score)))

## ---- ۲) نمره‌سازی مقیاس (q1..q9؛ q10 در فصل ۵ حذف شد)
dat$scale <- rowSums(dat[, paste0("q", 1:9)])

## ---- ۳) جدول توصیفی به تفکیک گروه («جدول ۱»)
desc <- function(x) sprintf("%.1f (%.1f)", mean(x, na.rm = TRUE), sd(x, na.rm = TRUE))
tab1 <- rbind(
  n           = table(dat$group),
  `Age, mean (SD)`       = tapply(dat$age, dat$group, desc),
  `Female, n (%)`        = tapply(dat$sex, dat$group, function(x) sprintf("%d (%.0f%%)", sum(x), 100 * mean(x))),
  `Pre-score, mean (SD)` = tapply(dat$pre_score, dat$group, desc))
print(noquote(tab1))
# نکته: در RCT برای مقایسه ویژگی‌های پایه p-value گزارش نکنید (CONSORT).

## ---- ۴) بررسی پیش‌فرض‌ها
cat("\nShapiro-Wilk (post_score):", round(shapiro.test(dat$post_score)$p.value, 3), "\n")
cat("Variance ratio test p:", round(var.test(post_score ~ group, data = dat)$p.value, 3), "\n")

## ---- ۵) مقایسه دو گروه
print(t.test(post_score ~ group, data = dat))            # Welch t (پیش‌فرض R)
print(wilcox.test(post_score ~ group, data = dat))       # جایگزین ناپارامتری (من-ویتنی)

# اندازه اثر Cohen d
m <- tapply(dat$post_score, dat$group, mean, na.rm = TRUE)
s <- tapply(dat$post_score, dat$group, sd, na.rm = TRUE)
cat("Cohen d =", round(diff(m) / sqrt(mean(s^2)), 2), "\n")

## ---- ۶) ANCOVA: تحلیل ارجح برای طرح پیش‌آزمون–پس‌آزمون
anc <- lm(post_score ~ group + pre_score, data = dat)
print(round(cbind(coef(summary(anc)), confint(anc)), 3))

## ---- ۷) زوجی درون گروه مداخله (پیش در برابر پس)
iv <- subset(dat, group == "intervention" & !is.na(post_score))
print(t.test(iv$post_score, iv$pre_score, paired = TRUE))

## ---- ۸) دو متغیر طبقه‌ای و ANOVA
print(chisq.test(table(dat$region, dat$smoker)))
fit_aov <- aov(pre_score ~ region, data = dat)
print(summary(fit_aov)); print(TukeyHSD(fit_aov)$region[1:4, ])
print(kruskal.test(pre_score ~ region, data = dat))

## ---- ۹) همبستگی و رگرسیون
print(cor.test(dat$age, dat$pre_score))                       # پیرسون
print(cor.test(dat$age, dat$scale, method = "spearman", exact = FALSE))
reg <- lm(pre_score ~ age + sex + region, data = dat)
print(summary(reg)$coef); cat("R2 =", round(summary(reg)$r.squared, 3), "\n")
logit <- glm(disease ~ smoker + age + sex, family = binomial, data = dat)
print(round(exp(cbind(OR = coef(logit), confint.default(logit))), 3))

## ---- ۱۰) اصلاح مقایسه‌های چندگانه
p <- c(0.001, 0.012, 0.021, 0.04, 0.049, 0.3)
print(round(rbind(raw = p,
                  bonferroni = p.adjust(p, "bonferroni"),
                  holm = p.adjust(p, "holm"),
                  BH_FDR = p.adjust(p, "BH")), 3))

## ---- ۱۱) اختیاری: داده خوشه‌ای (دانش‌آموز درون مدرسه) با مدل آمیخته
if (requireNamespace("lme4", quietly = TRUE)) {
  mm <- lme4::lmer(post_score ~ group + pre_score + (1 | school), data = dat)
  print(summary(mm)$coefficients)
}
# جانهی چندگانه داده گمشده: بسته mice →  imp <- mice(dat, m = 20); pool(with(imp, lm(...)))
