library (dodgr)
library (sf)
library (magrittr)
# hard-code dirs for now; this will later be done with the drat archive
pd_dir <- file.path (here::here(), "../popdens")
devtools::load_all (pd_dir, export_all = FALSE)

# If !is.null(n), then sample that number of nodes
get_popdens_nodes <- function (city = "accra", n = NULL)
{
    data_dir <- file.path (here::here(), "../who-data")
    nodes <- readRDS (file.path (data_dir, city, "osm", "nodes_new.Rds"))
    if (!is.null (n))
    {
        indx <- sample (sequence (nrow (nodes)), size = n)
        nodes <- nodes [indx, ]
    }
    return (nodes)
}
nodes <- get_popdens_nodes ("accra", n = 1000)

get_od_matrix <- function (net, nodes)
{
    dens <- nodes$pop
    x <- lapply (nodes$geometry, function (i) i [1]) %>%
        unlist () %>% as.numeric ()
    y <- lapply (nodes$geometry, function (i) i [2]) %>%
        unlist () %>% as.numeric ()
    xy <- data.frame (x = x, y = y)
    xy_index <- match_pts_to_graph (verts = dodgr_vertices (net), xy = xy)

    od <- dodgr_spatial_interaction (graph = net, nodes = xy_index, dens = dens,
                                     k = 2, contract = TRUE)
    list (index = xy_index, od = od)
}
transport <- "bicycle" # for weighting profile
data_dir <- file.path (here::here(), "../who-data")
net <- readRDS (file.path (data_dir, "accra", "osm", "accra-hw.Rds")) %>%
    weight_streetnet (wt_profile = transport)
od <- get_od_matrix (net, nodes)

get_flows <- function (net, od, filename = NULL)
{
    flows <- dodgr_flows (graph = net, from = od$index, to = od$index,
                          flows = od$od)
    if (!is.null (filename)) # dump plot
    {
        flows_merged <- merge_directed_flows (flows)
        dodgr_flowmap (flows_merged,
                       file = file.path (here::here(), "fig", filename))
    }
    return (flows)
}
flows <- get_flows (net, od)

match_to_sf <- function (flows, finite = TRUE)
{
    gc <- dodgr_contract_graph (flows)$graph
    sf_xy <- dodgr_to_sf (flows) %>% sf::st_sf ()
    sf_xy [names (gc)] <- gc
    if (finite) # remove zero flows
        sf_xy <- sf_xy [which (sf_xy$flow > 0), ]
    return (sf_xy)
}
flows <- match_to_sf (flows, finite = TRUE)
