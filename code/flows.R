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
# match xy to network:
verts <- dodgr_vertices (net)
xy_index <- match_pts_to_graph (verts = verts, xy = xy)
#xy_id <- verts$id [xy_index]

od <- dodgr_spatial_interaction (graph = net, nodes = xy_index, dens = dens,
                                 k = 2, contract = TRUE)

# Then get and plot flows
flows <- dodgr_flows (graph = net, from = xy_index, to = xy_index, flows = od) %>%
    merge_directed_flows ()
dodgr_flowmap (flows, file = file.path (here::here(), "fig", "test"))

# or zoom in to verts only (makes no diff here):
#bb <- apply (verts [xy_index, 2:3], 2, range)
#rownames (bb) <- c ("x", "y")
#colnames (bb) <- c ("min", "max")
#dodgr_flowmap (flows, file = file.path (here::here(), "fig", "test"), bbox = bb)
