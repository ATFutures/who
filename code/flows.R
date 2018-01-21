library (dodgr)
library (sf)
library (magrittr)
# hard-code dirs for now; this will later be done with the drat archive
city = "kathmandu"
pd_dir <- file.path (here::here(), "../popdens")
devtools::load_all (pd_dir, export_all = FALSE)

# If !is.null(n), then sample that number of nodes
get_popdens_nodes <- function (city = city, n = NULL)
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
nodes <- get_popdens_nodes (city, n = 1000)

get_od_matrix <- function (net, nodes)
{
    dens <- nodes$pop
    x <- lapply (nodes$geometry, function (i) i [1]) %>%
        unlist () %>% as.numeric ()
    y <- lapply (nodes$geometry, function (i) i [2]) %>%
        unlist () %>% as.numeric ()
    xy <- data.frame (x = x, y = y)
    verts <- dodgr_vertices (net)
    xy_index <- match_pts_to_graph (verts = verts, xy = xy)
    nodes <- verts$id [xy_index]

    od <- dodgr_spatial_interaction (graph = net, nodes = nodes, dens = dens,
                                     k = 2.33, contract = TRUE)
    list (index = xy_index, od = od)
}
transport <- "bicycle" # for weighting profile
data_dir <- file.path (here::here(), "../who-data")
net <- readRDS (file.path (data_dir, city, "osm", paste0(city, "-hw.Rds"))) %>%
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
saveRDS (flows, file = "accra-flows.Rds")

# --------- Merge directed flows and convert to sf geometries
library (sf) # has to be in namespace for this to work
graph <- readRDS ("accra-flows.Rds")
graph_sf <- dodgr_to_sf (graph)
gc <- dodgr_contract_graph (graph)
graphm <- merge_directed_flows (gc$graph)
indx <- match (graphm$edge_id, names (graph_sf))
graph_sf <- graph_sf [indx]
# graph_sf then has the geometries and graphm the associated data

# --------- interactive plot with mapview
library (mapview)
ncols <- 30
flow <- graphm$flow / max (graphm$flow)
cols <- colorRampPalette (c ("lawngreen", "red")) (ncols) [ceiling (ncols * flow)]
mapview (graph_sf, color = cols, lwd = 10 * flow)

# --------- interactive plot with tmap:
# requires construction of full sf data.frame
sf_xy <- graph_sf %>% sf::st_sf ()
sf_xy [names (graphm)] <- graphm
library (tmap)
tmap_mode("view")
tm_shape(sf_xy) +
  tm_lines(col = "flow", lwd = "flow", scale = 20, alpha = 0.8,
           palette = viridis::viridis(n=5, direction = -1,option = "C"), breaks = c(0, 500, 1000, 2000)) +
  tm_scale_bar()

# --------- static plot with ggmap - slow and looks crap!
library (ggmap)
linescale <- 5
fmax <- max (graphm$flow)
graphm$flow <- linescale * graphm$flow / fmax
verts <- dodgr_vertices (graphm)
map <- get_map (location = c (mean (verts$x), mean (verts$y)), zoom = 12) %>%
    ggmap ()
map <- map +
    ggplot2::geom_segment (ggplot2::aes (x = from_lon, y = from_lat,
                                         xend = to_lon, yend = to_lat,
                                         colour = flow, size = flow),
                           size = graphm$flow, data = graphm) +
    ggplot2::scale_colour_gradient (low = "lawngreen", high = "red",
                                guide = "none",
                                limits = c (0, max (graphm$flow)))
ggsave (map, file = "accra-flowmap.png")

# --------- static plot with mapshot basemap - supremely quick, but does not
# align properly, so is tweaked here with a crappy manual fix
plotmapshot <- function (graph, graph_sf, expand = 0.5, dark = TRUE)
{
    bb <- sf::st_bbox (graph_sf)
    if (dark)
        m <- mapview (bb, lwd = 0, col.regions = NA, alpha = 0)
    else
        m <- mapview (bb, lwd = 0, alpha = 0)
    mapshot (m, file = "accra-bg.png")
    img <- png::readPNG ("accra-bg.png")
    xlims <- c (bb [1], bb [3])
    ylims <- c (bb [2], bb [4])
    xlims <- xlims + c (-expand, expand) * diff (xlims)
    ylims <- ylims + c (-expand, expand) * diff (ylims)
    plot (NULL, xlim = xlims, ylim = ylims, xlab = "lon", ylab = "lat")
    # fill to plot limits
    lim <- par ()$usr
    rasterImage (img, lim [1], lim [3], lim [2], lim [4])

    graph0 <- graph [which (graph$flow > 0), ]
    graph0$flow <- graph0$flow / max (graph0$flow)
    ncols <- 30
    cols <- colorRampPalette (c ("lawngreen", "red")) (ncols)
    cols <- cols [ceiling (graph0$flow * ncols)]

    #plot (NULL, xlim = xlims, ylim = ylims, xlab = "lon", ylab = "lat")
    with (graph0, segments (from_lon, from_lat, to_lon, to_lat,
                            col = cols, lwd = 10 * graph0$flow))
}
plotmapshot (graph, graph_sf, 0.5)

