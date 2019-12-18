context("scrape_jobs")


test_that("scrape_jobs works as expected", {

  logfile <- tempfile()
  on.exit(unlink(logfile))

  lg <- lgr::get_logger("test")$
    set_propagate(FALSE)$
    add_appender(lgr::AppenderJson$new(file = logfile), "json")

  lg$list_log(job_start("update-database"))
  lg$list_log(job_finished())

  # run the job again the next day
  lg$list_log(job_start("update-database"))
  lg$list_log(job_failed("something went wrong this time"))

  # The log of a json appender can be accessed conveniently via its $data field
  lg$appenders$json$data

  # scrape_joblog summarieses alle log-rows that relate to a specifc job
  scrape_joblog(lg$appenders$json$data)
  expect_output(print(lg$appenders$json$data))

  expect_identical(nrow(scrape_joblog(logfile)), 2L)
})
