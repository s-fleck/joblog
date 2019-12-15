
<!-- README.md is generated from README.Rmd. Please edit that file -->

# joblog

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

joblog proposes a format for logging the start and completion of jobs
via [lgr](https://github.com/s-fleck/lgr) (such as cron jobs or
automatically triggered etl operations). joblog assumes you are logging
to [jsonlines](http://jsonlines.org/) files, but other formats/logging
destinations could be supported in theory.

## Installation

``` r
remotes::install_github("s-fleck/joblog")
```

## Example

``` r
library(joblog)

# setup logging
lf <- paste0(tempfile(), ".jsonl")
lg <- lgr::get_logger("jobs")$set_propagate(FALSE)  # prevent logging to the console
lg$add_appender(lgr::AppenderJson$new(file = lf), name = "json")

lg$list_log(job_start("example"))  # log the job start
# ... do stuff ...
lg$list_log(job_finished())  # log the job end

# run the same job again
lg$list_log(job_start("example"))
lg$list_log(job_failed("something went wrong")) 


# log other stuff unrelated to the job
lg$info("today is tuesday")
lg$warn("only true every 7 days")
```

Using the setup above we have logged to a json lines file that looks
like this:

``` r
lg$appenders$json$show()
#> {"level":400,"timestamp":"2019-12-15 22:34:54","logger":"jobs","caller":"log_job_start","msg":"job started","type":"job","id":"0001EZD9QYRGPQ7MVZHY0TQCZG","name":"example","status":1,"jobtype":1}
#> {"level":400,"timestamp":"2019-12-15 22:34:54","logger":"jobs","caller":"do.call","msg":"job finished successfully","type":"job","id":"0001EZD9QYRGPQ7MVZHY0TQCZG","status":0}
#> {"level":400,"timestamp":"2019-12-15 22:34:54","logger":"jobs","caller":"log_job_start","msg":"job started","type":"job","id":"0001EZD9QY7JHDYYZ4DDNNN444","name":"example","status":1,"jobtype":1}
#> {"level":200,"timestamp":"2019-12-15 22:34:54","logger":"jobs","caller":"do.call","msg":"job failed: something went wrong","type":"job","id":"0001EZD9QY7JHDYYZ4DDNNN444","status":2}
#> {"level":400,"timestamp":"2019-12-15 22:34:54","logger":"jobs","caller":"eval","msg":"today is tuesday"}
#> {"level":300,"timestamp":"2019-12-15 22:34:54","logger":"jobs","caller":"eval","msg":"only true every 7 days"}
```

joblog provides `scrape_joblog()` for extracting the jobs from logfile
and consolidating all info about the job from the relevant log entries,
based on the auto-generated job-id.

``` r
scrape_joblog(lf)
#>               ts_start              ts_end    name                         id status jobtype                              msg repeats
#> 1: 2019-12-15 22:34:54 2019-12-15 22:34:54 example 0001EZD9QYRGPQ7MVZHY0TQCZG      0       1        job finished successfully    <NA>
#> 2: 2019-12-15 22:34:54 2019-12-15 22:34:54 example 0001EZD9QY7JHDYYZ4DDNNN444      2       1 job failed: something went wrong    <NA>
```

    #cleanup
    unlink(lf)
