# Convert .Rds files to .gpkg files
rds_to_gpkg <- function(f, output_file = gsub(".Rds", ".gpkg", f)) {
  d = readRDS(f)
  if(is(d, "Spatial")) {
    d = sf::st_as_sf(d)
  } 
  sf::st_write(d, output_file)
}
rds_to_gpkg(f = "../who-data/accra/osm/accra-hw.Rds")
rds_to_gpkg(f = "../who-data/accra/osm/nodes_new.Rds")
