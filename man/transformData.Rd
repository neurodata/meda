% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/transformData.R
\name{transformData}
\alias{transformData}
\title{Data transformations}
\usage{
transformData(x, type = c("1e3"), t98 = FALSE, ...)
}
\arguments{
\item{x}{A matrix, data.frame, or data.table with the data of
interest.}

\item{type}{A character list of the transformations desired. See
'Details'}

\item{t98}{A boolean variable to define if the data are truncated to
the inner 98\% before continuing.}

\item{...}{Arguments passed to the rank function.}
}
\value{
A list of the transformed data as data.tables.
}
\description{
Data transformations
}
\details{
If there are negatives present, using any of log transforms
will generate an error. Types of transformations include 'Zscore' -- 
transforms to z-scores, 'rank' -- passes to ranks, '1e3' -- scales 
the data between \eqn{[0,1e3]}, 'log10' -- checks for negatives
and then removes 0's and takes the \eqn{\log_10} of the data, 'log' --
same as 'log10' but for base \eqn{e}.  'slog10' -- checks for negatives
and then removes 0's and takes \eqn{\log_10}, then zscores. 'slog' --
same as 'slog10' but for base \eqn{e}. And 'all' performs all of the
above.
}
\examples{
set.seed(13)
x <- exp(3 + rnorm(100))
y <- exp(5 + rnorm(100))
z <- abs(x*y + rnorm(100, mean = 3, sd = 2))
X <- data.frame(x, y, z)

tx <- transformData(X, type = c('1e3'),
ties.method = 'average')

}
