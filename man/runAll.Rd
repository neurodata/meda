% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/runAll.R
\name{runAll}
\alias{runAll}
\title{MEDA run all plotting functions on a dataset with default options.}
\usage{
runAll(dat, ccol = "black", trans = NULL, ...)
}
\arguments{
\item{dat}{the data}

\item{ccol}{colors for columns/features.}

\item{trans}{transform data before running meda.
see \code{\link{transformData}}}

\item{...}{passed to transformData}
}
\value{
an object of type d1heat
}
\description{
MEDA run all plotting functions on a dataset with default options.
}
\details{
For each feature column a 1D heatmap is generated and
plotted as a geom_tile object.
}
\examples{
dat <- iris[, -5]
ccol <- c("darkgreen", "darkgreen", "purple", "purple")
L <- runAll(dat, ccol = ccol, trans = "log")
plot(L[[1]])
plot(L[[2]], bincount=TRUE)
plot(L[[3]])
plot(L[[4]])
plot(L[[5]])
plot(L[[6]])
plotDend(L[[7]])
plot(L[[7]])
stackM(L[[7]])
clusterMeans(L[[7]])

}
