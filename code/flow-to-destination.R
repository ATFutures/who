# This script maps flows from the **entire** population density data set to one
# single bus stop in Accra

#library (dodgr) # needs latest version
devtools::load_all ("../dodgr", export_all = FALSE)
devtools::load_all ("../m4ra", export_all = FALSE)
#devtools::load_all (".", export_all = FALSE)
hw <- readRDS ("../who-data/accra/osm/accra-hw.Rds")
graph <- weight_streetnet (hw, wt_profile = "foot")
verts <- dodgr_vertices (graph)

# get one accra bus stop:
bs <- readRDS ("../who-data/accra/osm/accra-bs.Rds")
xy <- t (vapply (bs$geometry, function (i) as.numeric (i), numeric (2)))
colnames (xy) <- c ("x", "y")
bs <- xy [sample (nrow (xy), 1), , drop = FALSE]
node <- verts$id [match_pts_to_graph (verts, bs)]

# and pop densities
dens <- readRDS ("../who-data/accra/osm/nodes_new.Rds")$pop
if (length (dens) != nrow (verts)) stop ("nope")

# spatial interaction from all density points to that bus stop:
# Note k = 2.5 or so is okay for bike, so arbitrarily set pedestrians at k = 0.1
k <- 0.5
si <- m4ra_spatial_interaction1 (graph, node = node, dens = dens, k = k)

# comparing si with distance gives precisely the expected results
plotsi <- FALSE
if (plotsi)
{
    d <- dodgr_dists (graph, from = node, to = verts$id) [1, ]
    sip <- si / max (si, na.rm = TRUE)
    plot (d, sip, col = "grey", log = "y")
    dfit <- seq (min (d, na.rm = TRUE), max (d, na.rm = TRUE), length.out = 100) [-1]
    yfit <- exp (-dfit / k)
    lines (dfit, yfit, col = "red", lwd = 2)
}

indx <- which (si > 0 & !is.na (si))
length (indx)
si <- si [indx]
nodes_to <- verts$id [indx]

if ("flow" %in% names (graph)) graph$flow <- NULL
graph <- dodgr_flows_aggregate (graph, from = node, to = nodes_to, flows = si)
require (sf) # very important to use sf.[] method!
graph_sf <- dodgr_to_sf (graph)
gc <- dodgr_contract_graph (graph)
graphm <- merge_directed_flows (gc$graph)
indx <- match (graphm$edge_id, names (graph_sf))
graph_sf <- graph_sf [indx]

# cut out lowest 1% of flows:
#indx <- which (graphm$flow > 0.01 * max (graphm$flow))
#graphm <- graphm [indx, ]
#graph_sf <- graph_sf [indx]


require (mapview)
ncols <- 30
flow <- graphm$flow / max (graphm$flow)
cols <- colorRampPalette (c ("lawngreen", "red")) (ncols) [ceiling (ncols * flow)]
mapview (graph_sf, color = cols, lwd = 10 * flow)
