# Library for multicore processing:
library(doMC)
registerDoMC()

# Store the path to the files
data.dir   <- './matlab/data'
train.file <- paste0(data.dir, 'training.csv')
test.file  <- paste0(data.dir, 'test.csv')

# read in the csv files
d  <- read.csv(train.file, stringsAsFactors=F)

# Parallel conversion of images to a vector of integers.
# Note: columns -> pixels; rows -> images
im <- foreach(im = d$Image, .combine=rbind) %dopar% {
  as.integer(unlist(strsplit(im, " ")))
}

# Eliminate last column:
d$Image <- NULL

# Sampling - Training and Test sets
set.seed(0)
idxs     <- sample(nrow(d), nrow(d)*0.8)
d.train  <- d[idxs, ]
d.test   <- d[-idxs, ]
im.train <- im[idxs,]
im.test  <- im[-idxs,]
rm("d", "im")

# Save
save(d.train, im.train, d.test, im.test, file='data.Rd')




