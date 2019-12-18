#' Scrape joblog jobs from
#'
#' Extracts a [joblog] `data.table` from a `data.frame` or a `.jsonl` logfile.
#' The resulting `data.table` whill contain all the fields logged with
#' [job_start()]. If a [job_finished()] or [job_failed()] was registered for
#' the same job id, they will override the fields from the job start (see examples)
#'
#' @param x a `data.frame` or the path to a `.jsonl` file as created by
#'   [lgr::AppenderJson]
#'
#' @return a `data.table`
#' @export
#' @examples
#' logfile <- tempfile()
#'
#' lg <- lgr::get_logger("test")$
#'   set_propagate(FALSE)$
#'   add_appender(lgr::AppenderJson$new(file = logfile), "json")
#'
#' lg$list_log(job_start("update-database"))
#' lg$list_log(job_finished())
#'
#' # run the job again the next day
#' lg$list_log(job_start("update-database"))
#' lg$list_log(job_failed("something went wrong this time"))
#'
#' # The log of a json appender can be accessed conveniently via its $data field
#' lg$appenders$json$data
#'
#' # scrape_joblog summarieses alle log-rows that relate to a specifc job
#' scrape_joblog(lg$appenders$json$data)
#' scrape_joblog(logfile)
#'
#' unlink(logfile)
#' lg$config(NULL)  # reset logger
scrape_joblog <- function(x){
  UseMethod("scrape_joblog")
}




#' @export
#' @rdname scrape_joblog
scrape_joblog.data.table <- function(x){
  res <- x[type == "job"]
  msg <- NULL

  if (!"repeats" %in% names(res))
    res[, repeats := as.POSIXct(NA)]

  res <- res[,
    copy(.SD)[, `:=`(
      ts_start = timestamp[[1]],
      ts_end   = timestamp[[.N]],
      status   = last_known(status),
      msg      = last_known(msg),
      repeats  = last_known_timestamp(repeats))
    ][1]
    ,
    by = "id"
  ]

  res[status == 1, ts_end := as.Date(NA)]

  for (i_col in rev(seq_along(res))){
    if (names(res)[[i_col]] == "repeats")
      next

    if (all(is.na(res[[i_col]]))){
      set(res, j = i_col, value = NULL)
    }
  }

  res <- res[, !c("timestamp", "level", "caller", "logger", "type")]
  set_joblog(res)
  res
}




#' @export
#' @rdname scrape_joblog
scrape_joblog.character <- function(x){
  scrape_joblog(lgr::read_json_lines(x))
}




#' @export
#' @rdname scrape_joblog
scrape_joblog.data.frame <- function(x){
  scrape_joblog(as.data.table(x))
}
