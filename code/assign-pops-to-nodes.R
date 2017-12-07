library(tidyverse)
library(osmdata)
library(raster)
library(sf)

boundary = getbb("Kathmandu", format_out = )
pd = raster::raster("../who-data/accra/popdens/GHA15_040213.tif")
summary(pd)
pd_sf = pd %>% 
  raster::rasterToPolygons() %>% 
  st_as_sf()
mapview::mapview(pd) # nice viz
nodes = readRDS("../who-data/accra/osm/accra-hw.Rds")
