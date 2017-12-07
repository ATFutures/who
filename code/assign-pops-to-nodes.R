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
ways = readRDS("../who-data/accra/osm/accra-hw.Rds")
nodes = st_cast(ways, "POINT")
pd_sf$id = 1:nrow(pd_sf)
nodes_joined = st_join(nodes, pd_sf) 
# nodes_agg = aggregate(pd_sf, nodes, mean) # works but how to divide them again?
nodes_aggregated = nodes_joined %>% 
  st_set_geometry(NULL) %>% 
  group_by(id) %>% 
  summarise(pop = mean(GHA15_040213, na.rm = T) / sum(!is.na(GHA15_040213)))
sum(pd_sf$GHA15_040213)
sum(nodes_joined$GHA15_040213, na.rm = T) # higher
sum(nodes_aggregated$pop, na.rm = T) # too few
nodes_new = inner_join(nodes_joined, nodes_aggregated)
sum(nodes_new$pop, na.rm = T) # 1/3 less - why?

pd_sf_sample = pd_sf %>% filter(GHA15_040213 > 3000)
nodes_sample = nodes_new[pd_sf_sample,]
tmap_mode("view")
qtm(pd_sf_sample) +
  qtm(nodes_sample) # explanation: many nodes have no points in!

saveRDS(nodes_new, "../who-data/accra/osm/nodes_new.Rds")
