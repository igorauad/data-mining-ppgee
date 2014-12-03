# Using image patches
# Define the keypoint of interest

# coord       ----> Keypoint of interest
# search_size ----> Region to search 
# mean.patch  ----> Mean patch of the keypoint
# iImage ---------> Test image no.
# shouldPlot -----> Flag indicating whether or not to plot prediction image

predictWithCorrelation <- function(coord, search_size, mean.patch, iImage, shouldPlot) {  
  
  patch_size <- (dim(mean.patch)[1] - 1) / 2
  
  coord_x <- paste(coord, "x", sep="_")
  coord_y <- paste(coord, "y", sep="_")
  
  # Search for the keypoint on the training images
  mean_x <- mean(d.train[, coord_x], na.rm=T)
  mean_y <- mean(d.train[, coord_y], na.rm=T)
  x1     <- as.integer(mean_x)-search_size
  x2     <- as.integer(mean_x)+search_size
  y1     <- as.integer(mean_y)-search_size
  y2     <- as.integer(mean_y)+search_size
  
  # Grid of image coordinates used as patch center for search
  params <- expand.grid(x = x1:x2, y = y1:y2)
  
  # Test image
  im <- matrix(data = im.test[iImage,], nrow=96, ncol=96)
  if (shouldPlot) {
    image(1:96, 1:96, im[96:1,96:1], col=gray((0:255)/255))
  }
  
  
  # iterate over grid points to find the one with the maximum correlation to the average patch:
  r  <- foreach(j = 1:nrow(params), .combine=rbind) %dopar% {
    x     <- params$x[j]
    y     <- params$y[j]
    if (y <= (96 - patch_size)) {
      p     <- im[(x-patch_size):(x+patch_size), (y-patch_size):(y+patch_size)]
      score <- cor(as.vector(p), as.vector(mean.patch))
      score <- ifelse(is.na(score), 0, score)
      data.frame(x, y, score)
    }
  }
  
  best <- r[which.max(r$score), c("x", "y")]
  
  if (shouldPlot) {
    points(96 - best$x, 96 - best$y, col="red")
  }
  
  return(c(best$x, best$y))
}