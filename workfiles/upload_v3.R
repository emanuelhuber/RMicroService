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


# PostgreSQL offers a nice syntax sugar for this:
#   
#   CREATE TABLE mytable (id BIGSERIAL PRIMARY KEY, value INT);
# 
# which is equivalent to
# 
# CREATE SEQUENCE mytable_id_seq; -- table_column_'seq'
# CREATE TABLE mytable (id BIGINT NOT NULL PRIMARY KEY DEFAULT NEXTVAL('mytable_id_seq'), value INT); -- it's not null and has a default value automatically

# BIGSERIAL / bigint
# serial ( 1 to 2147483647) <-> integer 


CREATE TABLE gpr.gpr_trace
(
  id_trace integer NOT NULL DEFAULT nextval('gpr.gpr_trace_id_trace_seq'::regclass),
  geometry geometry(Point,4326),
  altitude numeric(5,2),
  traces smallint[],
  id_gpr_line integer NOT NULL,
  traces_count integer NOT NULL,
  CONSTRAINT gpr_trace_pkey PRIMARY KEY (id_trace),
  CONSTRAINT gpr_trace_id_gpr_line_678a36a92952f8bb_fk_gpr_line_id_gpr_line FOREIGN KEY (id_gpr_line)
  REFERENCES gpr.gpr_line (id_gpr_line) MATCH SIMPLE
  ON UPDATE NO ACTION
  ON DELETE NO ACTION
  DEFERRABLE INITIALLY DEFERRED
)