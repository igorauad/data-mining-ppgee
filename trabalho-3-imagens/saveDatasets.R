# Library for multicore processing:
#library(doMC)
#registerDoMC()
library(foreach)

# Store the path to the files
data.dir   <- './matlab/data/'
train.file <- paste0(data.dir, 'training.csv')
test.file  <- paste0(data.dir, 'test.csv')

# read in the csv files
d  <- read.csv(train.file, stringsAsFactors=F)

# Parallel conversion of images to a vector of integers.
# Note: columns -> pixels; rows -> images
im <- foreach(imcurrent = d$Image, .combine=rbind) %do% { #%dopar% {
  as.integer(unlist(strsplit(imcurrent, " ")))
}

# Eliminate last column:
d$Image <- NULL


# Get training indices from file 'posTrainIndices.txt'
idxs_train <- read.table('matlab/posTrainIndices.txt')

# Get test indices from file 'posTrainIndices.txt'
idxs_test <- read.table('matlab/posTestIndices.txt')
  

# Sampling - Training and Test sets
#set.seed(0)
#idxs     <- sample(nrow(d), nrow(d)*0.8)
d.train  <- d[idxs_train[,1], ]
d.test   <- d[idxs_test[,1], ]
im.train <- im[idxs_train[,1], ]
im.test  <- im[idxs_test[,1], ]
#rm("d", "im")

# Save
save(d.train, im.train, d.test, im.test, file='data_MATLAB.Rd')




