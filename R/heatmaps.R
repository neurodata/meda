#' Generate 1d heatmaps
#'
#' @param dat the data
#' @param breaks see \code{\link[graphics]{hist}}
#' @param ccol colors for features.
#' @param trunc numeric vector of length 2 to truncate bottom and top
#' respectively, defaults to c(0.01,0.99), set to NA for no truncation.
#' 
#' @return an object of type d1heat
#'
#' @details For each feature column a 1D heatmap is generated and
#' plotted as a geom_tile object.
#'
#' @import ggplot2 
#' @importFrom graphics hist
#' @importFrom gplots colorpanel
#' @importFrom data.table data.table 
#' @importFrom data.table melt
#'
#' @examples
#' dat <- iris[, -5]
#' d <- d1heat(dat, breaks = "Scott", ccol = 1:4, trunc = c(0.01,0.99))
#' plot(d)
#' plot(d, mycol = colorpanel(255, "white", "blue"))
#' @export 
### 1D heatmap
d1heat <- function(dat, breaks = "Scott", 
                   ccol = "black", trunc = c(0.01, 0.99)) {

  dat <- data.table(data.frame(apply(dat, 2, as.numeric)))

  if(!any(is.na(trunc))){
    qs <- apply(dat, 2, quantile, probs = c(trunc[1],trunc[2]))

    x <- dat[, lapply(.SD, 
              function(x){
                qs <- quantile(x, probs=c(trunc[1],trunc[2]))
                x[x < qs[1]] <- NA
                x[x > qs[2]] <- NA
                return(x)
                }
              )]
    dat <- x
  }

  mt <- data.table::melt(dat, measure = 1:ncol(dat))

  H <- hist(mt$value, breaks = breaks, plot = FALSE)
  df <- expand.grid(x = H$mids, y = names(dat))

  bn <- lapply(apply(dat, 2, hist, breaks = H$breaks, plot = FALSE), 
               function(x) { x$counts }) 

  df$Count <- Reduce(c, bn)

  out <- structure(list(dat = df, ccol = ccol, breaks = breaks),
                   class = "d1heat")

}
### END d1heat

#' Generate 1d heatmap plots
#'
#' @param x an object of type d1heat
#' @param ... unused
#' @param mycol a colorpanel or gradient e.g. \code{colorpanel(255,"white","darkgreen")}
#' @param bincount boolean to plot bin count (might be messy if bins are small)
#' 
#' @return a ggplot object 
#'
#' @import ggplot2 
#' @importFrom gplots colorpanel
#' @importFrom data.table data.table 
#' @importFrom data.table melt
#' @importFrom stats na.omit
#'
#' @export 
#' @method plot d1heat
plot.d1heat <- function(x, ..., mycol = NULL, bincount = FALSE){

  d1heat <- x
  df <- d1heat$dat
  ccol <- rev(d1heat$ccol)

  if(is.null(mycol)){
    mycol <- colorpanel(255, "white", "#094620")
  }

  sc <- scale_fill_gradientn(colours = mycol)
  
  p <- ggplot(df, aes(x, y, fill = Count)) + 
         scale_y_discrete(name="", limits = rev(levels(df$y))) +
         geom_tile() + 
         theme(axis.title = element_blank(),
               axis.text.y=element_text(color=ccol)) + 
         sc

  if(bincount){
    df$Count[df$Count == 0] <- NA
    p0 <- p + geom_text(data = na.omit(df), aes(label = Count), fontface="bold")
    p0
    return(p0)
  } else {
    return(p)
  }
}




#' Create representative heatmap with kmeanspp initialization
#'
#' @param x data
#' @param num number of points to show
#' @param ccol character vector of colors for columns/features.
#' 
#' @return a heatmap plot
#'
#' @import viridis
#' @import knor
#' @importFrom stats heatmap
#' @export 
repHeat <- function(x, num = 1000, ccol = NULL){   
  
  x <- as.matrix(x)

  if(num > nrow(x)){
    num <- nrow(x)
  }

  kv <- Kmeans(x, centers = num, iter.max = 0, init = "kmeanspp")
  colnames(kv$centers) <- colnames(x)

  if(!is.null(ccol) && class(ccol) == "character"){
    heatmap(kv$centers, col = viridis(255), ColSideColors = ccol)
  } else {
    heatmap(kv$centers, col = viridis(255))
  }
}

