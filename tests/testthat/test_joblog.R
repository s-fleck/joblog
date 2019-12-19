context("joblog")


test_that("joblog works as expected", {

  lg <- lgr::get_logger("test")$
    set_propagate(FALSE)$
    set_appenders(list(buffer = lgr::AppenderBuffer$new()))

  lg$list_log(job_start("job1"))
  lg$list_log(job_finished("job1"))
  lg$list_log(job_start("job1"))
  lg$list_log(job_finished("job1"))
  lg$list_log(job_start("job1"))
  lg$list_log(job_failed("job1"))

  lg$list_log(job_start("job2"))
  lg$list_log(job_finished("job2"))
  lg$list_log(job_start("job2"))
  lg$list_log(job_start("job2"))
  lg$list_log(job_failed("job2"))

  day <- 60*60*24

  lg$list_log(job_start("job2", timestamp = Sys.time() - day))
  lg$list_log(job_finished("job2"))
  lg$list_log(job_start("job2", timestamp = Sys.time() - day))
  lg$list_log(job_start("job2", timestamp = Sys.time() - day))
  lg$list_log(job_failed("job2"))

  summary(scrape_joblog(lg$appenders$buffer$dt))





})
