# This script maps randomly-dispersed flows from every non-residential location
# in Kathmanudu.

#library (dodgr) # needs latest version
devtools::load_all (file.path (here::here(), "..", "dodgr"), export_all = FALSE)
devtools::load_all (file.path (here::here(), "..", "m4ra"), export_all = FALSE)
#devtools::load_all (".", export_all = FALSE)
require (sf) # very important to use sf.[] method!
require (tidyverse)

data_dir <- file.path (here::here(), "..", "who-data", "kathmandu")
hw <- readRDS (file.path (data_dir, "osm", "kathmandu-hw.Rds"))
graph_full <- weight_streetnet (hw, wt_profile = "foot")
graph <- dodgr_contract_graph (graph_full)
verts <- dodgr_vertices (graph$graph)
#graph_sf <- dodgr_to_sf (graph)

# For flows **from** particular points (here, the buildings), the graph has to
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

# get kathmandu bus stops (not used at present):
#bs <- readRDS (file.path (data_dir, "osm", "kathmandu-bs.Rds"))
#xy <- t (vapply (bs$geometry, function (i) as.numeric (i), numeric (2)))
#colnames (xy) <- c ("x", "y") # Only 134 bus stops in Kathmandu
#bus_nodes <- verts$id [match_pts_to_graph (verts, xy)]

# And the buildings (polygons only; not multipolygons
message ("loading buildings ... ", appendLF = FALSE)
b1 <- file.path (data_dir, "osm", "kathmandu-bldg1.Rds")
b2 <- file.path (data_dir, "osm", "kathmandu-bldg2.Rds")
bldg <- rbind (readRDS (b1)$osm_polygons, readRDS (b1)$osm_polygons)
# try to identify buildings with some kind of purpose:
bldgf <- bldg %>% filter ( (!is.na (bldg$amenity) |  !is.na (bldg$leisure) |
                !is.na (bldg$office) | !is.na (bldg$office.name) |
                !is.na (bldg$office.type) | !is.na (bldg$opening_hours) |
                !is.na (bldg$opening.hours) | !is.na (bldg$operator) |
                !is.na (bldg$operator.type) | !is.na (bldg$shop) |
                !is.na (bldg$sport) | bldg$tourism == "museum") &
                bldg$building != "residential")
message ("done")

# First cut with all buildings together

bhts <- as.numeric (bldg$building.levels)
message ("There are ", format (length (which (!is.na (bhts))), big.mark = ","),
         " buldings with heights, or ",
         formatC (100 * length (which (!is.na (bhts))) / length (bhts),
                  format = "f", digits = 1),
         "% of all ", format (nrow (bldg), big.mark = ","), " buildings")
message ("Calculating centroids ... ", appendLF = FALSE)

# Get building areas and presume working density is proportional:
areas <- bldg %>% st_area () # in m^2
bhts [is.na (bhts)] <- 1
areas <- areas * bhts
# code to reduce employment densities of schools and hospitals, but not
# implemented coz education can readily be conflated with employment here
#indx <- which (bldg$building %in% c ("school", "hospital"))
#areas [indx] <- areas [indx] / 20 # 20-to-1 student

# Then map centroids of those areas onto the street network:
suppressWarnings ({
    xy <- st_transform (bldg, 6207) %>%
        st_centroid () %>%
        st_transform (., st_crs (bldg)$proj4string) %>%
        st_geometry () %>%
        lapply (as.numeric) %>%
        do.call (rbind, .)
})
colnames (xy) <- c ("x", "y")
message ("done\nMatching centroids to street network ... ", appendLF = FALSE)
bldg_nodes <- verts$id [match_pts_to_graph (verts, xy)]
# Those are mapped onto nodes on the contracted graph, so lots of overlap. Areas
# mapping onto same nodes are then added:
bldg_nodes <- tibble::tibble (node = bldg_nodes, area = areas) %>%
    dplyr::group_by (node) %>%
    dplyr::summarise (area = sum (area))


# `m4ra_spatial_intreaction1` requires density estimates at all vertices, so
# simply set the rest to 0
dens <- rep (0, nrow (verts))
dens [match (bldg_nodes$node, verts$id)] <- bldg_nodes$area

message ("done\nFinal calculation of flows dispersed from ",
         format (nrow (bldg_nodes), big.mark = ","), " buildings out to ",
         format (nrow (verts), big.mark = ","), " street network vertices")

# spatial interaction from all density points to the buidlings
# Note k = 2.5 or so is okay for bike, so arbitrarily set pedestrians at k = 0.1
k <- 2.5
fname <- "kathmandu-flows-from-bldgs-k25.Rds"
# quicker to loop over each bus stop because flow aggregation is much more
# efficient for a single source, because there are far fewer nodes_to in each
# case. flow aggregation is not parallelised (in C++), so this code can be
# directly run in parallel
pb <- txtProgressBar (style = 3)
flows <- rep (0, nrow (graph$graph))
for (i in seq (bldg_nodes$node))
{
    si <- m4ra_spatial_interaction1 (graph$graph, node = bldg_nodes$node [i],
                                     dens = dens, k = k)
    indx <- which (si > 0 & !is.na (si))
    si <- si [indx]
    nodes_to <- verts$id [indx] # this is why the explicit loop saves!

    if ("flow" %in% names (graph)) graph$flow <- NULL
    flows <- flows + dodgr_flows_aggregate (graph$graph,
                                            from = bldg_nodes$node [i],
                                            to = nodes_to,
                                            flows = si)$flow
    saveRDS (flows, file = fname)

    setTxtProgressBar (pb, i / length (bldg_nodes$node))
}
close (pb)


# Map flows on contracted graph back on to full network using code from
# https://github.com/ATFutures/m4ra/blob/master/R/flows.R
#indx_to_full <- match (graph$edge_map$edge_old, graph_full$edge_id)
#indx_to_contr <- match (graph$edge_map$edge_new, graph$graph$edge_id)
# edge_map only has the contracted edges; flows from the original
# non-contracted edges also need to be inserted
#edges <- graph$graph$edge_id [which (!graph$graph$edge_id %in%
#                                     graph$edge_map$edge_new)]
#indx_to_full <- c (indx_to_full, match (edges, graph_full$edge_id))
#indx_to_contr <- c (indx_to_contr, match (edges, graph$graph$edge_id))
#graph_full$flow <- 0
#graph_full$flow [indx_to_full] <- flows [indx_to_contr]


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
