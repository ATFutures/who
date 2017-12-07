library(tidyverse)
devtools::install_github("robinlovelace/osmdata")
library(osmdata)
library(raster)
library(tmap)
library(sf)

boundary_bb = getbb("Accra")
boundary = stplanr::bb2poly(boundary_bb) %>% 
  st_as_sf()
pd = raster::raster("../who-data/accra/popdens/GHA15_040213.tif")
pd # 200k cells
# pd = mask(pd, as_Spatial(st_geometry(boundary)))
pd = crop(pd, extent(boundary_bb)) # make smaller dataset - 148k cells

pd_sf = pd %>% 
  raster::rasterToPolygons() %>% 
  st_as_sf()
tmap_mode("view")
qtm(pd) +
  qtm(boundary)
nodes = readRDS("../who-data/accra/osm/accra-hw.Rds")
