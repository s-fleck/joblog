#' @keywords internal
#' @import data.table
"_PACKAGE"

# The following block is used by usethis to automatically manage
# roxygen namespace tags. Modify with care!
## usethis namespace: start
## usethis namespace: end
NULL



utils::globalVariables(c(".overdue", ".today", "repeats", "status", "timestamp", "ts_start", "ts_end", "type"))



joblog.globals <- new.env()
assign(".last_job_id", NULL, envir = joblog.globals)
