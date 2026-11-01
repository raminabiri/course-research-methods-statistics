# =============================================================
# فصل ۲ — متاآنالیز تفاوت میانگین استانداردشده (Hedges g)
# با R پایه + مقایسه اختیاری با بسته metafor
# اجرا از ریشه پروژه: Rscript 02_literature_review/code/meta_analysis.R
# =============================================================
dat <- read.csv("data/meta_studies.csv")

## ---- ۱) اندازه اثر هر مطالعه
sp  <- sqrt(((dat$n1 - 1) * dat$sd1^2 + (dat$n2 - 1) * dat$sd2^2) / (dat$n1 + dat$n2 - 2))
d   <- (dat$mean1 - dat$mean2) / sp
J   <- 1 - 3 / (4 * (dat$n1 + dat$n2) - 9)            # اصلاح سوگیری نمونه کوچک
dat$g  <- J * d
dat$vg <- J^2 * ((dat$n1 + dat$n2) / (dat$n1 * dat$n2) + d^2 / (2 * (dat$n1 + dat$n2)))

## ---- ۲) مدل اثر ثابت (وزن معکوس واریانس)
w      <- 1 / dat$vg
g_fe   <- sum(w * dat$g) / sum(w)
se_fe  <- sqrt(1 / sum(w))

## ---- ۳) ناهمگونی و مدل اثرات تصادفی (DerSimonian–Laird)
k    <- nrow(dat)
Q    <- sum(w * (dat$g - g_fe)^2)
tau2 <- max(0, (Q - (k - 1)) / (sum(w) - sum(w^2) / sum(w)))
I2   <- max(0, (Q - (k - 1)) / Q) * 100
wr    <- 1 / (dat$vg + tau2)
g_re  <- sum(wr * dat$g) / sum(wr)
se_re <- sqrt(1 / sum(wr))
pi_lo <- g_re - qt(.975, k - 2) * sqrt(tau2 + se_re^2)  # فاصله پیش‌بینی
pi_hi <- g_re + qt(.975, k - 2) * sqrt(tau2 + se_re^2)

cat(sprintf("Fixed : g = %.3f  95%%CI [%.3f, %.3f]\n", g_fe, g_fe - 1.96 * se_fe, g_fe + 1.96 * se_fe))
cat(sprintf("Random: g = %.3f  95%%CI [%.3f, %.3f]  PI [%.3f, %.3f]\n",
            g_re, g_re - 1.96 * se_re, g_re + 1.96 * se_re, pi_lo, pi_hi))
cat(sprintf("Q = %.2f (df = %d, p = %.3f), I2 = %.1f%%, tau2 = %.4f\n",
            Q, k - 1, pchisq(Q, k - 1, lower.tail = FALSE), I2, tau2))

## ---- ۴) نمودار جنگلی (R پایه)
png("02_literature_review/code/forest_plot.png", width = 800, height = 500)
lo <- dat$g - 1.96 * sqrt(dat$vg); hi <- dat$g + 1.96 * sqrt(dat$vg)
y  <- k:1
plot(dat$g, y, xlim = range(c(lo, hi, 0)), ylim = c(-1, k + 0.5), pch = 15,
     cex = 3 * sqrt(wr / max(wr)), yaxt = "n", xlab = "Hedges g", ylab = "",
     main = "Forest plot (random effects)")
segments(lo, y, hi, y)
abline(v = 0, lty = 2)
polygon(c(g_re - 1.96 * se_re, g_re, g_re + 1.96 * se_re, g_re), c(0, 0.3, 0, -0.3), col = "grey40")
axis(2, at = c(y, 0), labels = c(dat$study, "Pooled (RE)"), las = 1, cex.axis = .8)
invisible(dev.off())

## ---- ۵) تحلیل حساسیت: حذف یکی‌یکی
loo <- sapply(1:k, function(i) {
  x <- dat[-i, ]; wi <- 1 / x$vg; gf <- sum(wi * x$g) / sum(wi)
  Qi <- sum(wi * (x$g - gf)^2)
  t2 <- max(0, (Qi - (k - 2)) / (sum(wi) - sum(wi^2) / sum(wi)))
  wri <- 1 / (x$vg + t2); sum(wri * x$g) / sum(wri)
})
print(data.frame(omitted = dat$study, pooled_g = round(loo, 3)))

## ---- ۶) آزمون Egger (عدم تقارن نمودار قیفی؛ با k<10 توان کم است)
egger <- lm(I(dat$g / sqrt(dat$vg)) ~ I(1 / sqrt(dat$vg)))
cat("Egger intercept p =", round(summary(egger)$coef[1, 4], 3), "\n")

## ---- ۷) اختیاری: همان تحلیل با metafor
if (requireNamespace("metafor", quietly = TRUE)) {
  library(metafor)
  es  <- escalc("SMD", m1i = mean1, sd1i = sd1, n1i = n1, m2i = mean2, sd2i = sd2, n2i = n2, data = dat)
  res <- rma(yi, vi, data = es, method = "DL")
  print(res); # forest(res); funnel(res); regtest(res); leave1out(res)
}
