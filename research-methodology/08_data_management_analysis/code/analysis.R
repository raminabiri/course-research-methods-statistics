args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)

if (length(script_arg) != 1L) {
  stop("Run this file with Rscript so the accompanying data file can be located.")
}

script_path <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
module_dir <- dirname(dirname(script_path))
data_path <- file.path(module_dir, "data", "synthetic_followup.csv")

if (!file.exists(data_path)) {
  stop(
    "Synthetic data file not found: ", data_path,
    ". Run code/generate_synthetic_data.R first."
  )
}

dat <- read.csv(
  data_path,
  na.strings = c("", "NA"),
  stringsAsFactors = FALSE
)

expected_columns <- c(
  "participant_id", "site_id", "group", "age_years", "sex",
  "baseline_sbp_mmhg", "week12_sbp_mmhg", "adverse_event"
)

if (!identical(names(dat), expected_columns)) {
  stop("Unexpected columns or order in the synthetic data file.")
}

if (nrow(dat) != 400L || anyDuplicated(dat$participant_id)) {
  stop("The data must contain 400 rows and unique participant identifiers.")
}

if (!all(dat$group %in% c("control", "intervention"))) {
  stop("Unexpected group code found.")
}

if (any(dat$age_years < 18 | dat$age_years > 85, na.rm = TRUE)) {
  stop("Age outside the documented simulation range.")
}

if (any(dat$baseline_sbp_mmhg < 80 | dat$baseline_sbp_mmhg > 220, na.rm = TRUE)) {
  stop("Baseline pressure outside the programmed data-quality review range.")
}

dat$group <- factor(dat$group, levels = c("control", "intervention"))
dat$site_id <- factor(dat$site_id)

cat("Synthetic participants:", nrow(dat), "\n")
cat("Duplicate participant identifiers:", anyDuplicated(dat$participant_id), "\n")
cat("Missing week-12 outcomes:", sum(is.na(dat$week12_sbp_mmhg)), "\n\n")

cat("Missing week-12 outcomes by group:\n")
print(with(dat, table(group, outcome_missing = is.na(week12_sbp_mmhg))))

cat("\nMean baseline pressure by observed follow-up status:\n")
print(tapply(dat$baseline_sbp_mmhg, is.na(dat$week12_sbp_mmhg), mean))

cat("\nDescriptive model of follow-up missingness (not a test of MCAR/MAR/MNAR):\n")
missingness_model <- glm(
  I(is.na(week12_sbp_mmhg)) ~ group + age_years +
    baseline_sbp_mmhg + site_id,
  data = dat,
  family = binomial()
)
print(coef(summary(missingness_model)))

complete <- dat[complete.cases(dat$week12_sbp_mmhg), ]
cat("\nComplete-case Welch t-test (demonstration only):\n")
print(t.test(week12_sbp_mmhg ~ group, data = complete))

cat("\nComplete-case adjusted linear model (demonstration only):\n")
fit <- lm(
  week12_sbp_mmhg ~ group + baseline_sbp_mmhg + age_years + site_id,
  data = complete
)
print(summary(fit))
cat("\n95% confidence intervals for model coefficients:\n")
print(confint(fit))

cat(
  "\nInterpret the complete-case results only under justified assumptions; ",
  "this script does not perform multiple imputation or MNAR sensitivity analysis.\n",
  sep = ""
)
