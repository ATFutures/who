library (dodgr)
library (magrittr)

count_streets <- function (city = "accra")
{
    transport <- "bicycle" # for weighting profile
    data_dir <- file.path (here::here(), "../who-data")
    fname <- paste0 (city, "-hw.Rds")
    net <- readRDS (file.path (data_dir, city, "osm", fname)) %>%
        weight_streetnet (wt_profile = transport)
    verts <- dodgr_vertices (net)
    # distance can only be measured by reducing bi-direcitonal links to single
    # non-directed equivalents. The `merge_directed_flows` function does this,
    # but also drops all edges with flow = 0, so:
    net$flow <- 1
    net <- merge_directed_flows (net)
    message ("Network has ", format (nrow (verts), big.mark = ","),
             " vertices and ", format (nrow (net), big.mark = ","),
             " edges for ", format (round (sum (net$d)), big.mark = ","),
             "km of streets")
}

count_buildings <- function (city = "accra")
{
    # ignore multipolygon buildings here
    data_dir <- file.path (here::here(), "../who-data")
    fname <- paste0 (city, "-bldg.Rds") %>%
        file.path (data_dir, city, "osm", .)
    if (!file.exists (fname))
    {
        i <- 1
        f1 <- paste0 (city, "-bldg", i, ".Rds") %>%
            file.path (data_dir, city, "osm", .)
        fname <- NULL
        while (file.exists (f1))
        {
            fname <- c (fname, f1)
            i <- i + 1
            f1 <- paste0 (city, "-bldg", i, ".Rds") %>%
                file.path (data_dir, city, "osm", .)
        }
    }
    nbuildings <- nno_description <- 0
    tb <- NULL
    for (f in fname)
    {
        dat <- readRDS (f) %>% extract2 ("osm_polygons")
        nbuildings <- nbuildings + nrow (dat)
        nno_description  <- nno_description + length (which (dat$building == "yes"))
        tb <- c (tb, unique (dat$building))
    }
    message ("There are ", format (nbuildings, big.mark = ","),
             " buildings of which ",
             format (nno_description, big.mark = ","),
             " have no description and the remaining ",
             format (nbuildings - nno_description, big.mark = ","),
             " are divded between ", length (tb) - 1,
             " distinct building types (including building names)")
}

count_popdens_nodes <- function (city = "accra")
{
    data_dir <- file.path (here::here(), "../who-data")
    nodes <- readRDS (file.path (data_dir, city, "osm", "nodes_new.Rds"))
    message ("Population density contains values for ",
             format (nrow (nodes), big.mark = ","), " points")
}
