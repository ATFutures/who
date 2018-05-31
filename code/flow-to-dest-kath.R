# This script maps flows from the **entire** population density data set to
# every single bus stop in Accra. These are **first-mile** flows.

#library (dodgr) # needs latest version
devtools::load_all ("../dodgr", export_all = FALSE)
devtools::load_all ("../m4ra", export_all = FALSE)
#devtools::load_all (".", export_all = FALSE)
require (sf) # very important to use sf.[] method!

hw <- readRDS ("../who-data/accra/osm/accra-hw.Rds")
graph <- weight_streetnet (hw, wt_profile = "foot")
verts <- dodgr_vertices (graph)

# get ten accra bus stops:
bs <- readRDS ("../who-data/accra/osm/accra-bs.Rds")
xy <- t (vapply (bs$geometry, function (i) as.numeric (i), numeric (2)))
colnames (xy) <- c ("x", "y")
#nstops <- 10
#bs <- xy [sample (nrow (xy), nstops), , drop = FALSE]
#bus_nodes <- verts$id [match_pts_to_graph (verts, bs)]
# all 2,451 stops:
bus_nodes <- verts$id [match_pts_to_graph (verts, xy)]

# and pop densities
dens <- readRDS ("../who-data/accra/osm/nodes_new.Rds")$pop
if (length (dens) != nrow (verts)) stop ("nope")

# spatial interaction from all density points to that bus stop:
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
    saveRDS (flows, file = "accra-flows-to-busstops.Rds")

    setTxtProgressBar (pb, i / length (bus_nodes))
}
close (pb)

graph$flow <- flows
graph_sf <- dodgr_to_sf (graph)
gc <- dodgr_contract_graph (graph)
graphm <- merge_directed_flows (gc$graph)
indx <- match (graphm$edge_id, names (graph_sf))
graph_sf <- graph_sf [indx]

# cut out lowest 1% of flows; speeds up rendering significantly
indx <- which (graphm$flow > 0.01 * max (graphm$flow))
graphm <- graphm [indx, ]
graph_sf <- graph_sf [indx]

require (mapview)
ncols <- 30
flow <- graphm$flow / max (graphm$flow)
cols <- colorRampPalette (c ("lawngreen", "red")) (ncols) [ceiling (ncols * flow)]
mapview (graph_sf, color = cols, lwd = 10 * flow)
