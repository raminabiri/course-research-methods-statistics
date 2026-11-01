# =============================================================
# فصل ۱۱ — گزارش‌دهی قابل تکرار: جدول ۱ به CSV، جمله نتایج به سبک APA،
# و نمودار نقطه-فاصله اطمینان به جای نمودار میله‌ای «دینامیت» (R پایه)
# اجرا از ریشه پروژه: Rscript 11_reporting_publication/code/reporting.R
# =============================================================
dat <- read.csv("data/survey_data.csv")
dir <- "11_reporting_publication/code"

## ---- ۱) جدول ۱ (ویژگی‌های پایه) — خروجی CSV برای Word/Excel
fmt_mean <- function(x) sprintf("%.1f (%.1f)", mean(x, na.rm = TRUE), sd(x, na.rm = TRUE))
fmt_med  <- function(x) { q <- quantile(x, c(.5, .25, .75), na.rm = TRUE); sprintf("%.1f (%.1f–%.1f)", q[1], q[2], q[3]) }
fmt_n    <- function(x) sprintf("%d (%.1f%%)", sum(x), 100 * mean(x))
grp <- split(dat, dat$group)
table1 <- data.frame(
  Characteristic = c("n", "Age, years, mean (SD)", "Female, n (%)", "Smoker, n (%)",
                     "Pre-score, median (IQR)"),
  sapply(grp, function(g) c(nrow(g), fmt_mean(g$age), fmt_n(g$sex), fmt_n(g$smoker), fmt_med(g$pre_score))),
  check.names = FALSE)
print(table1, row.names = FALSE)
write.csv(table1, file.path(dir, "table1.csv"), row.names = FALSE, fileEncoding = "UTF-8")

## ---- ۲) جمله نتیجه به سبک APA 7 (اندازه اثر + CI + p دقیق)
fmt_p <- function(p) if (p < .001) "p < .001" else sprintf("p = %s", sub("^0", "", sprintf("%.3f", p)))
fit <- lm(post_score ~ group + pre_score, data = dat)
b   <- coef(summary(fit))["groupintervention", ]; ci <- confint(fit)["groupintervention", ]
cat(sprintf("\nAdjusted for baseline, the intervention group scored %.2f points higher (95%% CI [%.2f, %.2f]), t(%d) = %.2f, %s.\n",
            b[1], ci[1], ci[2], fit$df.residual, b[3], fmt_p(b[4])))

## ---- ۳) نمودار: میانگین و CI ۹۵٪ به‌همراه داده خام (به جای میله ± SE)
png(file.path(dir, "means_ci.png"), width = 600, height = 450)
y  <- dat$post_score; g <- factor(dat$group)
stripchart(y ~ g, vertical = TRUE, method = "jitter", pch = 16, col = "grey75",
           ylab = "Post-test score", main = "Mean and 95% CI with raw data")
m  <- tapply(y, g, mean, na.rm = TRUE)
se <- tapply(y, g, function(v) sd(v, na.rm = TRUE) / sqrt(sum(!is.na(v))))
n  <- tapply(y, g, function(v) sum(!is.na(v)))
hw <- qt(.975, n - 1) * se
points(1:2, m, pch = 19, cex = 1.6)
arrows(1:2, m - hw, 1:2, m + hw, angle = 90, code = 3, length = .08, lwd = 2)
invisible(dev.off())
cat("Saved: table1.csv, means_ci.png in", dir, "\n")
