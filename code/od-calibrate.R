# aim: Calibrate dodgr_spatial_interaction output against Bristol OD data

# generate OD flows
net <- readRDS ("../who-data/bristol/osm/bristol-hw.Rds") %>% weight_streetnet ()
nodes <- readRDS ("../who-data/bristol/osm/nodes_new.Rds")
verts <- dodgr_vertices (net)

library (sf)
indx <- 1:1000
# indx should actually be the OD points matched to the street network using
# `match_pts_to_graph`, but pretend here that that's just the first 1,000 points
# Note that this whole routine presumes that the OD matrix is square and has the
# same origin and destination points. This can be changed, but will require some
# C++ re-coding.
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

# construct function to be optimised for calibration. The above `indx` should
# index the full set of origin and destination points (because these are
# presumed to be the same), so `dodgr_spatial_interaction` will return an
# estimate of the OD matrix. The optimiser will minimise a simple mean squared
# error,
f <- function (k = 2, net, nodes, dens, odmat)
{
    s <- dodgr_spatial_interaction (net, nodes = nodes, dens = dens, k = k)
    sum ((odmat - s) ^ 2
}

# set a very rough tolerance here. It might also be necessary to fiddle with
# lower and upper bounds a bit.
res <- optimise (f, lower = 0.1, upper = 10, maximum = FALSE, tol = 1e-4)
res$objective # should give the calibrated value

# The resultant value can then be fed into the following line in the `od-gen`
# script:
k <- res$objective # i think?

# use that value of `k` to generate the flows:
s <- dodgr_spatial_interaction (net, nodes = id, dens = dens, k = k)
f <- dodgr_flows(net, id, id, flows = s, contract = T)
dodgr_flowmap(f, "/data/who/flow")
rnet_g <- dodgr_to_sf(net) 
length(rnet_g)
nrow(f)
rnet = st_sf(geometry = rnet_g, f)
