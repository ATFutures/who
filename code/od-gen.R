# generate OD flows
net <- readRDS ("../who-data/accra/osm/accra-hw.Rds") %>% weight_streetnet ()
nodes <- readRDS ("../who-data/accra/osm/nodes_new.Rds")
verts <- dodgr_vertices (net)

library (sf)
indx <- 1:1000
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
f <- dodgr_flows(net, id, id, flows = s, contract = T)
dodgr_flowmap(f, "/data/who/flow")
rnet_g <- dodgr_to_sf(net) 
length(rnet_g)
nrow(f)
rnet = st_sf(geometry = rnet_g, f)
