# Educational examples; not a clinical allocation service.
# Run: Rscript --vanilla 06_sampling/code/sampling.R
# No package installation, network access, or patient data is required.

check_count <- function(x, label, minimum = 1L) {
  if (length(x) != 1L || !is.numeric(x) || is.na(x) || !is.finite(x) ||
      x < minimum || x != floor(x)) stop(label, " must be an integer >= ", minimum)
}

srs_ids <- function(N, n) {
  check_count(N, "N"); check_count(n, "n")
  if (n > N) stop("n must not exceed N")
  sample.int(N, n, replace = FALSE)
}

systematic_ids <- function(N, n, start = NULL) {
  check_count(N, "N"); check_count(n, "n")
  if (n > N) stop("n must not exceed N")
  interval <- N / n
  if (is.null(start)) start <- runif(1L, 0, interval)
  if (length(start) != 1L || !is.numeric(start) || is.na(start) ||
      !is.finite(start) || start < 0 || start >= interval) {
    stop("start must be in [0, N/n)")
  }
  # Positions use a zero-based continuous start, then become one-based IDs.
  as.integer(floor(start + (seq_len(n) - 1L) * interval) + 1L)
}

allocate_counts <- function(n, sizes, spread = NULL) {
  check_count(n, "n")
  if (!is.numeric(sizes) || !length(sizes) || anyNA(sizes) ||
      any(!is.finite(sizes)) || any(sizes <= 0) || any(sizes != floor(sizes))) {
    stop("sizes must contain positive finite integer counts")
  }
  if (n > sum(sizes)) stop("sample exceeds population")
  if (is.null(spread)) spread <- rep(1, length(sizes))
  if (!is.numeric(spread) || length(spread) != length(sizes) ||
      anyNA(spread) || any(!is.finite(spread)) || any(spread <= 0)) {
    stop("spread must contain positive finite values")
  }
  raw <- n * sizes * spread / sum(sizes * spread)
  if (any(raw > sizes)) stop("allocation exceeds stratum capacity; redesign required")
  out <- floor(raw)
  left <- as.integer(n - sum(out))
  if (left > 0L) {
    # Stable tie break: earlier stratum in the input wins.
    rank <- order(-(raw - out), seq_along(raw))
    chosen <- rank[seq_len(left)]
    out[chosen] <- out[chosen] + 1L
  }
  names(out) <- names(sizes)
  if (any(out > sizes)) stop("rounded allocation exceeds capacity")
  if (any(out == 0L)) stop("zero stratum allocation; set a minimum and redesign")
  as_counts <- as.integer(out)
  names(as_counts) <- names(sizes)
  as_counts
}

pps_one <- function(sizes) {
  if (!is.numeric(sizes) || !length(sizes) || anyNA(sizes) ||
      any(!is.finite(sizes)) || any(sizes <= 0)) stop("invalid cluster sizes")
  # One draw only. This is NOT a general multi-draw inclusion-probability routine.
  sample.int(length(sizes), 1L, prob = sizes)
}

block_rand <- function(n_total, sizes = c(4L, 6L), arms = c("A", "B")) {
  check_count(n_total, "n_total")
  if (!is.character(arms) || length(arms) < 2L || anyNA(arms) ||
      any(!nzchar(arms)) || anyDuplicated(arms)) stop("invalid arm labels")
  if (!is.numeric(sizes) || !length(sizes) || anyNA(sizes) ||
      any(!is.finite(sizes)) || any(sizes <= 0) ||
      any(sizes != floor(sizes)) || any(sizes %% length(arms) != 0)) {
    stop("block sizes must be positive multiples of the number of arms")
  }
  out <- character(); block_id <- integer(); full_sizes <- integer()
  b_id <- 0L
  while (length(out) < n_total) {
    b <- sizes[sample.int(length(sizes), 1L)]
    b_id <- b_id + 1L
    block <- rep(arms, each = b / length(arms))
    block <- block[sample.int(length(block))]
    out <- c(out, block)
    block_id <- c(block_id, rep(b_id, b))
    full_sizes <- c(full_sizes, b)
  }
  out <- out[seq_len(n_total)]
  attr(out, "block_id") <- block_id[seq_len(n_total)]
  attr(out, "generated_block_sizes") <- full_sizes
  attr(out, "last_block_complete") <- n_total == sum(full_sizes)
  # Truncation need not preserve final arm balance; metadata makes that visible.
  out
}

run_demo <- function(root = ".") {
  set.seed(123)
  pop <- read.csv(file.path(root, "data", "survey_data.csv"))
  required <- c("id", "region", "school", "pre_score")
  if (!all(required %in% names(pop)) || anyNA(pop[required]) ||
      anyDuplicated(pop$id)) stop("invalid teaching population")
  N <- nrow(pop); n <- 80L
  srs <- pop[srs_ids(N, n), ]
  systematic <- pop[systematic_ids(N, n), ]
  sizes <- table(pop$region)
  nh <- allocate_counts(n, sizes)
  stratified <- do.call(rbind, lapply(names(sizes), function(h) {
    sub <- pop[pop$region == h, ]
    sub[srs_ids(nrow(sub), nh[h]), ]
  }))
  sh <- tapply(pop$pre_score, pop$region, sd)
  cat("Teaching population mean:", round(mean(pop$pre_score), 2), "\n")
  print(rbind(population = sizes, proportional = nh,
              neyman = allocate_counts(n, sizes, sh)))
  clusters <- unique(pop$school)
  cl_sizes <- table(pop$school)
  if (length(clusters) < 16L || length(unique(as.integer(cl_sizes))) != 1L ||
      any(cl_sizes < 5L)) stop("demo requires >=16 equal-size clusters, size >=5")
  picked <- clusters[sample.int(length(clusters), 8L)]
  cluster <- pop[pop$school %in% picked, ]
  picked2 <- clusters[sample.int(length(clusters), 16L)]
  two_stage <- do.call(rbind, lapply(picked2, function(s) {
    sub <- pop[pop$school == s, ]
    sub[srs_ids(nrow(sub), 5L), ]
  }))
  estimates <- sapply(list(SRS = srs, Systematic = systematic,
                           Stratified = stratified, Cluster = cluster,
                           TwoStage = two_stage), function(d) {
    c(n = nrow(d), mean = mean(d$pre_score))
  })
  print(round(estimates, 3))
  # Compare equal-size samples; the cluster mean is appropriate here because
  # cluster sizes are equal and every member of each selected cluster is measured.
  cluster_n <- nrow(cluster)
  reps <- 2000L
  means_srs <- replicate(reps, mean(pop$pre_score[srs_ids(N, cluster_n)]))
  means_cluster <- replicate(reps, {
    chosen <- clusters[sample.int(length(clusters), 8L)]
    mean(pop$pre_score[pop$school %in% chosen])
  })
  cat("Monte Carlo DEFF (this finite teaching population):",
      round(var(means_cluster) / var(means_srs), 3), "\n")
  cat("One PPS draw, cluster index:", pps_one(c(100, 200, 300)), "\n")
  cat("Noninteger systematic example:", systematic_ids(103, 10, 2), "\n")
  alloc <- block_rand(61L)
  cat("Allocation demo, n=61 (exact equal counts impossible):\n")
  print(table(alloc))
  cat("Last block complete:", attr(alloc, "last_block_complete"), "\n")
  invisible(list(estimates = estimates, allocation = alloc))
}

if (sys.nframe() == 0L) {
  arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (!length(arg)) stop("run with Rscript")
  raw_path <- sub("^--file=", "", arg[1L])
  # R encodes spaces in --file as ~+~ on some Rscript builds.
  if (!file.exists(raw_path)) raw_path <- gsub("~+~", " ", raw_path, fixed = TRUE)
  script_path <- normalizePath(raw_path, mustWork = TRUE)
  root <- dirname(dirname(dirname(script_path)))
  run_demo(root)
}
