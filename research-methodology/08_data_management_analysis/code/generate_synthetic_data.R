args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)

if (length(script_arg) != 1L) {
  stop("Run this file with Rscript so its output directory can be located.")
}

script_path <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
module_dir <- dirname(dirname(script_path))
data_dir <- file.path(module_dir, "data")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

set.seed(20261127)
n <- 400L

group <- sample(rep(c("control", "intervention"), each = n / 2L))
baseline_sbp_mmhg <- round(rnorm(n, mean = 142, sd = 14), 1)
age_years <- pmin(85L, pmax(18L, round(rnorm(n, mean = 56, sd = 11))))
site_id <- sample(sprintf("S%02d", 1:4), n, replace = TRUE)
sex <- sample(c("F", "M"), n, replace = TRUE)

week12_sbp_mmhg <- round(
  baseline_sbp_mmhg - 2 -
    3.5 * (group == "intervention") +
    rnorm(n, mean = 0, sd = 9),
  1
)

missing_probability <- plogis(
  -3.2 + 0.65 * ((baseline_sbp_mmhg - 142) / 14)
)
week12_sbp_mmhg[rbinom(n, size = 1, prob = missing_probability) == 1] <- NA_real_

adverse_event <- rbinom(
  n,
  size = 1,
  prob = plogis(-2 + 0.25 * (group == "intervention"))
)

synthetic_data <- data.frame(
  participant_id = sprintf("P%04d", seq_len(n)),
  site_id = site_id,
  group = group,
  age_years = age_years,
  sex = sex,
  baseline_sbp_mmhg = baseline_sbp_mmhg,
  week12_sbp_mmhg = week12_sbp_mmhg,
  adverse_event = adverse_event,
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(synthetic_data) == 400L,
  !anyDuplicated(synthetic_data$participant_id),
  all(table(synthetic_data$group) == 200L),
  all(synthetic_data$age_years >= 18L & synthetic_data$age_years <= 85L)
)

output_path <- file.path(data_dir, "synthetic_followup.csv")
write.csv(synthetic_data, output_path, row.names = FALSE, na = "")
message(
  "Wrote ", nrow(synthetic_data), " synthetic rows to ", output_path,
  "; missing week-12 outcomes: ", sum(is.na(synthetic_data$week12_sbp_mmhg))
)
