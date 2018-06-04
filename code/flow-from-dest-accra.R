# This script maps flows from every bus stop in Accra to every commercial
# building, in an attempt to capture last-mile flows related to employment.

#library (dodgr) # needs latest version
devtools::load_all (file.path (here::here(), "..", "dodgr"), export_all = FALSE)
devtools::load_all (file.path (here::here(), "..", "m4ra"), export_all = FALSE)
#devtools::load_all (".", export_all = FALSE)
require (sf) # very important to use sf.[] method!

data_dir <- file.path (here::here(), "..", "who-data", "accra")
hw <- readRDS (file.path (data_dir, "osm", "accra-hw.Rds"))
graph <- weight_streetnet (hw, wt_profile = "foot")
verts <- dodgr_vertices (graph)
graph_sf <- dodgr_to_sf (graph)

# For flows **from** particular points (here, the bus stops), the graph has to
# be reversed:
from_id <- graph$from_id
from_lon <- graph$from_lon
from_lat <- graph$from_lat
graph$from_id <- graph$to_id
graph$from_lon <- graph$to_lon
graph$from_lat <- graph$to_lat
graph$to_id <- from_id
graph$to_lon <- from_lon
graph$to_lat <- from_lat

# get ten accra bus stops:
bs <- readRDS (file.path (data_dir, "osm", "accra-bs.Rds"))
xy <- t (vapply (bs$geometry, function (i) as.numeric (i), numeric (2)))
colnames (xy) <- c ("x", "y")
# all 2,451 stops:
bus_nodes <- verts$id [match_pts_to_graph (verts, xy)]

# And the buildings (polygons only; not multipolygons
bldg <- readRDS (file.path (data_dir, "osm", "accra-bldg.Rds"))$osm_polygons
# try to identify buildings with some kind of purpose:
library (tidyverse)
library (magrittr)
bldg %<>% filter (!is.na (bldg$name) | !is.na (bldg$alt_name) |
                !is.na (bldg$amenity) | !is.na (bldg$diplomatic) |
                !is.na (bldg$government) | !is.na (bldg$leisure) |
                !is.na (bldg$office) | !is.na (bldg$opening_hours) |
                !is.na (bldg$operator) | !is.na (bldg$shop) |
                !is.na (bldg$sport) | bldg$tourism == "museum" |
                bldg$building %in%
                c ("civic", "commerical", "garage", "hangar", "hospital",
                   "hotel", "industrial", "lecture halls", "manufacture",
                   "office", "public", "retail", "school", "service",
                   "supermarket", "university", "warehouse") &
                bldg$building != "residential")

indx <- unique (c (indx1, indx2))
# Remove residential buildings:
indx <- indx [which (!indx %in% which (bldg$building == "residential"))]
# That gives 678 / 24,490 = 2.7% of buildings

bldg <- bldg [indx, ]
bhts <- as.numeric (bldg$building.levels) # 88 / 24490 buildings

# Get building areas and presume working density is proportional:
areas <- bldg %>% st_area () # in m^2
bhts [is.na (bhts)] <- 1
areas <- areas * bhts
# code to reduce employment densities of schools and hospitals, but not
# implemented coz education can readily be conflated with employment here
#indx <- which (bldg$building %in% c ("school", "hospital"))
#areas [indx] <- areas [indx] / 20 # 20-to-1 student

# Then map centroids of those areas onto the street network:
xy <- st_transform (bldg, 29101) %>%
    st_centroid () %>%
    st_transform (., st_crs (bldg)$proj4string) %>%
    st_geometry () %>%
    lapply (as.numeric) %>%
    do.call (rbind, .)
colnames (xy) <- c ("x", "y")
work_nodes <- verts$id [match_pts_to_graph (verts, xy)]
# `m4ra_spatial_intreaction1` requires density estimates at all vertices, so
# simply set the rest to 0
dens <- rep (0, nrow (verts))
dens [match (work_nodes, verts$id)] <- areas

# spatial interaction from all density points to the bus stops:
# Note k = 2.5 or so is okay for bike, so arbitrarily set pedestrians at k = 0.1
k <- 0.5
# quicker to loop over each bus stop because flow aggregation is much more
# efficient for a single source, because there are far fewer nodes_to in each
# case. flow aggregation is not parallelised (in C++), so this code can be
# directly run in parallel
pb <- txtProgressBar (style = 3)
flows <- rep (0, nrow (graph))
for (i in seq (bus_nodes))
{
    si <- m4ra_spatial_interaction1 (graph, node = bus_nodes [i],
                                     dens = dens, k = k)
    indx <- which (si > 0 & !is.na (si))
    si <- si [indx]
    nodes_to <- verts$id [indx] # this is why the explicit loop saves!

    if ("flow" %in% names (graph)) graph$flow <- NULL
    flows <- flows + dodgr_flows_aggregate (graph, from = bus_nodes [i],
                                            to = nodes_to, flows = si)$flow
    saveRDS (flows, file = "accra-flows-from-busstops.Rds")

    setTxtProgressBar (pb, i / length (bus_nodes))
}
close (pb)

#graph$flow <- flows
#gc <- dodgr_contract_graph (graph)
#graphm <- merge_directed_flows (gc$graph)
#indx <- match (graphm$edge_id, names (graph_sf))
#graph_sf <- graph_sf [indx]

# cut out lowest 1% of flows; speeds up rendering significantly
#indx <- which (graphm$flow > 0.01 * max (graphm$flow))
#graphm <- graphm [indx, ]
#graph_sf <- graph_sf [indx]

#require (mapview)
#ncols <- 30
#flow <- graphm$flow / max (graphm$flow)
#cols <- colorRampPalette (c ("lawngreen", "red")) (ncols) [ceiling (ncols * flow)]
#mapview (graph_sf, color = cols, lwd = 10 * flow)
