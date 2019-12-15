#' Title
#'
#' @param name `character` scalar. Name of the job
#' @param status `integer` scalar. Status of the job; `0` = succesfully completed, `1` = started, `2` = failed.
#' @param jobtype `integer` scalar. `1` = scheduled (for example via cron), 2 = triggered, 3 = manually started
#' @param ... added to the resulting `list`
#' @param id a global unique id (such as UUID or ULID) for the job
#' @param repeats `timestamp` when the job is expected to repeat
#' @param path `character` scalar. path to the script that contains the job
#'
#' @section Side Effects:
#'   `job_start()` assigns the variable `.last_job_id` to the environment
#'   `joblog.globals`, which is used by `job_finished()` and `job_failed()`. If
#'   you want to run several jobs concurrently, you need to pass `id` in
#'   manually.
#'
#' @return a `list()` for `Logger$list_log()`
#' @export
#'
#' @examples
#' lg <- lgr::get_logger("test")
#' lg$list_log(job_start("example-job"))
#' lg$list_log(job_finished())
job_start <- function(
  name,
  status =  1L,
  jobtype = 1L,
  ...,
  id = ulid::generate(),
  repeats = NULL,
  path = NULL
){
  assert(is_scalar_character(id))
  assert(is_scalar_character(name))
  assert(is_scalar_integerish(status))
  assert(is_scalar_integerish(jobtype))
  assert(is.null(repeats) || is_POSIXct(repeats) || is_Date(repeats))
  assert(is.null(path) || is_scalar_character(path))

  assign(".last_job_id", id, envir = joblog.globals)

  compact(list(
    level = 400L,
    msg = "job started",
    type = "job",
    id = id,
    name = name,
    status = status,
    jobtype = jobtype,
    repeats = repeats,
    path = path,
    ...,
    caller = "log_job_start"
  ))
}




#' @export
#' @rdname job_start
job_finished <- function(
  id = get(".last_job_id", envir = joblog.globals),
  ...
){
  list(level = 400L, msg = "job finished", type = "job",  id = id, status = 0L, ...)
}




#' @export
#' @rdname job_start
job_failed <- function(
  id = get(".last_job_id", envir = joblog.globals),
  ...
){
  list(level = 200L, msg = "job finished", type = "job", id = id, status = 2L, ...)
}
