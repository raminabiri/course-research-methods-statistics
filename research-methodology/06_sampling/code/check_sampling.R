# Behavioral checks for teaching selection and allocation routines.
args <- grep("^--file=", commandArgs(FALSE), value = TRUE)
raw_path <- sub("^--file=", "", args[1L])
if (!file.exists(raw_path)) raw_path <- gsub("~+~", " ", raw_path, fixed = TRUE)
path <- normalizePath(raw_path, mustWork = TRUE)
source(file.path(dirname(path), "sampling.R"))
expect_error <- function(expr) {
  result <- tryCatch({ force(expr); FALSE }, error = function(e) TRUE)
  if (!result) stop("expected an error")
}
set.seed(44)
a <- srs_ids(600, 60)
stopifnot(length(a) == 60, !anyDuplicated(a), all(a >= 1 & a <= 600))
stopifnot(identical(systematic_ids(120, 12, 6), seq.int(7L, 117L, 10L)))
stopifnot(identical(systematic_ids(103, 10, 2),
                    c(3L,13L,23L,33L,44L,54L,64L,75L,85L,95L)))
# Enumerate every possible random-start region: all individuals have equal
# inclusion frequency even when N/n is not integer.
starts <- ((0:102) + 0.5) / 10
frequency <- tabulate(unlist(lapply(starts, function(u) systematic_ids(103,10,u))),103)
stopifnot(all(frequency == 10L))
for (N in c(1L, 2L, 7L, 103L)) for (n in seq_len(N)) {
  x <- systematic_ids(N, n, 0)
  stopifnot(length(x) == n, !anyDuplicated(x), all(x >= 1 & x <= N))
}
stopifnot(identical(allocate_counts(400, c(5000,3000,2000)), c(200L,120L,80L)))
stopifnot(identical(allocate_counts(400, c(5000,3000,2000), c(10,20,30)),
                    c(118L,141L,141L)))
stopifnot(identical(allocate_counts(10,c(10,10,10)), c(4L,3L,3L)))
for (n in c(1L, 2L, 60L, 61L, 101L)) {
  alloc <- block_rand(n)
  stopifnot(length(alloc) == n, all(alloc %in% c("A","B")))
  ids <- attr(alloc,"block_id"); bs <- attr(alloc,"generated_block_sizes")
  for (b in seq_along(bs)) if (sum(ids == b) == bs[b]) {
    stopifnot(all(table(factor(alloc[ids == b],levels=c("A","B"))) == bs[b]/2))
  }
}
stopifnot(length(block_rand(7, sizes = 4)) == 7)
expect_error(srs_ids(4,5)); expect_error(systematic_ids(10,3,10))
expect_error(allocate_counts(1,c(10,10))); expect_error(allocate_counts(100,c(3,4)))
expect_error(block_rand(20,sizes=c(3,4))); expect_error(pps_one(c(1,NA)))
# Independent recomputation of numerical teaching examples.
stopifnot(abs(weighted.mean(c(10,20,30,40),c(1,1,4,4))-31)<1e-12)
stopifnot(abs((1+19*.04)-1.76)<1e-12, round(600/1.76)==341)
stopifnot(round(600/1.36)==441, ceiling(385*1.5/.8)==722)
stopifnot(abs((.25*.1*.25)^(-1)-160)<1e-12)
# A PPS one-draw experiment checks the actual draw distribution.
set.seed(901)
pps <- tabulate(replicate(12000,pps_one(c(100,200,300))),3)/12000
stopifnot(all(abs(pps - c(1,2,3)/6) < .02))
cat("PASS: selection bounds, exact counts, inclusion frequencies, allocation,\n")
cat("complete-block balance, rejected invalid input, PPS distribution, teaching arithmetic.\n")
