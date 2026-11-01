# =============================================================
# فصل ۶ — روش‌های نمونه‌گیری احتمالی، اثر طرح و تخصیص تصادفی (R پایه)
# اجرا از ریشه پروژه: Rscript 06_sampling/code/sampling.R
# جامعه فرضی = ۴۰۰ نفر فایل survey_data.csv
# =============================================================
set.seed(123)
pop <- read.csv("data/survey_data.csv")
N <- nrow(pop); n <- 80
cat("True population mean of pre_score:", round(mean(pop$pre_score), 2), "\n\n")

## ---- ۱) تصادفی ساده (SRS) بدون جایگذاری
srs <- pop[sample(N, n), ]

## ---- ۲) سیستماتیک: فاصله k = N/n، شروع تصادفی
k     <- N / n
start <- sample(1:k, 1)
sys   <- pop[seq(start, N, by = k), ]

## ---- ۳) طبقه‌ای با تخصیص متناسب
Nh    <- table(pop$region)
nh    <- round(n * Nh / N)
strat <- do.call(rbind, lapply(names(Nh), function(h) {
  sub <- pop[pop$region == h, ]; sub[sample(nrow(sub), nh[h]), ] }))
print(rbind(N_h = Nh, n_h_proportional = nh))

# تخصیص بهینه نیمن: n_h ∝ N_h × S_h
Sh <- tapply(pop$pre_score, pop$region, sd)
cat("Neyman allocation:", round(n * Nh * Sh / sum(Nh * Sh)), "\n\n")

## ---- ۴) خوشه‌ای یک‌مرحله‌ای: ۸ مدرسه از ۴۰ و همه افراد آن‌ها
cl_sel  <- sample(unique(pop$school), 8)
cluster <- pop[pop$school %in% cl_sel, ]

## ---- ۵) دومرحله‌ای: ۱۶ مدرسه، سپس ۵ نفر از هر مدرسه
s1 <- sample(unique(pop$school), 16)
two_stage <- do.call(rbind, lapply(s1, function(s) {
  sub <- pop[pop$school == s, ]; sub[sample(nrow(sub), 5), ] }))

## ---- ۶) احتمال متناسب با اندازه (PPS) سیستماتیک — مثال با اندازه‌های فرضی خوشه
size <- c(120, 80, 300, 50, 150, 220, 90, 60, 180, 250)        # جمعیت ۱۰ روستا
cum  <- cumsum(size); interval <- sum(size) / 3                    # انتخاب ۳ روستا
picks <- runif(1, 0, interval) + interval * (0:2)
cat("PPS selected villages:", sapply(picks, function(p) which(cum >= p)[1]), "\n\n")

## ---- ۷) مقایسه برآوردها
est <- sapply(list(SRS = srs, Systematic = sys, Stratified = strat,
                   Cluster = cluster, TwoStage = two_stage),
              function(s) c(n = nrow(s), mean = mean(s$pre_score)))
print(round(est, 2))

## ---- ۸) شبیه‌سازی ۲۰۰۰ تکرار: خطای معیار SRS در برابر خوشه‌ای ← اثر طرح
reps <- 2000
m_srs <- replicate(reps, mean(pop$pre_score[sample(N, n)]))
m_cl  <- replicate(reps, mean(pop$pre_score[pop$school %in% sample(1:40, 8)]))
deff_emp <- var(m_cl) / var(m_srs)

# ICC بین مدارس از ANOVA و اثر طرح نظری: DEFF = 1 + (m - 1) * ICC
a   <- anova(lm(pre_score ~ factor(school), data = pop))
m   <- 10
icc <- (a$`Mean Sq`[1] - a$`Mean Sq`[2]) / (a$`Mean Sq`[1] + (m - 1) * a$`Mean Sq`[2])
cat("SE SRS =", round(sd(m_srs), 3), "| SE cluster =", round(sd(m_cl), 3),
    "| empirical DEFF =", round(deff_emp, 2), "\n")
cat("ICC =", round(icc, 3), "| theoretical DEFF = 1 + (10-1)*ICC =", round(1 + (m - 1) * icc, 2), "\n\n")

## ---- ۹) تخصیص تصادفی بلوکی (برای کارآزمایی): بلوک‌های ۴ و ۶ به صورت تصادفی
block_rand <- function(n_total, sizes = c(4, 6), arms = c("A", "B")) {
  out <- character(0)
  while (length(out) < n_total) {
    b <- sample(sizes, 1)
    out <- c(out, sample(rep(arms, b / length(arms))))
  }
  out[1:n_total]
}
alloc <- block_rand(40)
print(table(alloc)); cat(alloc, "\n")

# تخصیص طبقه‌ای-بلوکی: یک فهرست جدا برای هر طبقه (مثلاً جنس)
strat_alloc <- lapply(c(male = 20, female = 20), block_rand)
str(strat_alloc)

## ---- ۱۰) اختیاری: برآورد با وزن طرح در بسته survey
if (requireNamespace("survey", quietly = TRUE)) {
  library(survey)
  cluster$fpc <- 40
  des <- svydesign(ids = ~school, fpc = ~fpc, data = cluster)
  print(svymean(~pre_score, des, deff = TRUE))
}
