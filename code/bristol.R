# aim: generate maps and ods for bristol

pd = raster::raster("../who-data/accra/popdens/GHA15_040213.tif")
raster::res(pd) # 0.0008333
pd_sf = pd %>% 
  raster::rasterToPolygons() %>% 
  st_as_sf()
pd_sf_proj = st_transform(pd_sf, 2136)
r1 = pd_sf_proj[1, ]
mapview::mapview(r1)
st_area(r1)^0.5 # 300 m cells

ways = readRDS("../who-data/bristol/osm/bristol-hw.Rds")
ways_bb = stplanr::geo_bb(ways) %>% 
  as("Spatial")
ext = raster::extent(ways_bb)
r = raster::raster(ext, crs = "+proj=longlat +datum=WGS84", resolution = 0.005)
# raster::values(r) <- 1
# mapview::mapview(r)
r_sf = st_as_sf(r)

devtools::install_github("robinlovelace/ukboundaries")
library(ukboundaries)
data(package = "ukboundaries")
data("oas_sw")
pop_points = as(oas_sw["All Ages"], "Spatial")
pd = raster::rasterize(pop_points, r, fun = sum)
pd_sf = pd %>% 
  raster::rasterToPolygons() %>% 
  st_as_sf()
plot(pd$All.Ages)
mapview::mapview(pd)
raster::writeRaster(pd$All.Ages, "../who-data/bristol/popdens/bris-official-0.005-res.tif")

# allocate pops to nodes
nodes = st_cast(ways, "POINT")
pd_sf$id = 1:nrow(pd_sf)
nodes_joined = st_join(nodes, pd_sf) 
# nodes_agg = aggregate(pd_sf, nodes, mean) # works but how to divide them again?
nodes_aggregated = nodes_joined %>% 
  st_set_geometry(NULL) %>% 
  group_by(id) %>% 
  summarise(pop = mean(All.Ages, na.rm = T) / sum(!is.na(All.Ages)))
sum(pd_sf$All.Ages)
sum(nodes_joined$All.Ages, na.rm = T) # higher
sum(nodes_aggregated$pop, na.rm = T) # too few
nodes_new = inner_join(nodes_joined, nodes_aggregated)
sum(nodes_new$pop, na.rm = T) # correct!

pd_sf_sample = pd_sf %>% filter(All.Ages > 3000)
nodes_sample = nodes_new[pd_sf_sample,]
tmap_mode("view")
qtm(pd_sf_sample) +
  qtm(nodes_sample) # explanation: many nodes have no points in!

saveRDS(nodes_new, "../who-data/bristol/osm/nodes_new.Rds")
