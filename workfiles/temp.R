
if(!require("devtools")) install.packages("devtools")
devtools::install_local("/media/data/huber/Documents/WORKNEW/RGPR_dev/RGPR")
# devtools::install_github("emanuelhuber/RGPR")
library(RGPR)


x

apply(x, 1, function(x) (min(x) - max(x))== 0)

ncol(x)


#------ TEST reading GPR files from connection ---------#
con <- file("data/GSSI/FILE____050.DZT", "rb")
x1 <- readGPR(con)
x2 <- readGPR(fPath = "data/GSSI/FILE____050.DZT")
close(con)
identical(x1, x2)


con <- file("data/DT1/XLINE00.DT1", "rb")
con2 <- file("data/DT1/XLINE00.HD", "rt")
x1 <- readGPR(con, dsn2 = con2)
x2 <- readGPR("data/DT1/XLINE00.DT1")
close(con)
close(con2)
identical(x1, x2)

xyz <- read.table("data/DT1/XLINE00.txt", header = TRUE)

coord(x2) <- xyz

dim(xyz)
dim(x2)


spPts <- as.SpatialPoints(x2)
plot(spPts)
x2data <- as.data.frame(t(as.matrix(x2)))
spdf <- SpatialPointsDataFrame(spPts, x2data)
plot(spdf)

length(spPts)

nrow(x2data)





con <- file("data/RD3/DAT_0052.rd3", "rb")
con2 <- file("data/RD3/DAT_0052.rad", "rt")
x1 <- readGPR(con, dsn2 = con2)
x2 <- readGPR("data/RD3/DAT_0052.rd3")
close(con)
close(con2)
identical(x1, x2)
plot(x1)

con <- file("data/impulseRadar/CO example_0002_0.iprb", "rb")
con2 <- file("data/impulseRadar/CO example_0002_0.iprh", "rt")
x1 <- readGPR(con, dsn2 = con2)
x2 <- readGPR("data/impulseRadar/CO example_0002_0.iprb")
close(con)
close(con2)
identical(x1, x2)
plot(x2)
plot(x1)


x <- readGPR(dsn, dsn2 = fob2)



library(plumber)
r <- plumb("./upload_v2.R")
r$run(port=8000)




headHD <- scan( fName$hd, what = character(), strip.white = TRUE,
                quiet = TRUE, fill = TRUE, blank.lines.skip = TRUE, 
                flush = TRUE, sep = "\n")


con <- file("data/GSSI/FILE____050_DZT", "rb")
x <- RGPR::readGPR(con, format = "DZT")
close(con)
plot(x[,1])

x[,1:10]
x@fid



plot3D::image2D(as.matrix(x))
dev.off()
str(x)



setMethod("readGPR", "ANY", function(fPath, desc = "", ...){
  con <- fPath
  if( inherits(con, "connection") ){
    summaryCon <- summary.connection(con)
    ext <- .fExt(summaryCon$description)
  }else{
    stop("dsf")
  }
})
