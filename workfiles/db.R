

# install.packages("RPostgreSQL")
require("RPostgreSQL")

library(rpostgis)

setwd("/media/huber/Seagate1TB/UNIBAS/PROJECTS/RGPR/CODE/RMicroService")


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


# PostgreSQL offers a nice syntax sugar for this:
#   
#   CREATE TABLE mytable (id BIGSERIAL PRIMARY KEY, value INT);
# 
# which is equivalent to
# 
# CREATE SEQUENCE mytable_id_seq; -- table_column_'seq'
# CREATE TABLE mytable (id BIGINT NOT NULL PRIMARY KEY DEFAULT NEXTVAL('mytable_id_seq'), value INT); -- it's not null and has a default value automatically
# 
# # BIGSERIAL / bigint
# # serial ( 1 to 2147483647) <-> integer 


rpostgis::dbDrop(con,
                 name = c("gpr", "gpr_trace"),
                 type = "table")

# CREATE TABLE gpr.gpr_survey
# (
#   id_gpr_survey integer NOT NULL DEFAULT nextval('gpr.gpr_survey_id_gpr_survey_seq'::regclass),
#   description character varying(200) COLLATE pg_catalog."default" NOT NULL,
#   date_creation timestamp with time zone NOT NULL,
#   geometry geometry(MultiPolygon,4326) NOT NULL,
#   id_standard_class integer,
#   id_project integer,
#   CONSTRAINT gpr_survey_pkey PRIMARY KEY (id_gpr_survey),
#   CONSTRAINT ee276226759824f579c2274252352ffc FOREIGN KEY (id_standard_class)
#   REFERENCES gpr.standard_class (id_standard_class) MATCH SIMPLE
#   ON UPDATE NO ACTION
#   ON DELETE NO ACTION
#   DEFERRABLE INITIALLY DEFERRED,
#   CONSTRAINT gpr_gp_id_project_6d93ebdd58ffdd76_fk_t_genm_project_id_project FOREIGN KEY (id_project)
#   REFERENCES common.t_genm_project (id_project) MATCH SIMPLE
#   ON UPDATE NO ACTION
#   ON DELETE NO ACTION
#   DEFERRABLE INITIALLY DEFERRED
# )

# CREATE TABLE gpr.gpr_line
# (
#   id_gpr_line integer NOT NULL DEFAULT nextval('gpr.gpr_line_id_gpr_line'::regclass),
#   description character varying(200) COLLATE pg_catalog."default",
#   collect_date timestamp without time zone,
#   date_creation timestamp without time zone,
#   geometry geometry(MultiLineString,4326),
#   id_project integer,
#   line_num character varying(10) COLLATE pg_catalog."default",
#   id_standard_class integer,
#   imagefile character varying(100) COLLATE pg_catalog."default",
#   id_gpr_survey integer,
#   CONSTRAINT pk_gprs_gpr_line PRIMARY KEY (id_gpr_line),
#   CONSTRAINT "D4626b0734f8197f2e008621525eca79" FOREIGN KEY (id_gpr_survey)
#   REFERENCES gpr.gpr_survey (id_gpr_survey) MATCH SIMPLE
#   ON UPDATE NO ACTION
#   ON DELETE NO ACTION
#   DEFERRABLE INITIALLY DEFERRED,
#   CONSTRAINT "D732ccf08ca500cee1ddb1bcd336782e" FOREIGN KEY (id_standard_class)
#   REFERENCES gpr.standard_class (id_standard_class) MATCH SIMPLE
#   ON UPDATE NO ACTION
#   ON DELETE NO ACTION
#   DEFERRABLE INITIALLY DEFERRED
# )

# x0 <- SQL("CREATE SEQUENCE gpr.gpr_trace_id_trace_seq")
# 
# 
# x <- SQL(paste("CREATE TABLE gpr.gpr_trace(",
#   "id_trace integer NOT NULL DEFAULT nextval('gpr.gpr_trace_id_trace_seq'::regclass),",
#   "geometry geometry(Point,4326),",
#   "altitude numeric(5,2),",
#   "traces smallint[],",
#   "id_gpr_line integer NOT NULL,",
#   "traces_count integer NOT NULL,",
#   "CONSTRAINT gpr_trace_pkey PRIMARY KEY (id_trace),",
#   "CONSTRAINT gpr_trace_id_gpr_line_678a36a92952f8bb_fk_gpr_line_id_gpr_line FOREIGN KEY (id_gpr_line)",
#   "REFERENCES gpr.gpr_line (id_gpr_line) MATCH SIMPLE",
#   "ON UPDATE NO ACTION",
#   "ON DELETE NO ACTION",
#   "DEFERRABLE INITIALLY DEFERRED",
#   ")", sep = "\n"))
# 
# dbExecute(con, x0)
# dbExecute(con, x)


x <- SQL(paste(
  "CREATE TABLE gpr.gpr_trace(",
   "id_trace serial,",
   "coordinates geometry(Point,4326),",
   "altitude numeric(5,2),",
   "traces smallint[],",
   "id_gpr_line integer NOT NULL,",
   "traces_count integer NOT NULL,",
   "CONSTRAINT gpr_trace_pkey PRIMARY KEY (id_trace),",
   "CONSTRAINT gpr_trace_id_gpr_line FOREIGN KEY (id_gpr_line)",
   "REFERENCES gpr.gpr_line (id_gpr_line) MATCH SIMPLE",
   "ON UPDATE NO ACTION",
   "ON DELETE NO ACTION",
   "DEFERRABLE INITIALLY DEFERRED",
   ")", sep = "\n"))

# CREATE TABLE gpr.gpr_trace
# (
#   id_trace integer NOT NULL DEFAULT nextval('gpr.gpr_trace_id_trace_seq1'::regclass),
#   coordinates geometry(Point,4326),
#   altitude numeric(5,2),
#   traces smallint[],
#   id_gpr_line integer NOT NULL,
#   traces_count integer NOT NULL,
#   CONSTRAINT gpr_trace_pkey PRIMARY KEY (id_trace),
#   CONSTRAINT gpr_trace_id_gpr_line FOREIGN KEY (id_gpr_line)
#   REFERENCES gpr.gpr_line (id_gpr_line) MATCH SIMPLE
#   ON UPDATE NO ACTION
#   ON DELETE NO ACTION
#   DEFERRABLE INITIALLY DEFERRED
# )
dbExecute(con, x)

rpostgis::dbTableInfo(con, "gpr_trace")  
  
# table_catalog table_schema table_name       column_name ordinal_position
# 1  gvx  gpr   gpr_line id_gpr_line        integer
# 2  gvx  gpr   gpr_line description        character varying 200
# 3  gvx  gpr   gpr_line collect_date       timestamp without time zone
# 4  gvx  gpr   gpr_line date_creation      timestamp without time zone
# 5  gvx  gpr   gpr_line geometry           USER-DEFINED
# 6  gvx  gpr   gpr_line id_project         integer
# 7  gvx  gpr   gpr_line line_num           character varying 10
# 8  gvx  gpr   gpr_line id_standard_class  integer
# 9  gvx  gpr   gpr_line imagefile          character varying 100
# 10 gvx  gpr   gpr_line id_gpr_survey      integer

query <- paste("INSERT INTO gpr.gpr_line(",
               "description,",
               "id_project",
               ")",
               "VALUES ('NICE PROJECT',",
               "5",
               ");")

dbExecute(con, query)
aa <- dbGetQuery(con, "SELECT * FROM  gpr.gpr_line")


rpostgis::dbTableInfo(con, "gpr_line")  


query <- paste("INSERT INTO gpr.gpr_trace(",
               "coordinates,",
               "altitude,",
               "traces,",
               "id_gpr_line,",
               "traces_count",
               ")",
               "VALUES (",
                "ST_GeomFromText('POINT(10.809003 54.097834)',4326),",
                "125.23,",
                "'{0, 10, 126, 10, -125, -15}',",
                "3007,",
                "111",
                ");")

dbExecute(con, query)

bb <- dbGetQuery(con, "SELECT * FROM  gpr.gpr_trace")


# last key id:
id_trace <- dbGetQuery(con, 
                       "SELECT currval(pg_get_serial_sequence('gpr.gpr_trace', 'id_trace'))")
id_trace <- dbGetQuery(con, 
                       "SELECT currval(pg_get_serial_sequence('gpr.gpr_trace', 'id_trace'))")

id_line <- dbGetQuery(con, 
                       "SELECT currval('gpr.gpr_line_id_gpr_line')")






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
