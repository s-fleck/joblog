
<!-- README.md is generated from README.Rmd. Please edit that file -->

# joblog

An example package to show how custom “virtual event types” can be
leverage to easily create powerfull logging infrastructure
<!-- badges: start --> <!-- badges: end -->

## Installation

``` r
remotes::install_github("s-fleck/joblog")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(joblog)

lf <- paste0(tempfile(), ".jsonl")
on.exit(unlink(lf))
lg <- lgr::get_logger("jobs")$set_propagate(FALSE)
lg$add_appender(lgr::AppenderJson$new(file = lf))

# normal job
lg$list_log(job_start("example", repeats = Sys.Date(), timestamp = Sys.Date() - 1L))
lg$list_log(job_finished())  # mark the last job as finished

# job that repeats tomorrow
lg$list_log(job_start("example", repeats = Sys.Date() + 1L))
lg$list_log(job_finished())

# job that repeats today
lg$list_log(job_start("example-due-today", repeats = Sys.Date(), timestamp = as.POSIXct(Sys.Date() - 1L)))
lg$list_log(job_finished())

# job that is overdue repeats today
lg$list_log(job_start("example-overdue", repeats = Sys.Date()-1L, timestamp = as.POSIXct(Sys.Date() - 2L)))
lg$list_log(job_finished())

# currently running job
lg$list_log(job_start("example-still-running"))
```

joblog provides helpers to extract jobs from a .jsonl log and comes with
a print method that colors jobs whether they are overdue, due today or
still
running

``` r
print(scrape_joblog(lf))
```

<PRE class="fansi fansi-output"><CODE>#&gt;      ts_start     ts_end                  name                         id status jobtype    repeats
#&gt; <span style='color: #BB0000;'>1: 2019-12-13 2019-12-15       example-overdue 0001EZCYEYJCNASP5AED53MWXM      0       1 2019-12-14</span><span>
#&gt; 2: 2019-12-14 2019-12-15               example 0001EZCYEXM8Q75WKQH5B8D9RQ      0       1 2019-12-15
#&gt; </span><span style='color: #BBBB00;'>3: 2019-12-14 2019-12-15     example-due-today 0001EZCYEYT1M62PAZ7T7M2JT0      0       1 2019-12-15</span><span>
#&gt; </span><span style='color: #00BB00;'>4: 2019-12-15       &lt;NA&gt; example-still-running 0001EZCYEYDQ75KVG1Y15MCR67      1       1       &lt;NA&gt;</span><span>
#&gt; 5: 2019-12-15 2019-12-15               example 0001EZCYEXWD95ED0XGK5A3WHV      0       1 2019-12-16
</span></CODE></PRE>

    #cleanup
    unlink(lf)
