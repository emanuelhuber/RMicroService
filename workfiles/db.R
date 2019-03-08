

# install.packages("RPostgreSQL")
require("RPostgreSQL")

library(rpostgis)

setwd("/media/huber/Seagate1TB/UNIBAS/PROJECTS/RGPR/CODE/RMicroService")

# data

devtools::install_github("emanuelhuber/RGPR")

library(RGPR)
gpr <- readGPR("data/DT1/XLINE00.DT1")
xyz <- readTopo("data/DT1/XLINE00.txt", sep = "\t")
coord(gpr) <- xyz[[1]]

plot(gpr)
plot(coord(gpr)[,1:2], asp = 1, type = "l")

crs(gpr) <- CRS("+init=epsg:21781")

gpr <- trProject(gpr, "+init=epsg:4326")

plot(coord(gpr)[,1:2], asp = 1, type = "l")



# create a connection
# save the password that we can "hide" it as best as we can by collapsing it
pw <- {
  "12345"
}

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

rpostgis::pgPostGIS(con)

rpostgis::pgListGeom(con, geog = TRUE)
rpostgis::pgListRast(con)

rpostgis::dbTableInfo(con, "GPRsf")
rpostgis::dbTableInfo(con, c("gpr", "gpr_line"), allinfo = TRUE)

#--- list database
dbGetQuery(con, "SELECT datname FROM pg_database
           WHERE datistemplate = false")

dbListTables(con)

#--- This lists tables in the current database
dbGetQuery(con, "SELECT table_schema,table_name
FROM information_schema.tables
ORDER BY table_schema,table_name")

dbGetQuery(con, "SELECT table_schema='public',table_name
FROM information_schema.tables
ORDER BY table_schema,table_name")


#------------------------------------------------------------------------------#
#                           own approach                                       #
#------------------------------------------------------------------------------#

# DEF Table on github wiki


# DELETE ALL TABLES
deleteAllTables <- function(con){
  # # delete a sequence
  # dbExecute(con, "DROP SEQUENCE gpr.gpr_trace_id_trace_seq")
  # dbExecute(con, "DROP SEQUENCE gpr.gpr_line_id_line_seq")
  if(DBI::dbExistsTable(con, c("gpr", "gpr_trace"))){
    out <- rpostgis::dbDrop(con,
                   name = c("gpr", "gpr_trace"),
                   type = "table")
    if(isTRUE(out)){
      message("Table 'gpr.gpr_trace' deleted!")
    }else{
      warning("Problem by deleting table 'gpr.gpr_trace'")
    }
  }else{
    message("Table'gpr.gpr_trace' does not exist!")
  }
  if(DBI::dbExistsTable(con, c("gpr", "gpr_line"))){
    out <- rpostgis::dbDrop(con,
                    name = c("gpr", "gpr_line"),
                    type = "table")
    if(isTRUE(out)){
      message("Table 'gpr.gpr_line' deleted!")
    }else{
      warning("Problem by deleting table 'gpr.gpr_line'")
    }
  }else{
    message("Table'gpr.gpr_line' does not exist!")
  }
}

#--- DELETE ALL ROWS OF TABLES
cleanAllTables <- function(con){
  ## "RESTART IDENTITY" to reset associated sequence generator (serial)
  DBI::dbExecute(con, "TRUNCATE gpr.gpr_trace, gpr.gpr_line RESTART IDENTITY")
  # dbExecute(con, "TRUNCATE gpr.gpr_trace_float, gpr.gpr_trace, gpr.gpr_line")
}

createTable_gpr_line <- function(con){
  if(!DBI::dbExistsTable(con, c("gpr", "gpr_line"))){
    x <- SQL(paste(
      "CREATE TABLE gpr.gpr_line(",
      "id_line serial,",
      'name character varying(50) COLLATE pg_catalog."default",',
      'description character varying(200) COLLATE pg_catalog."default",',
      "date timestamp without time zone,",
      "PRIMARY KEY (id_line)",
      ")", sep = "\n"))
     
    DBI::dbExecute(con, x)
  }else{
    message("Table already exists")
  }
}

createTable_gpr_trace <- function(con){
  if(!DBI::dbExistsTable(con, c("gpr", "gpr_trace"))){
    x <- SQL(paste(
      "CREATE TABLE gpr.gpr_trace(",
      "id_trace serial,",
      "coordinates geometry(Point,4326),",
      "elevation numeric(5,2),",
      "traces smallint[],",
      "id_line integer NOT NULL,",
      "traces_count integer NOT NULL,",
      # "CONSTRAINT gpr_trace_pkey PRIMARY KEY (id_trace),",
      "PRIMARY KEY (id_trace),",
      "FOREIGN KEY (id_line)",
      "REFERENCES gpr.gpr_line (id_line) MATCH SIMPLE",
      "ON UPDATE NO ACTION",
      "ON DELETE NO ACTION",
      "DEFERRABLE INITIALLY DEFERRED",
      ")", sep = "\n"))
    
    DBI::dbExecute(con, x)
  }else{
    message("Table already exists")
  }
}



createTable_gpr_line(con)  
createTable_gpr_trace(con)

# cleanAllTables(con)
# deleteAllTables(con)




rpostgis::dbTableInfo(con, "gpr_trace")  
  

#---------------- ADD GPR LINE

getTimeStamp <- function(x){
  as.character(as.POSIXlt(x@time[1], 
                          origin = as.Date("1970-01-01")))
}

insert_gpr_line <- function(con, gpr){
  input <- paste0("'", paste(name(gpr), 
                             description(gpr), 
                             getTimeStamp(gpr), sep = "', '"),
                  "'")
  
  query <- DBI::SQL(paste("INSERT INTO gpr.gpr_line(",
                     "name,",
                     "description,",
                     "date",
                     ")",
                     "VALUES (",
                     input,
                     ");", sep = " "))
  
  DBI::dbExecute(con, query)
}

get_gpr_line <- function(con){
  dbGetQuery(con, "SELECT * FROM  gpr.gpr_line")
}

insert_gpr_line(con, gpr)
get_gpr_line(con)

#---------------- ADD GPR TRACES


# try rpostgis::pgInsert  with array int...


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
## COPY APPROACH
createPoint <- function(x){
  paste0("ST_GeomFromText('POINT(", 
               paste(x[1:2], collapse = " "), 
               ")', 4326)")
}

createTrace <- function(x){
  paste0("'{",
         paste(x, collapse = ", "),
         "}'")
}

xy <- apply(gpr@coord, 1, createPoint)
elv <- gpr@coord[,3]
trc <- apply(gpr_int, 2, createTrace)
id_line <- DBI::dbGetQuery(con, 
                      "SELECT currval('gpr.gpr_line_id_line_seq')")
tr_count <- nrow(gpr)

df <- data.frame(coordinates = xy,
                 elevation = elv,
                 traces = trc,
                 id_line = rep(as.integer(id_line), ncol(gpr)),
                 traces_count = rep(tr_count, ncol(gpr)))

RPostgreSQL::dbSendQuery(con, "COPY gpr.gpr_trace(coordinates, elevation, traces, id_line, traces_count) FROM STDIN") 
RPostgreSQL::postgresqlCopyInDataframe(con, df) 
rs <- RPostgreSQL::postgresqlgetResult(con)
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



insert_gpr_trace <- function(con, gpr){
  id_line <- DBI::dbGetQuery(con, 
                        "SELECT currval('gpr.gpr_line_id_line_seq')")
  
  gpr_int <- round(as.matrix(gpr) * 1/byte2volt())
  
  input <- character(ncol(gpr))
  for(i in seq_along(gpr)){
    input[i] <- paste0("(",
                      paste(paste0("ST_GeomFromText('POINT(", 
                             paste(gpr@coord[i,1:2], collapse = " "), 
                             ")', 4326)"),
                        gpr@coord[i,3],
                        paste0("'{",
                               paste(gpr_int[,i], collapse = ", "),
                               "}'"),
                        id_line,
                        nrow(gpr),
                        sep = ", "), 
                      ")" )
  }

  query <- paste("INSERT INTO gpr.gpr_trace(",
                 "coordinates,",
                 "elevation,",
                 "traces,",
                 "id_line,",
                 "traces_count",
                 ")",
                 "VALUES ",
                 paste(input, collapse = ", "),
                  ";")
  DBI::dbExecute(con, query)
  # query <- paste("INSERT INTO gpr.gpr_trace(",
  #                "coordinates,",
  #                "elevation,",
  #                "traces,",
  #                "id_line,",
  #                "traces_count",
  #                ")",
  #                "VALUES (",
  #                 "ST_GeomFromText('POINT(10.809003 54.097834)',4326),",
  #                 "125.23,",
  #                 "'{0, 10, 126, 10, -125, -15}',",
  #                 "3007,",
  #                 "111",
  #                 ");")
}

intArrayToInt <- function(x){
  sapply(x, function(x) as.integer(unlist(strsplit(x, ",", fixed = TRUE))))
}

get_gpr_trace_trace <- function(con){
  bb <- DBI::dbGetQuery(con, "SELECT gpr_trace.traces FROM  gpr.gpr_trace")
  dim(bb)
  bb1 <- gsub("\\{|\\}", "", as.vector(bb[, 1]))
  bb4 <- unname(sapply(bb1, intArrayToInt))
  # bb0 <- RPostgres::dbSendQuery(con, "SELECT * FROM  gpr.gpr_trace")
  # bb1 <- RPostgres::dbFetch(bb0)
  # bb1[, 4] <- gsub("\\{|\\}", "", bb1[, 4])
  # bb42 <- sapply(bb1[,4], intArrayToInt)
  # plot3D::image2D(bb42)
  return(bb4)
}

get_gpr_trace_coords <- function(x){
  dd <- DBI::dbGetQuery(con, paste("SELECT ST_X(coordinates),",
                                   "ST_Y(coordinates),",
                                   "elevation",
                                   "FROM gpr.gpr_trace"))
}

insert_gpr_trace(con, gpr)

get_gpr_trace(con)

gd <- get_gpr_trace_trace(con)
plot3D::image2D(gd)

xyz <- get_gpr_trace_coords(con)
plot(xyz[,1:2])



gprbits <- intToBits(gpr_int[,1])


x <- "A test string"
(y <- charToRaw(x))


################################################################################
aa <- rpostgis::pgGetGeom(con, name = c("gpr","gpr_trace"), geom = "coordinates", 
          gid = "id_trace", other.cols = FALSE)
dim(aa)

class(aa)

plot(aa)



################################################################################


bb <- DBI::dbGetQuery(con, "SELECT * FROM  gpr.gpr_trace")
dim(bb)
bb[, 4] <- gsub("\\{|\\}", "", bb[, 4])
bb4 <- sapply(bb[,4], intArrayToInt)
plot3D::image2D(bb4)
bb[,2]

bb0 <- RPostgres::dbSendQuery(con, "SELECT * FROM  gpr.gpr_trace")
bb1 <- RPostgres::dbFetch(bb0)
bb1[, 4] <- gsub("\\{|\\}", "", bb1[, 4])
bb42 <- sapply(bb1[,4], intArrayToInt)
plot3D::image2D(bb42)


bb4 - as.integer(gpr_int[,i])

# last key id:
id_line <- dbGetQuery(con, 
                      "SELECT lastval('gpr.gpr_line_id_gpr_line')")



id_line <- dbGetQuery(con, 
                       "SELECT currval(pg_get_serial_sequence('gpr.gpr_line', 'id_line'))")



id_trace <- dbGetQuery(con, 
                       "SELECT currval(pg_get_serial_sequence('gpr.gpr_trace', 'id_trace_seq'))")


id_line <- dbGetQuery(con, 
                       "SELECT currval('gpr.gpr_trace_id_trace_seq')")



id_line <- dbGetQuery(con, 
                      "SELECT last_value FROM gpr.gpr_line")

con <- dbConnect(RSQLite::SQLite(), ":memory:")

dbWriteTable(con, "cars", head(cars, 3))
dbReadTable(con, "cars")   # there are 3 rows
dbExecute(
  con,
  "INSERT INTO cars (speed, dist) VALUES (1, 1), (2, 2), (3, 3)"
)
dbReadTable(con, "cars")   # there are now 6 rows

# Pass values using the param argument:
dbExecute(
  con,
  "INSERT INTO cars (speed, dist) VALUES (?, ?)",
  param = list(4:7, 5:8)
)
dbReadTable(con, "cars")   # there are now 10 rows

dbDisconnect(con)

#------------------------------------------------------------------------------#
#                           sp approach                                        #
#------------------------------------------------------------------------------#

library(RGPR)
library(Rook)
library(rpostgis)

x <- RGPR::readGPR("data/DT1/XLINE00.DT1")
plot(x)

xyz <- read.table( "data/DT1/XLINE00.txt", header = TRUE)
str(xyz)
RGPR::coord(x) <- xyz
RGPR::crs(x) <- c("+init=epsg:2055")

dim(x)
dim(xyz)

spPts <- RGPR::as.SpatialPoints(x)

xdata <- as.data.frame(t(as.matrix(x)))
spdf <- sp::SpatialPointsDataFrame(spPts, xdata)

sp::plot(spdf[,10], pch = 20, col = )

xx <- as.data.frame(spdf)

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



#------------------------------------------------------------------------------#
#                           sf approach                                        #
#------------------------------------------------------------------------------#

library(RGPR)
library(Rook)
library(rpostgis)
library(sf)

x <- RGPR::readGPR("data/DT1/XLINE00.DT1")
plot(x)

xyz <- read.table( "data/DT1/XLINE00.txt", header = TRUE)
str(xyz)
RGPR::coord(x) <- xyz
RGPR::crs(x) <- c("+init=epsg:2055")

dim(x)
dim(xyz)

xm <- as.matrix(x)
rownames(xm) <- paste0("t", 1:nrow(xm))
x_df <- as.data.frame(cbind(coord(x), t(xm)))
x_df[1:5,1:10]
names(x_df)

s_sf <- df::st_as_sf(x_df, coords = c(1,2, 3))

plot(s_sf)

# for sf object
dbWriteTable(con, 
             name = "GPRsf",
             s_sf, 
             overwrite = TRUE)

y <- st_read(con, "GPRsf")

sf::plot(y)

#------------------------------------------------------------------------------#

sfx <- sf::st_multipoint(x = coord(x) , dim = "XYZ")

plot(sfx)

sf::st_agr(sfx) <- as.matrix(x)

x_sfc <- sf::st_as_sfc(as.data.frame(coord(x)))

set.seed(123)
m <- matrix(runif(10),ncol=2)

m <- as.data.frame(m)
m_sf <- st_as_sf(m, coords = c(1,2))

m %>% 
  as.data.frame %>% 
  sf::st_as_sf(coords = c(1,2))


library(sf)
nc = st_read(system.file("shape/nc.shp", package="sf"))
plot(nc[1])

nc2 <- nc[1:2]

plot(nc2)

dbDataType(con, nc2)

# for sf object
dbWriteTable(con, 
             name = "nc",
             nc2[1:10,], 
             overwrite = TRUE)

nc3 <- dbReadTable(con, 'nc') 
plot(nc3)


library(sp)

data(meuse, package = "sp")

coords <- SpatialPoints(meuse[, c("x", "y")])
spdf <- SpatialPointsDataFrame(coords, meuse)


rpostgis::pgInsert(con, name = c("public", "meuse_data"), data.obj = spdf, overwrite = TRUE)

pp <- rpostgis::pgGetGeom(con, c("public", "meuse_data"))

plot(pp, col = "red")

rpostgis::dbDrop(con,
                 name = c("public", "meuse_data"),
                 type = "table")

rpostgis::dbDrop(con,
                 name = c("common", "nc"),
                 type = "table")
