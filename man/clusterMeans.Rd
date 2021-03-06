% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/clusterAnalysis.R
\name{clusterMeans}
\alias{clusterMeans}
\title{Generate cluster parameter plots}
\usage{
clusterMeans(L, ccol = "black")
}
\arguments{
\item{L}{of class hmc}

\item{ccol}{colors for features}
}
\value{
heatmap and line plot of cluster means
}
\description{
Generate cluster parameter plots
}
\examples{
dat <- iris[, -5]
truth <- iris[, 5]
L <- hmc(dat, truth = truth, modelNames = c("VVV"))
clusterMeans(L, ccol = 1:4)
}
