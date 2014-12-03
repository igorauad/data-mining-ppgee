# Library for multicore processing:
library(doMC)
registerDoMC()

load('matlab/data/data.Rd')

# visualize image
# Reverse because R's image function expects the origin to be in the lower left corner
im <- matrix(data=rev(im.train[1,]), nrow=96, ncol=96)
image(1:96, 1:96, im, col=gray((0:255)/255))

# Plot keypoints from training set:
points(96 - d.train$nose_tip_x[1], 96 - d.train$nose_tip_y[1], col="red")
points(96 - d.train$left_eye_center_x[1], 96 - d.train$left_eye_center_y[1], col="blue")
points(96 - d.train$right_eye_center_x[1], 96 - d.train$right_eye_center_y[1], col="green")

for(i in 1:nrow(d.train)) {
  points(96-d.train$nose_tip_x[i], 96-d.train$nose_tip_y[i], col="red")
}

# Inspect outliers
idx <- which.max(d.train$nose_tip_x)
im  <- matrix(data=rev(im.train[idx,]), nrow=96, ncol=96)
image(1:96, 1:96, im, col=gray((0:255)/255))
points(96-d.train$nose_tip_x[idx], 96-d.train$nose_tip_y[idx], col="red")

# Predict using means:
# (Same prediction for every image)
p           <- matrix(data=colMeans(d.train, na.rm=T), 
                      nrow=nrow(d.test),
                      ncol=ncol(d.train),
                      byrow=T)
colnames(p) <- names(d.train)
# ImageId + features
predictions <- data.frame(ImageId = 1:nrow(d.test), p)


#
# Correlation between average patch and test images
#
# See "Matching by correlation" in 
# http://www.math.hcmuns.edu.vn/~tatuana/Xu%20Ly%20Anh/Ebook(Seminar)/Digital%20Image%20Processing%20CHAPTER%2012%20%5BGONZALEZ%20R%20C%20WOOD%5D.pdf
# Obs: some methods use FFT to compute correlation

source('meanPatch.R')
source('predictWithCorrelation.R')

coord      <- "mouth_center_top_lip" 
coord_x <- paste(coord, "x", sep="_")
coord_y <- paste(coord, "y", sep="_")

patch_size <- 15 # e.g. 10 means we will have a square of 21x21 pixels (10+1+10). 
search_size <- 10 # e.g. would give a 5x5 (2+1+2) 

mean.patch <- meanPatch(coord, patch_size, TRUE)  

# Vizualize prediciton
iImg = 2
estimated_p <- predictWithCorrelation(coord, search_size, mean.patch, iImg, TRUE) 
points(96 - d.test$mouth_center_top_lip_x[iImg], 96 - d.test$mouth_center_top_lip_y[iImg], col="green")
real_p <- c(d.test$mouth_center_top_lip_x[iImg], d.test$mouth_center_top_lip_y[iImg])
err <- estimated_p - real_p
err

# Iterate over all test images and compute prediction
# NOTE: for many the chosen feature may be missing
# nrow(d.test)
targetIdx <- 1:30
est_p <- foreach(iImg = targetIdx, .combine=rbind) %dopar% {  
  p <- predictWithCorrelation(coord, search_size, mean.patch, iImg, FALSE)    
  p
}
colnames(est_p) <- c(coord_x, coord_y)
est_p

rmse <- sqrt(mean((d.test[targetIdx,c(coord_x, coord_y)] - est_p)^2, na.rm=T))
rmse

#
# Search the best patch_size and search_size (based on RM)
#

coord      <- "mouth_center_bottom_lip" 
coord_x <- paste(coord, "x", sep="_")
coord_y <- paste(coord, "y", sep="_")

patch_sizes <- 4:25 # e.g. 10 means we will have a square of 21x21 pixels (10+1+10). 
search_size <- 3:30 # e.g. would give a 5x5 (2+1+2) 

targetIdx <- 1:200

rmses <- foreach(patchSize = patch_sizes, .combine=rbind) %dopar% {
  
  mean.patch <- meanPatch(coord, patchSize, FALSE) 
  est_p <- foreach(iImg = targetIdx, .combine=rbind) %do% {  
    p <- predictWithCorrelation(coord, search_size, mean.patch, iImg, FALSE)    
    p
  }

  rmse <- sqrt(mean((d.test[targetIdx,c(coord_x, coord_y)] - est_p)^2, na.rm=T))
  print(rmse)
  rmse  
}





