# =============================================================
# فصل ۴ — مخدوش‌گری، Mantel–Haenszel، برخورددهنده (Collider)،
# بازگشت به میانگین و پارادوکس سیمپسون (R پایه)
# اجرا از ریشه پروژه: Rscript 04_bias_confounding_causality/code/confounding.R
# =============================================================
dat <- read.csv("data/survey_data.csv")

## ---- ۱) OR خام در برابر OR تعدیل‌شده برای سن
crude <- glm(disease ~ smoker, family = binomial, data = dat)
adj   <- glm(disease ~ smoker + age, family = binomial, data = dat)
cat("Crude OR    :", round(exp(coef(crude)["smoker"]), 2), "\n")
cat("Adjusted OR :", round(exp(coef(adj)["smoker"]), 2),
    " 95%CI", round(exp(confint.default(adj)["smoker", ]), 2), "\n")

## ---- ۲) طبقه‌بندی بر اساس گروه سنی + Mantel–Haenszel
dat$age_grp <- cut(dat$age, c(17, 35, 50, 65), labels = c("18-35", "36-50", "51-65"))
st <- table(factor(dat$smoker, 1:0), factor(dat$disease, 1:0), dat$age_grp,
            dnn = c("smoker", "disease", "age"))
for (k in dimnames(st)$age) {
  t <- st[, , k]; cat("OR in age", k, "=", round(t[1,1]*t[2,2] / (t[1,2]*t[2,1]), 2), "\n")
}
print(mantelhaen.test(st))       # OR مشترک MH + آزمون CMH
# همگنی OR بین طبقات (Breslow-Day) در بسته DescTools: BreslowDayTest(st)

## ---- ۳) شبیه‌سازی: سوگیری برخورددهنده (Collider bias)
set.seed(1)
n <- 5000
talent <- rnorm(n); looks <- rnorm(n)                    # مستقل از هم
hired  <- (talent + looks + rnorm(n, 0, .5)) > 1.5       # برخورددهنده
cat("\nCorrelation in population:", round(cor(talent, looks), 3), "\n")
cat("Correlation among hired  :", round(cor(talent[hired], looks[hired]), 3), "\n")

## ---- ۴) شبیه‌سازی: بازگشت به میانگین
true <- rnorm(n, 100, 10)
t1   <- true + rnorm(n, 0, 8); t2 <- true + rnorm(n, 0, 8)  # بدون هیچ مداخله
worst <- t1 < quantile(t1, .10)
cat("\nWorst 10% at time 1:", round(mean(t1[worst]), 1),
    "-> time 2:", round(mean(t2[worst]), 1), "(no intervention!)\n")

## ---- ۵) پارادوکس سیمپسون (داده کلاسیک سنگ کلیه، Charig 1986)
kid <- array(c(81, 6, 234, 36,   192, 71, 55, 25), dim = c(2, 2, 2),
             dimnames = list(result = c("success", "fail"),
                             treatment = c("A_open", "B_PCNL"),
                             stone = c("small", "large")))
rate <- function(x) round(x["success", ] / colSums(x), 2)
cat("\nSmall stones:", rate(kid[, , "small"]), "\n")
cat("Large stones:", rate(kid[, , "large"]), "\n")
cat("Pooled      :", rate(apply(kid, 1:2, sum)), "\n")
