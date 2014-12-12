# Library for multicore processing:
#library(doMC)
#registerDoMC()

library(foreach)
load('matlab/data/data.Rd')

# Concatenate d.train and d.test and order the resulting dataframe by row names.
# This is done so that d.train is identical to training.mat, used by MATLAB.
d.train <- rbind(d.train, d.test);
d.train <- d.train[ order( as.integer(row.names(d.train)) ), ];

# Do the same for im.train and im.test
im.train <- rbind(im.train, im.test);
im.train <- im.train[ order( as.integer(substring(row.names(im.train), 8)) ), ];

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
# 

source('meanPatch.R')
source('predictWithCorrelation.R')

coord      <- "mouth_center_top_lip"
coord_x <- paste(coord, "x", sep="_")
coord_y <- paste(coord, "y", sep="_")

patch_size <- 15 # e.g. 10 means we will have a square of 21x21 pixels (10+1+10).
search_size <- 10 # e.g. 2 would give a 5x5 (2+1+2)

mean.patch <- meanPatch(coord, patch_size, TRUE)

# Visualize prediction
iImg = 2;
estimated_p <- predictWithCorrelation(coord, search_size, mean.patch, iImg, TRUE)
points(96 - d.test$mouth_center_top_lip_x[iImg], 96 - d.test$mouth_center_top_lip_y[iImg], col="green", lwd=2, cex=1.5)
real_p <- c(d.test$mouth_center_top_lip_x[iImg], d.test$mouth_center_top_lip_y[iImg])
err <- estimated_p - real_p
err


# read matlab/data/testIdx.csv to get the indices of the test images
testIndices <- read.csv(file="./matlab/data/testIdx.csv", header=TRUE, sep=",", colClasses=c("NULL", NA))


# Iterate over the train images without NAN-entries (indices from 1 to 470 in targetIdx)
# all test images and compute prediction
# NOTE: for many the chosen feature may be missing
# nrow(d.test)

targetIdx <- testIndices[1:50,1] #1:470
features <- cbind("mouth_center_top_lip", "mouth_center_bottom_lip", "mouth_left_corner", "mouth_right_corner")

i_RMSEs <- 0

RMSEs <- foreach(coord = features, .combine=rbind) %do% { #%dopar% {
  
  print( paste("i_RMSEs =", i_RMSEs) );
  
  j_est <- 0
  mean.patch <- meanPatch(coord, patch_size, TRUE)
  est_p <- foreach(iImg = targetIdx, .combine=rbind) %do% { #%dopar% {  
    p <- predictWithCorrelation(coord, search_size, mean.patch, iImg, FALSE)
    if(j_est%%100 == 0) {
      print( paste("j_est =", j_est) );
    }
    
    j_est <- j_est + 1
    
    p
  }
  
  i_RMSEs  <- i_RMSEs + 1
  
  coord_x <- paste(coord, "x", sep="_")
  coord_y <- paste(coord, "y", sep="_")
  
  colnames(est_p) <- c(coord_x, coord_y)
  #est_p
  
  rmse <- sqrt(mean((d.train[targetIdx,c(coord_x, coord_y)] - est_p)^2, na.rm=T))
  rmse
}

RMSE_global <- mean(RMSEs)
print(RMSE_global)


# Show comparison of real vs detected bounding boxes for test figure #50
#iImg = 170; #testIndices[10,1]
iImg = testIndices[50,1]
im  <- matrix(data=rev(im.train[iImg,]), nrow=96, ncol=96)
#im  <- matrix(data=im.train[iImg,], nrow=96, ncol=96)
image(1:96, 1:96, im, col=gray((0:255)/255))

real_leftCorner <- cbind(96-d.train$mouth_left_corner_x[iImg], 96-d.train$mouth_left_corner_y[iImg]);
real_rightCorner <- cbind(96-d.train$mouth_right_corner_x[iImg], 96-d.train$mouth_right_corner_y[iImg]);
real_topLip <- cbind(96-d.train$mouth_center_top_lip_x[iImg], 96-d.train$mouth_center_top_lip_y[iImg]);
real_bottomLip <- cbind(96-d.train$mouth_center_bottom_lip_x[iImg], 96-d.train$mouth_center_bottom_lip_y[iImg]);

rect( real_leftCorner[1], real_bottomLip[2], real_rightCorner[1], real_topLip[2], lwd=2, border="red" );


# draw detected bounding box
features <- cbind("mouth_center_top_lip", "mouth_center_bottom_lip", "mouth_left_corner", "mouth_right_corner")
points <- foreach(coord = features, .combine=rbind) %do% { #%dopar% {
  
  mean.patch <- meanPatch(coord, patch_size, FALSE)
  p <- predictWithCorrelation(coord, search_size, mean.patch, iImg, FALSE)
  p
}

detected_topLip = 96 - points[1,];
detected_bottomLip = 96 - points[2,];
detected_leftCorner = 96 - points[3,];
detected_rightCorner = 96 - points[4,];

# points(detected_topLip[1], detected_topLip[2], col="green", lwd=2, cex=1.5)
# points(detected_bottomLip[1], detected_bottomLip[2], col="green", lwd=2, cex=1.5)
# points(detected_leftCorner[1], detected_leftCorner[2], col="green", lwd=2, cex=1.5)
# points(detected_rightCorner[1], detected_rightCorner[2], col="green", lwd=2, cex=1.5)

rect( detected_leftCorner[1], detected_bottomLip[2], detected_rightCorner[1], detected_topLip[2], lwd=2, border="green" );

png(filename="figs/correlation_comparison.png")
plot(fit)
dev.off()


# coord = "mouth_left_corner"
# mean.patch <- meanPatch(coord, patch_size, TRUE)
# detected_leftCorner <- predictWithCorrelation(coord, search_size, mean.patch, iImg, FALSE)
# 
# coord = "mouth_right_corner"
# mean.patch <- meanPatch(coord, patch_size, TRUE)
# detected_rightCorner <- predictWithCorrelation(coord, search_size, mean.patch, iImg, FALSE)
# 
# coord = "mouth_center_top_lip"
# mean.patch <- meanPatch(coord, patch_size, TRUE)
# detected_topLip <- predictWithCorrelation(coord, search_size, mean.patch, iImg, FALSE)



# #
# # Search the best patch_size and search_size (based on RMSE)
# #
# 
# coord      <- "mouth_center_bottom_lip" 
# coord_x <- paste(coord, "x", sep="_")
# coord_y <- paste(coord, "y", sep="_")
# 
# patch_sizes <- 4:25 # e.g. 10 means we will have a square of 21x21 pixels (10+1+10). 
# search_size <- 3:30 # e.g. would give a 5x5 (2+1+2) 
# 
# targetIdx <- 1:200
# 
# rmses <- foreach(patchSize = patch_sizes, .combine=rbind) %do% { #%dopar% {
#   
#   mean.patch <- meanPatch(coord, patchSize, FALSE) 
#   est_p <- foreach(iImg = targetIdx, .combine=rbind) %do% {  
#     p <- predictWithCorrelation(coord, search_size, mean.patch, iImg, FALSE)    
#     p
#   }
# 
#   rmse <- sqrt(mean((d.test[targetIdx,c(coord_x, coord_y)] - est_p)^2, na.rm=T))
#   print(rmse)
#   rmse  
# }






