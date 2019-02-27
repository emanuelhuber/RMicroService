

# install.packages("RPostgreSQL")
require("RPostgreSQL")

library(rpostgis)

setwd("/media/huber/Seagate1TB/UNIBAS/PROJECTS/RGPR/CODE/DEVELOPMENT/WebAPI")


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
