library(RGPR)
library(Rook)
library(rpostgis)

##----- how to run
# library(plumber)
# r <- plumb("./upload.R")
# r$run(port=8000)


#Sys.setlocale('LC_ALL','C')

#* @png
#* @post /upload
function(req){
  formContents <- suppressWarnings(Rook::Multipart$parse(req))
  
  formContents
  
  # read GPR data
  ext <- RGPR::.fExt(formContents$bin$filename)
  dsn <- file(formContents$bin$tempfile , "rb")
  
  if(!is.null(formContents$hd)){
    cat("yep!!!")
    dsn2 <- file(formContents$hd$tempfile , "rb")
  }
  x <- RGPR::readGPR(dsn, dsn2 = dsn2, format = ext)
  plot(x)
  
  if(!is.null(formContents$coords)){
    cat("yep!!!")
    xyz <- read.table( formContents$coords$tempfile, header = TRUE )
    str(xyz)
    coord(x) <- xyz

    
    spPts <- as.SpatialPoints(x)

    xdata <- as.data.frame(t(as.matrix(x)))
    spdf <- SpatialPointsDataFrame(spPts, xdata)
    
    # store GPR data in database
    # create a connection
    # save the password that we can "hide" it as best as we can by collapsing it
    pw <- "12345"
  
    # loads the PostgreSQL driver
    drv <- dbDriver("PostgreSQL")
    # creates a connection to the postgres database
    # note that "con" will be used later in each connection to the database
    con <- RPostgreSQL::dbConnect(drv,
                                  dbname = "gvx",
                                  host = "ec2-52-60-120-132.ca-central-1.compute.amazonaws.com",
                                  port = 5432,
                                  user = "common", password = pw)
    rm(pw) # removes the password
    
    # rpostgis::dbDrop(con,
    #                  name = c("public", "meuse_data"),
    #                  type = "table")
    
    rpostgis::pgInsert(con, name = c("public", "GPRspatial"), 
                       data.obj = spdf, 
                       overwrite = TRUE)
  
    pp <- rpostgis::pgGetGeom(con, c("public", "GPRspatial"))
  
    plot(pp, col = "red")
  }
  
  
}


