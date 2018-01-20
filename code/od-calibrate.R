# aim: Calibrate dodgr_spatial_interaction output against Bristol OD data

library (magrittr)
library (sf)
devtools::install_github("ATFutures/dodgr")
library (dodgr)

trmode <- "foot" # mode of transport to be analysed: "bicycle" or "foot"
trmode <- "bicycle" # mode of transport to be analysed: "bicycle" or "foot"

# load OSM data
bristol_dir <- file.path (here::here(), "..", "who-data", "bristol")
net <- readRDS (file.path (bristol_dir, "osm", "bristol-hw.Rds")) %>%
    weight_streetnet (wt_profile = trmode)
nodes <- readRDS (file.path (bristol_dir, "osm", "nodes_new.Rds"))
verts <- dodgr_vertices (net)

# load OD data
od <- readRDS (file.path (bristol_dir, "l.Rds"))
od_id <- sort (unique (od$o))
identical (od_id, sort (unique (od$d))) # Must be TRUE!
indx <- match (od_id, od$o)
od_xy <- t (sapply (od$geometry [indx], function (i) as.numeric (i [1, ])))

# current bristol OSM data are smaller than the OD data, so cut OD data to size
# of OSM net for the moment:
indx_xy <- which (od_xy [, 1] > min (verts$x) & od_xy [, 1] < max (verts$x) &
                  od_xy [, 2] > min (verts$y) & od_xy [, 2] < max (verts$y))
od_xy <- od_xy [indx_xy, ]

indx <- match_pts_to_graph (verts, od_xy)
dens <- as.numeric (sapply (unique (od$o), function (i)
                sum (od [[trmode]] [which (od$o == i)]))) [indx_xy]
nodes <- verts$id [indx]
# dens is the sum of all origin values in the OD matrix. The dodgr code
# simulates an approximation of these using a spatial interaction model. First
# construct OD in matrix form using only those values within the xy range of
# verts:
od_xy1 <- t (sapply (od$geometry, function (i) as.numeric (i [1, ])))
od_xy2 <- t (sapply (od$geometry, function (i) as.numeric (i [2, ])))
indx_xy <- which (od_xy1 [, 1] > min (verts$x) & od_xy1 [, 1] < max (verts$x) &
                  od_xy1 [, 2] > min (verts$y) & od_xy1 [, 2] < max (verts$y) &
                  od_xy2 [, 1] > min (verts$x) & od_xy2 [, 1] < max (verts$x) &
                  od_xy2 [, 2] > min (verts$y) & od_xy2 [, 2] < max (verts$y))
odmat <- data.frame (o = od$o [indx_xy], d = od$d [indx_xy],
                     dens = od [[trmode]] [indx_xy]) %>%
    reshape2::dcast (o ~ d, value.var = "dens")
odmat$o <- NULL

# construct function to be optimised for calibration through minimising a simple
# mean squared error. Note that self-flows are removed.
f <- function (k) {
    s <- dodgr_spatial_interaction (net, nodes, dens, k = k)
    diag (s) <- NA
    # mod is between log-scaled values, so:
    s [s == 0] <- NA
    mod <- lm (as.vector (log (s)) ~ as.vector (as.matrix (log (odmat))))
    summary (mod)$r.squared
}

# set OD values of 0 to NA to allow log fitting in model. This is also
# appropriate because it reflects the fact that values of 0 are arguably better
# interpreted to reflect innacurate/missing knowledge than actual absence of
# pedestrians/cyclists.
odmat [odmat == 0] <- NA
res <- optimise (f (k) , lower = 0.1, upper = 20, maximum = TRUE, tol = 1e-4)
# The resultant value can then be fed into the following line in the `od-gen`
# script:
#k <- res$maximum
k <- 2.330138 # bicycle
k <- 1.164235 # foot

# correlation between estimated and actual OD mat:
s <- dodgr_spatial_interaction (net, nodes = nodes, dens = dens, k = k)
s [s == 0] <- NA
mod <- lm (as.vector (log (s)) ~ as.vector (as.matrix (log (odmat))))
summary (mod)
# bicycle: R2 = 11.85%; foot: R2 = 45.96


# use that value of `k` to generate the flows:
f <- dodgr_flows(net, id, id, flows = s, contract = T)
dodgr_flowmap(f, "/data/who/flow")
rnet_g <- dodgr_to_sf(net) 
length(rnet_g)
nrow(f)
rnet = st_sf(geometry = rnet_g, f)
