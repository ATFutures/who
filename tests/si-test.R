devtools::install_github("ATFutures/dodgr")
library(dodgr)
library(sf)

# load data
net <- readRDS ("../who-data/accra/osm/accra-hw.Rds") %>% weight_streetnet ()
head(net)
nodes <- readRDS ("../who-data/accra/osm/nodes_new.Rds")
verts <- dodgr_vertices (net)

indx <- 1:100
nodes <- nodes [indx, ]
indx <- match_pts_to_graph (verts, nodes)
dcol <- names (nodes) [which (grepl ("GHA15", names (nodes)))]
dens <- nodes [[dcol]]

# remove duplicated points
dens <- dens [which (!duplicated (indx))]
id <- verts$id [unique (indx)]
indx <- which (!is.na (dens))
id <- id [indx]
dens <- dens [indx]
s <- dodgr_spatial_interaction (net, nodes = id, dens = dens, k = 2)
f = dodgr_flows(graph = net, from = id, to = id, flows = s)

xy = dodgr_to_sf(f[1:999,])
xys = st_sfc(xy)
xysf = st_sf(xys)
plot(xysf)

dodgr_flowmap(f, "/tmp/flow.png")
