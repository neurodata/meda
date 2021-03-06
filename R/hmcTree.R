#' Generate a binary hierarchical mclust tree
#'
#' @param dat a data matrix
#' @param maxDepth maximum tree depth, defaults to 5
#' @param modelNames passed to mclust
#'
#' @return binary hierarchical mclust classification output
#' @details BIC is run for k = {1,2}, if k = 2 then each node is
#' propagated down the tree.  If k = 1, then that node is frozen. 
#' @import data.tree
#' @importFrom abind abind
#' @importFrom mclust mclustBIC Mclust
#' @importFrom data.table melt
#' @importFrom stats cov
#' @importFrom stats cor
#' @importFrom stats cov2cor
#'
#' @export 
#' @examples
#' dat <- iris[, -5]
#' truth <- iris[, 5]
#' L <- hmcTree(dat, modelNames = c("VVV", "EEE"))
### Binary Hierarchical Mclust Classifications 
hmcTree <- function(dat, maxDepth = 5, modelNames){ ## Helper function
  
  if(dim(dat)[2] == 1 && !any(c("E", "V", "X", "XII", "XXI", "XXX") %in% modelNames)){
    stop("Check your modelNames and the dimensions of your data!")
  }

  splitNode = function(node){
    if(!is.null(dim(node$data)) && 
       dim(node$data)[1] > 5 && 
       node$continue == TRUE && 
       isLeaf(node)){
       b <- mclustBIC(node$data, G = 1:2, modelNames = modelNames)
       node$bic <- b
       mc <- Mclust(node$data, x = b)
       cont <- all(table(mc$classification) > 10)
       node$G <- mc$G
       if(mc$G == 2 && cont){
         node$model <- mc
         dat1 <- node$data[mc$classification == 1,]
         dat2 <- node$data[mc$classification == 2,]

         if(dim(dat1)[1] >= dim(dat2)[1]){
           big <- "1"
           little <- "2"
           #
           node$AddChild(paste0(node$name, big), 
             data = dat1, dataid = rownames(dat1), 
             continue = TRUE,
             num = dim(dat1)[1]/tot,
             mean = mc$parameters$mean[,1], 
             cov = mc$parameters$variance$sigma[,,1],
             cor = cov2cor(mc$parameters$variance$sigma[,,1]))
           #
           node$AddChild(paste0(node$name, little), 
             data = dat2, dataid = rownames(dat2), continue = TRUE,
             num = dim(dat2)[1]/tot,
             mean = mc$parameters$mean[,2], 
             cov = mc$parameters$variance$sigma[,,2],
             cor = cov2cor(mc$parameters$variance$sigma[,,2]))
         } else {
           big <- "2"
           little <- "1"
           #
           node$AddChild(paste0(node$name, little), 
             data = dat2, dataid = rownames(dat2), continue = TRUE,
             num = dim(dat2)[1]/tot,
             mean = mc$parameters$mean[,2], 
             cov = mc$parameters$variance$sigma[,,2],
             cor = cov2cor(mc$parameters$variance$sigma[,,2]))
           #
           node$AddChild(paste0(node$name, big), 
             data = dat1, dataid = rownames(dat1), 
             continue = TRUE,
             num = dim(dat1)[1]/tot,
             mean = mc$parameters$mean[,1], 
             cov = mc$parameters$variance$sigma[,,1],
             cor = cov2cor(mc$parameters$variance$sigma[,,1]))
         }
       } else {
         node$continue = FALSE
       }
    }
  } ## END splitNode

 splitNode1 = function(node){
    if(!is.null(dim(node$data)) && 
       dim(node$data)[1] > 5 && 
       node$continue == TRUE && 
       isLeaf(node)){
       b <- mclustBIC(node$data, G = 1:2, modelNames = modelNames)
       node$bic <- b
       mc <- Mclust(node$data, x = b)
       node$G <- mc$G
       node$mc <- mc
       cont <- all(table(mc$classification) > 10)
       if(mc$G == 2 && cont){
         node$model <- mc
         dat1 <- data.frame(node$data[mc$classification == 1,])
         rownames(dat1) <- rownames(node$data)[mc$classification == 1]
         dat2 <- data.frame(node$data[mc$classification == 2,])
         rownames(dat2) <- rownames(node$data)[mc$classification == 2]

         if(dim(dat1)[1] >= dim(dat2)[1]){
           big <- "1"
           little <- "2"
         } else {
           big <- "2"
           little <- "1"
         }
         node$AddChild(paste0(node$name, big), 
                       data = dat1, 
                       dataid = rownames(dat1), 
                       continue = TRUE,
                       num = length(dat1)/tot,
                       sigmasq = ifelse(mc$modelName == "V" ,
                                        mc$parameters$variance$sigmasq[big],
                                        mc$parameters$variance$sigmasq),
                       #cor = cov2cor(mc$parameters$variance$sigma[1])
                       mean = mc$parameters$mean[1]
                       )
         node$AddChild(paste0(node$name, little), 
                       data = dat2, 
                       dataid = rownames(dat2), 
                       continue = TRUE,
                       num = length(dat2)/tot,
                       #cov = mc$parameters$variance$sigma[2],
                       sigmasq = ifelse(mc$modelName == "V",
                                        mc$parameters$variance$sigmasq[little],
                                        mc$parameters$variance$sigmasq),
                       #cor = cov2cor(mc$parameters$variance$sigma[2])
                       mean = mc$parameters$mean[2]
                       )
       } else {
         node$continue = FALSE
       }
    }
  } ## END splitNode1

  #dat <- as.data.frame(dat)
  tot <- dim(dat)[1]
  dataid <- if(!is.null(rownames(dat))){ 
              rownames(dat) 
              } else { 
                1:dim(dat)[1] 
              }

  node <- Node$new("", data = dat, 
                   dataid = rownames(dat), 
                   continue = TRUE, model = NULL, 
                   mean = apply(dat, 2, mean),
                   num = tot/tot)

  if(dim(dat)[2] == 1){
    while(node$height < maxDepth && 
         any(Reduce(c,node$Get('continue', format = list, filterFun = isLeaf)))){
      node$Do(splitNode1, filterFun = isLeaf)
      }
  } else {
    while(node$height < maxDepth && 
         any(Reduce(c,node$Get('continue', format = list, filterFun = isLeaf)))){
      node$Do(splitNode, filterFun = isLeaf)
      }
  }

  ## 
  n <- node$Get("dataid")[node$Get("isLeaf")]
  n <- lapply(n, as.numeric)
  m <- node$Get('model')

  #g <- node$Get("mean", "level", format = list)
  g <- node$Get("mean", "level", format = list, filterFun = isLeaf)
  means <- data.frame(g)
  colnames(means) <- gsub("X", "C", colnames(means))

  #h <- node$Get("cov", "level", format = list)[-1]
  h <- node$Get("cov", "level", format = list, filterFun = isLeaf)
  mn <- melt(n)
  rownames(mn) <- mn$value
  mn$L1 <- as.factor(mn$L1)
  mn$col <- as.numeric(mn$L1)

  k <- 
    if(dim(dat)[2] > 1){
      node$Get("cor", "level", format = list, filterFun = isLeaf)
    } else {
      node$Get("sigmasq", "level", format = list, filterFun = isLeaf)
    }

  outLabels <- mn[order(mn$value), ]

  node$ClusterFraction <- node$Get("num", filterFun = isLeaf)
  node$means <- means


  if(dim(dat)[2] >1){
    node$sigma <- structure(list(dat =abind(h, along = 3)),
                            class=c("clusterCov", "array"))
    node$cor <- abind(k, along = 3)
  } else {
    names(k) <- names(means)
    node$sigma <- k
  }

  node$labels <- outLabels

  return(node)
}




#' Generate binary hierarchical mclust tree
#'
#' @param dat data 
#' @param truth true labels if any
#' @param maxDim maximum dimensions to plot
#' @param maxDepth maximum tree depth
#' @param modelNames model names for mclust see \code{\link[mclust]{mclustModelNames}}
#' @param ccol colors for feature labels
#'
#' @return binary hierarchical mclust classification output
#' @details BIC is run for k = {1,2}, if k = 2 then each node is
#' propagated down the tree.  If k = 1, then that node is frozen. 
#' If a singleton exists, the level takes a step back. 
#'
#' @export 
#' @examples
#'
#' set.seed(54321)
#' dat <- rnorm(1e3, mean = rep(c(0,1,10,11), each=250), sd = sqrt(0.1))
#' truth <- rep(1:4, each = 250)
#' modelNames = c("E", "V"); maxDepth = 3
#' d0 <- hmc(dat, truth, modelName = modelNames, maxDepth = maxDepth)
#' plot(d0, pch = truth)
#' plotDend(d0)
#'
#' dat <- iris[,-5] 
#' truth <- NULL #iris[,5]
#' maxDim = 6; modelNames = c("VVV"); maxDepth = 6
#' d1 <- hmc(dat, truth = truth, modelNames = c("VVV"), maxDim = 6)
#' plot(d1)
#' plotDend(d1)
### Binary Hierarchical Mclust Classifications 
hmc <- function(dat, truth = NULL, maxDim = Inf, maxDepth = 5,
                  modelNames = NULL, ccol = "black") {

  if(!is.null(dim(dat))){
    dat <- as.data.frame(dat)
    d <- dim(dat)[2]
    n <- dim(dat)[1]
    dmax <- ifelse(d > maxDim, maxDim, d)
  } else {
    dat <- as.data.frame(dat)
    d <- dim(dat)[2]
    n <- dim(dat)[1]
    ccol <- "black"
    dmax <- 1
  }

  size <- max(min(1.5/log10(n), 1.25), 0.05)
  shape <- if(!is.null(truth)){ 
    as.numeric(factor(truth))
  } else {
    20
  }

  L <- hmcTree(dat, maxDepth, modelNames = modelNames)
  
  out <- structure(list(dat = L, dmax = dmax, shape = shape, size = size, ccol = ccol, truth = truth), class = "hmc")
  
  return(out)
}

#' Find K closest points to each cluster mean
#'
#' @param x an object of type hmc
#' @param ... plotDend Boolean for dendrogram plot and maxd for max
#' plotting dimension
#'
#' @importFrom graphics pairs
#' @method plot hmc
#' @export 
### Binary Hierarchical Mclust Classifications 
closestK <- function(x, ...){

}

#' Generate binary hierarchical mclust tree plot
#'
#' @param x an object of type hmc
#' @param ... plotDend Boolean for dendrogram plot and maxd for max
#' plotting dimension
#'
#' @importFrom graphics pairs
#' @method plot hmc
#' @export 
### Binary Hierarchical Mclust Classifications 
plot.hmc <- function(x, ...){

  dl <- x
  L <- dl$dat
  shape <- 
    if(!is.null(dl$truth)){
      as.numeric(dl$truth)
    } else {
      if(is.null(list(...)$pch)){
         20 } else {
         list(...)$pch 
        }
    }
  size  <- ifelse(is.null(list(...)$cex), dl$size, list(...)$cex)
  dmax  <- ifelse(is.null(list(...)$maxd), min(8,dl$dmax), list(...)$maxd)

  print("Fraction of points in each cluster:")
  print(table(L$labels$col)/length(L$labels$col))
  
  if(dim(dl$dat$data)[2] > 1){
    pairs(dl$dat$data[, 1:dmax], 
          pch = shape, 
          col =  viridis(max(L$labels$col))[L$labels$col], 
          cex = size, 
          main = "Color is classification; if present, shape is truth"
          )
  } else {
    X <- dl$dat$data
    X$classification <- L$labels$col
    
    #plot(log1p(tmp$dat),tmp$col + 0.25 * shape,
    plot(X$dat,X$classification + 0.25 * shape,
         pch = shape,
         col = viridis(max(X$classification))[X$classification],
         cex = 1,
         #ylim = c(1,length(unique(tmp$col))),
         main = "Color is classification; if present, shape is truth"
         )
  }
}


#' plot a dendrogram from an hmc object
#'
#' @param dl an hmc object
#'
#' @return a dendrogram plot
#' @import data.tree
#' @import dendextend
#' @importFrom stats as.dendrogram
#'
#' @export 
plotDend <- function(dl){
  if(class(dl) != "hmc"){
    stop("must be of class hmc")
  } else {
    tree <- dl$dat 
    dend <- as.dendrogram(Sort(tree, "name"))
    num <- tree$Get("num")
    cond <- as.numeric(tree$Get("G", by = "level"))
    dend <- dend %>%
                 dendextend::set("branches_lwd", 10*as.numeric(num)) %>% 
                 dendextend::set("branches_lty", c(1)) %>%
                 dendextend::set("nodes_pch", c(15, 17)[cond]) %>%
                 dendextend::set("nodes_cex", 2.5) %>%
                 dendextend::set("nodes_col", c("red", "green")[cond])

    plot(dend, center = TRUE)
    round(tree$Get("num", filterFun=isLeaf), 4)
  }
}
