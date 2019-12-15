context("job")


test_that("logging jobs works as expected",{
  lf <- paste0(tempfile(), ".jsonl")
  on.exit(unlink(lf))
  lg <- lgr::get_logger("jobs")$set_propagate(FALSE)
  lg$add_appender(lgr::AppenderJson$new(file = lf))

  # normal job
  lg$list_log(job_start("example-job", repeats = Sys.Date(), timestamp = Sys.Date() - 1L))
  lg$list_log(job_finished())

  # job that repeats tomorrow
  lg$list_log(job_start("example-job", repeats = Sys.Date() + 1L))
  lg$list_log(job_finished())

  # job that repeats today
  lg$list_log(job_start("example-job-today", repeats = Sys.Date(), timestamp = as.POSIXct(Sys.Date() - 1L)))
  lg$list_log(job_finished())

  # job that is overdue repeats today
  lg$list_log(job_start("example-job-overdue", repeats = Sys.Date() - 1L, timestamp = as.POSIXct(Sys.Date() - 2L)))
  lg$list_log(job_finished())

  x <- scrape_joblog(lf)
  set_overdue(x)

  expect_identical(x$.overdue, x$name %in% c("example-job-overdue", "example-job-today"))
  expect_identical(x$.today, x$name == "example-job-today")

  # run new instance of job that should be run today
  lg$list_log(job_start("example-job-today", repeats = Sys.Date()))
  x <- scrape_joblog(lf)
  set_overdue(x)
  expect_identical(x$.today, rep(FALSE, 5))

  # run new instance of overdue job so that it is no longer overdue
  lg$list_log(job_start("example-job-overdue", repeats = Sys.Date()))
  x <- scrape_joblog(lf)
  set_overdue(x)
  expect_identical(x$.overd, rep(FALSE, 6))
})





test_that("still running job doesn't cause scrape_joblog to fail",{
  lf <- paste0(tempfile(), ".jsonl")
  on.exit(unlink(lf))
  lg <- lgr::get_logger("jobs")$set_propagate(FALSE)
  lg$add_appender(lgr::AppenderJson$new(file = lf))

  lg$list_log(job_start("example-job", repeats = Sys.Date(), timestamp = Sys.Date() - 1L))
  lg$list_log(job_finished())
  lg$list_log(job_start("running-job", repeats = Sys.Date()))
  testthat::expect_output(print(scrape_joblog(lf)))
})
