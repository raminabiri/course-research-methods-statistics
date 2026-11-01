# =============================================================
# فصل ۷ — محاسبه حجم نمونه و توان آماری (R پایه + بسته اختیاری pwr)
# اجرا از ریشه پروژه: Rscript 07_sample_size_power/code/sample_size.R
# همه نتایج را به عدد صحیح بعدی گرد کنید (ceiling).
# =============================================================
z <- function(p) qnorm(p)

## ---- ۱) برآورد یک میانگین با دقت d (نصف عرض CI)
n_mean <- function(sd, d, conf = .95) ceiling((z(1 - (1 - conf) / 2) * sd / d)^2)
cat("1) Mean, SD=15, d=2:", n_mean(15, 2), "\n")

## ---- ۲) برآورد یک نسبت با دقت مطلق d + اصلاح جامعه محدود (فرمول کوکران)
n_prop <- function(p, d, conf = .95, N = Inf) {
  n0 <- z(1 - (1 - conf) / 2)^2 * p * (1 - p) / d^2
  ceiling(if (is.finite(N)) n0 / (1 + (n0 - 1) / N) else n0)
}
cat("2) Proportion p=0.3, d=0.05:", n_prop(.3, .05),
    "| with N=2000:", n_prop(.3, .05, N = 2000),
    "| unknown p (0.5):", n_prop(.5, .05), "\n")

## ---- ۳) مقایسه دو میانگین مستقل (هر گروه)
n_two_means <- function(sd, delta, alpha = .05, power = .8, ratio = 1) {
  n1 <- (1 + 1 / ratio) * sd^2 * (z(1 - alpha / 2) + z(power))^2 / delta^2
  c(n1 = ceiling(n1), n2 = ceiling(n1 * ratio))
}
cat("3) Two means, SD=10, delta=5 (d=0.5):", n_two_means(10, 5), "\n")
print(power.t.test(delta = 5, sd = 10, power = .8))        # دقیق‌تر (توزیع t): 64 در هر گروه

## ---- ۴) مقایسه دو نسبت مستقل
n_two_props <- function(p1, p2, alpha = .05, power = .8) {
  pb <- (p1 + p2) / 2
  ceiling((z(1 - alpha / 2) * sqrt(2 * pb * (1 - pb)) +
           z(power) * sqrt(p1 * (1 - p1) + p2 * (1 - p2)))^2 / (p1 - p2)^2)
}
cat("\n4) Two proportions 0.30 vs 0.45:", n_two_props(.30, .45), "per group\n")
print(power.prop.test(p1 = .30, p2 = .45, power = .8))

## ---- ۵) طرح زوجی (پیش-پس): sd = انحراف معیار تفاوت‌ها
print(power.t.test(delta = 3, sd = 8, power = .8, type = "paired"))

## ---- ۶) ضریب همبستگی (تبدیل فیشر)
n_corr <- function(r, alpha = .05, power = .8)
  ceiling(((z(1 - alpha / 2) + z(power)) / (0.5 * log((1 + r) / (1 - r))))^2 + 3)
cat("6) Correlation r=0.3:", n_corr(.3), "\n")

## ---- ۷) ANOVA یک‌طرفه (۳ گروه)
# between.var و within.var: واریانس میانگین گروه‌ها و واریانس درون‌گروهی
print(power.anova.test(groups = 3, between.var = var(c(50, 55, 58)), within.var = 12^2, power = .8))

## ---- ۸) رگرسیون خطی چندگانه: آزمون F کل مدل با اندازه اثر f2 و u پیش‌بین
n_regression <- function(f2, u, alpha = .05, power = .8) {
  for (n in (u + 2):10000) {
    v <- n - u - 1
    pw <- 1 - pf(qf(1 - alpha, u, v), u, v, ncp = f2 * n)   # ncp مطابق G*Power
    if (pw >= power) return(n)
  }
}
cat("8) Regression f2=0.15, 5 predictors:", n_regression(.15, 5),
    "| rule of thumb Green (50+8m):", 50 + 8 * 5, "\n")

## ---- ۹) رگرسیون لجستیک: قاعده EPV (رویداد به ازای هر متغیر)
n_epv <- function(k, p_event, epv = 10) ceiling(epv * k / p_event)
cat("9) Logistic, 6 predictors, event rate 20%, EPV=10:", n_epv(6, .2), "\n")

## ---- ۱۰) تحلیل بقا: تعداد رویداد لازم (شوئنفلد) برای HR
events_hr <- function(hr, alpha = .05, power = .8, p_alloc = .5)
  ceiling((z(1 - alpha / 2) + z(power))^2 / (p_alloc * (1 - p_alloc) * log(hr)^2))
ev <- events_hr(.7)
cat("10) Survival, HR=0.7: events =", ev, "| if 40% will have the event: N =", ceiling(ev / .4), "\n")

## ---- ۱۱) مطالعه تشخیصی (بودرر): حساسیت مورد انتظار، دقت d، شیوع
n_sens <- function(se, d, prev, conf = .95) {
  n_dis <- z(1 - (1 - conf) / 2)^2 * se * (1 - se) / d^2
  c(diseased = ceiling(n_dis), total = ceiling(n_dis / prev))
}
cat("11) Sensitivity 0.9 ± 0.05, prevalence 20%:", n_sens(.9, .05, .2), "\n")

## ---- ۱۲) کارآزمایی عدم‌برتری (پیامد پیوسته): حاشیه M، تفاوت واقعی فرضی = 0
n_noninf <- function(sd, M, true_diff = 0, alpha = .025, power = .8)
  ceiling(2 * sd^2 * (z(1 - alpha) + z(power))^2 / (M - true_diff)^2)
cat("12) Non-inferiority SD=10, margin=4 (one-sided alpha 0.025):", n_noninf(10, 4), "per group\n")

## ---- ۱۳) تعدیل‌ها: اثر طرح خوشه‌ای و ریزش
adjust <- function(n, m = 1, icc = 0, dropout = 0) ceiling(n * (1 + (m - 1) * icc) / (1 - dropout))
cat("13) 64/group, clusters of 20, ICC=0.05, 15% dropout:", adjust(64, 20, .05, .15), "per group\n")

## ---- ۱۴) منحنی توان: حجم نمونه در برابر توان برای d = 0.2, 0.5, 0.8
png("07_sample_size_power/code/power_curve.png", width = 750, height = 480)
ns <- 5:200
plot(NA, xlim = range(ns), ylim = c(0, 1), xlab = "n per group", ylab = "Power",
     main = "Power of two-sample t-test (alpha = 0.05)")
for (d in c(.2, .5, .8)) lines(ns, power.t.test(n = ns, delta = d, sd = 1)$power, lwd = 2, lty = which(c(.2, .5, .8) == d))
abline(h = .8, col = "grey50", lty = 3)
legend("bottomright", c("d = 0.2 (small)", "d = 0.5 (medium)", "d = 0.8 (large)"), lty = 1:3, lwd = 2)
invisible(dev.off())

## ---- ۱۵) اختیاری: بسته pwr (هم‌خوان با G*Power)
if (requireNamespace("pwr", quietly = TRUE)) {
  library(pwr)
  print(pwr.t.test(d = .5, power = .8))
  print(pwr.2p.test(h = ES.h(.45, .30), power = .8))
  print(pwr.r.test(r = .3, power = .8))
  print(pwr.f2.test(u = 5, f2 = .15, power = .8))   # n = v + u + 1
  print(pwr.chisq.test(w = .3, df = 2, power = .8))
}
