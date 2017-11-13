devtools::load_all()
# get input data
region_name = "kathmandu"
region_shape = getbb(place_name = region_name, format_out = "polygon")
region_shape = region_shape[[1]]
schools = opq(bbox = region_name) %>% 
  add_osm_feature(key = "building", value = "school") %>% 
  trim_osmdata(region_shape)
saveRDS(schools, "who-data/schools.Rds")