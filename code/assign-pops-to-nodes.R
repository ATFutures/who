library(tidyverse)
devtools::install_github("robinlovelace/osmdata")
library(osmdata)
library(raster)
library(tmap)
library(sf)

city <- "accra"
city <- tolower (city)

boundary_bb = getbb(city)
boundary = stplanr::bb2poly(boundary_bb) %>% 
  st_as_sf()
data_dir <- "../who-data"
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
# Following line recycles OSM IDs from ways, not nodes as required here.
nodes = st_cast(ways, "POINT") # 172,238 nodes for Accra
# Following 2 lines re-extract the proper IDs:
xy <- lapply (ways$geometry, function (i) as.matrix (i))
nodes$osm_id <- rownames (do.call (rbind, xy))
pd_sf$id = 1:nrow(pd_sf)
nodes_joined = st_join(nodes, pd_sf) 
# nodes_agg = aggregate(pd_sf, nodes, mean) # works but how to divide them again?
layer_name <- gsub (".tif", "", pop_layer)
sf_dens <- pd_sf [[layer_name]]

# sf aggregation is crap; this is about 1,000 times faster (guessing there, but
# sure feels like it):
dat <- data.frame (osm_id = nodes_joined$osm_id,
                   pop = nodes_joined [[layer_name]]) %>%
    group_by (osm_id) %>%
    summarize (pop = sum (pop))
nodes_new <- nodes_joined [match (dat$osm_id, nodes_joined$osm_id), ]
names (nodes_new) [which (names (nodes_new) == layer_name)] <- "pop"
nodes_new$pop <- dat$pop

pd_sf_sample = pd_sf %>% filter(layer_name > 3000)
nodes_sample = nodes_new[pd_sf_sample,]
tmap_mode("view")
qtm(pd_sf_sample) +
  qtm(nodes_sample) # explanation: many nodes have no points in!

saveRDS (nodes_new, file.path (data_dir, city, "osm", "nodes_new.Rds"))
