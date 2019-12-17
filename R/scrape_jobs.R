#* @testfile test_job.R

#' Scrape joblog jobs from a Json Log
#'
#' @param file a `.jsonl` file as created by [lgr::AppenderJson]
#'
#' @return a `data.table`
#' @export
#'
scrape_joblog <- function(x){
  UseMethod("scrape_joblog")
}




#' Title
#'
#' @param x
#'
#' @return
#' @export
#'
#' @examples
scrape_joblog.data.table <- function(x){
  res <- x[type == "job"][,
  copy(.SD)[, `:=`(
    ts_start = timestamp[[1]],
    ts_end   = timestamp[[.N]],
    status   = last_known(status),
    msg      = last_known(msg),
    repeats  = {if (exists("repeats")) last_known_timestamp(repeats) else as.POSIXct(NA)}
  )][1]
  ,
    by = "id"
  ]

  res[status == 1, ts_end := as.Date(NA)]
  res[, repeats := as.POSIXct(repeats)]

  for (i_col in rev(seq_along(res))){
    if (all(is.na(res[[i_col]]))){
      set(res, j = i_col, value = NULL)
    }
  }


  res <- res[, !c("timestamp", "level", "caller", "logger", "type")]
  setcolorder(res, c("ts_start", "ts_end", "name", "id", "status", "jobtype", "msg"))
  setkeyv(res, c("ts_start", "ts_end"))
  setattr(res, "class", union("joblog", class(res)))
  res
}




#' Title
#'
#' @param x
#'
#' @return
#' @export
#'
#' @examples
scrape_joblog.character <- function(x){
  scrape_joblog(lgr::read_json_lines(x))
}




#' Title
#'
#' @param x
#'
#' @return
#' @export
#'
#' @examples
scrape_joblog.data.frame <- function(x){
  scrape_joblog(as.data.table(x))
}




set_overdue <- function(x){
  x[, .overdue := repeats < Sys.time() & repeats> max(ts_start) & (!is.na(repeats)), by = "name"]
  x[, .today   := as.Date(as.character(repeats)) == Sys.Date() & repeats > max(ts_start) & (!is.na(repeats)), by = "name" ]
}




#' Title
#'
#' @param x a `joblog`
#' @param ... ignored
#'
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
