library (dodgr)
# hard-code dirs for now; this will later be done with the drat archive
pd_dir <- file.path (here::here(), "../popdens")
devtools::load_all (pd_dir, export_all = FALSE)

# Get OD matrix:
data_dir <- file.path (here::here(), "../who-data")
accra_nodes <- readRDS (file.path (data_dir, "accra", "osm", "nodes_new.Rds"))
# sub-sample for proof-of-principle:
n <- 100
indx <- sample (sequence (nrow (accra_nodes)), size = n)
nodes <- accra_nodes [indx, ]

# get population and coordinates:
dens <- nodes$pop
x <- lapply (nodes$geometry, function (i) i [1]) %>% unlist () %>% as.numeric ()
y <- lapply (nodes$geometry, function (i) i [2]) %>% unlist () %>% as.numeric ()
xy <- data.frame (x = x, y = y)

# convert dens to OD matrix, using Accra street net
transport <- "bicycle" # for weighting profile
net <- readRDS (file.path (data_dir, "accra", "osm", "accra-hw.Rds")) %>%
    weight_streetnet (wt_profile = transport)
# match xy to network. Although dodgr can make contracted graphs that include
# explicitly specified points, the `dodgr_to_sf` function works only with the
# fully contracted graph. This means that the density vertices need to be
# matched to the contracted graph, not the full graph.
net_c <- dodgr_contract_graph (graph = net)$graph
verts <- dodgr_vertices (net_c)
xy_index <- match_pts_to_graph (verts = verts, xy = xy)

od <- dodgr_spatial_interaction (graph = net_c, nodes = xy_index, dens = dens,
                                 k = 2, contract = TRUE)

# Then get and plot flows. Although not necessary here, this also demonstrates
# how to convert the `xy_index` of routing vertices to explicit OSM ID values
# which can also be (more safely) submitted to all dodgr routines.
xy_id <- verts$id [xy_index]
flows <- dodgr_flows (graph = net_c, from = xy_id, to = xy_id, flows = od)
# merge directed flows for plotting only:
flows_merged <- merge_directed_flows (flows)
dodgr_flowmap (flows_merged, file = file.path (here::here(), "fig", "test"))

# or zoom in to verts only (makes no diff here):
#bb <- apply (verts [xy_index, 2:3], 2, range)
#rownames (bb) <- c ("x", "y")
#colnames (bb) <- c ("min", "max")
#dodgr_flowmap (flows, file = file.path (here::here(), "fig", "test"), bbox = bb)

# finally, the sf object corresponding to the flows. Note this requires the full
# network, and will generate an sfc object with exactly the same number of items
# as rows in `net_c`.
sf_xy <- dodgr_to_sf (net)
identical (length (sf_xy), nrow (net_c)) # TRUE!
