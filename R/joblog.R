#' Joblog Objects
#'
#' `joblogs` are `data.tables` with custom [print()] and [summary()] methods.
#' `as.joblog()` just adds a `joblog` attribute to an appropriately formatted
#' `data.table`. If you want to extract jobs from a normal log(file/`data.frame`)
#' use [scrape_joblog()] instead.
#'
#' @param x,object any \R object
#' @param ... ignored
#' @rdname joblog
#' @examples
#' lg <- lgr::get_logger("test")$
#'   set_propagate(FALSE)$
#'   add_appender(lgr::AppenderBuffer$new(), "buffer")
#'
#' lg$list_log(job_start("update-database"))
#' lg$list_log(job_finished())
#' lg$list_log(job_start("send-report"))
#' lg$list_log(job_failed("something went wrong this time"))
#' res <- scrape_joblog(lg$appenders$buffer$data)
#'
#' print(res)
#' summary(res)
#'
#' lg$config(NULL)  # reset logger
as_joblog <- function(x){
  x <- data.table::copy(x)
  set_joblog(x)
  x
}




#' @param x a `joblog`
#' @param ... ignored
#' @noRd
set_joblog <- function(x){
  setcolorder(x, c("ts_start", "ts_end", "name", "id", "status", "jobtype", "msg"))
  setkeyv(x, c("ts_start", "ts_end"))
  setattr(x, "class", union("joblog", class(x)))
}





#' @rdname joblog
#' @return `summary.joblog()` returns a `joblog_summary` `data.table`
#' @export
print.joblog <- function(x, ...){
  dd <- as.data.table(x)
  set_overdue(dd)

  res <- utils::capture.output(print(dd[, !c(".overdue", ".today")]))
  sel <- c(FALSE, dd$.overdue & (!dd$.today))
  res[sel] <- vapply(res[sel], crayon::red, character(1))
  sel <- c(FALSE, dd$.today)
  res[sel] <- vapply(res[sel], crayon::yellow, character(1))
  sel <- c(FALSE, dd$status == 1L)
  res[sel] <- vapply(res[sel], crayon::green, character(1))

  cat(res, sep = "\n")
  invisible(x)
}




#' @rdname joblog
#' @return `summary.joblog()` returns a `joblog_summary` `data.table`
#' @export
summary.joblog <- function(object, ...){
  dd <- as.data.table(object)

  runtime <- date <- status_col <- NULL

  dd[, runtime := ts_start - ts_end]
  dd[, date    := as.Date(ts_start)]
  dd[, status_col := as.character(status)]

  res <- dcast(dd, date ~ name, value.var = "status_col", fun.aggregate = function(.) paste(., collapse = "-"))
  data.table::setattr(res, "class", union("joblog_summary", class(res)))
  res
}




#' @rdname joblog
#' @export
print.joblog_summary <- function(x, ...){

  pd <- as.matrix(x)
  pd <- rbind(t(matrix(colnames(pd))), pd)

  for (cid in seq_len(ncol(pd))){
    pd[, cid] <- pad_left(pd[ ,cid])
  }

  for (rid in seq_len(nrow(pd))){
    cat(pd[rid, ], "\n")
  }

  invisible(x)
}




# utils -------------------------------------------------------------------

set_overdue <- function(x){
  x[, .overdue := repeats < Sys.time() & repeats> max(ts_start) & (!is.na(repeats)), by = "name"]
  x[, .today   := as.Date(as.character(repeats)) == Sys.Date() & repeats > max(ts_start) & (!is.na(repeats)), by = "name" ]
}




last_known_timestamp <- function(x){
  res <- last_known(x)
  if (is.character(x) && !any(grepl("-", x)))
    as.POSIXct(as.numeric(x), origin = "1970-01-01")
  else
    as.POSIXct(x)
}




last_known <- function(x){
  x <- x[!is.na(x)]

  if (length(x)){
    x[length(x)]
  } else {
    NA
  }
}
