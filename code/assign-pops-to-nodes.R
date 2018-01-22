library(tidyverse)
devtools::install_github("robinlovelace/osmdata")
library(osmdata)
library(raster)
library(tmap)
library(sf)

city <- "kathmandu"
city <- tolower (city)

boundary_bb = getbb(city)
boundary = stplanr::bb2poly(boundary_bb) %>% 
  st_as_sf()
data_dir <- "/data/data/who-data" # change that 
if (city == "accra")
    pop_layer <- "GHA15_040213.tif"
else if (city == "kathmandu")
    pop_layer <- "NPL_ppp_v2c_2015_UNadj.tif"
pd <- raster::raster (file.path (data_dir, tolower (city), "popdens", pop_layer))
pd # 200k cells
# pd = mask(pd, as_Spatial(st_geometry(boundary)))
pd = crop(pd, extent(boundary_bb)) # make smaller dataset - 148k cells

pd_sf = pd %>% 
  raster::rasterToPolygons() %>% 
  st_as_sf()
osm_dir <- file.path (data_dir, city, "osm")
ways = readRDS (file.path (osm_dir, paste0 (city, "-hw.Rds")))
nodes = st_cast(ways, "POINT")
pd_sf$id = 1:nrow(pd_sf)
nodes_joined = st_join(nodes, pd_sf) 
# nodes_agg = aggregate(pd_sf, nodes, mean) # works but how to divide them again?
layer_name <- gsub (".tif", "", pop_layer)
sf_dens <- pd_sf [[layer_name]]
nodes_aggregated = nodes_joined %>% 
  st_set_geometry(NULL) %>% 
  group_by(id) %>% 
  summarise(pop = mean(sf_dens, na.rm = T) / sum(!is.na(sf_dens)))
sum(sf_dens)
sum(nodes_joined [[layer_name]], na.rm = T) # higher
sum(nodes_aggregated$pop, na.rm = T) # too few
nodes_new = inner_join(nodes_joined, nodes_aggregated)
sum(nodes_new$pop, na.rm = T) # 1/3 less - why?

pd_sf_sample = pd_sf %>% filter(layer_name > 3000)
nodes_sample = nodes_new[pd_sf_sample,]
tmap_mode("view")
qtm(pd_sf_sample) +
  qtm(nodes_sample) # explanation: many nodes have no points in!

saveRDS (nodes_new, file.path (data_dir, city, "osm", "nodes_new.Rds"))
