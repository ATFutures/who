#' get_who_streets
#'
#' Extract OSM streets for given location (\code{city}), and save them in the
#' data directory
#' @param city Name of city for which streets are to be obtained
#' @return The \pkg{sf}-formatted data object (invisibly)
#'
#' @export
get_who_streets <- function (city = "kathmandu")
{
    region_shape <- getbb(place_name = city, format_out = "polygon")
    if (is.list (region_shape))
        region_shape <- region_shape [[1]]

    dat <- osmdata::opq (bbox = city) %>%
        osmdata::add_osm_feature (key = "highway") %>%
        osmdata::osmdata_sf (quiet = FALSE) %>%
        osmdata::trim_osmdata (region_shape) %>%
        osmdata::osm_poly2line () %>%
        magrittr::extract2 ("osm_lines")

    # Reduce to only fields with > 1 unique value
    n <- apply (dat, 2, function (i) length (unique (i)))
    dat <- dat [, which (n > 1)]

    write_who_data (dat, city = city, suffix = "hw")

    invisible (dat)
}

#' get_who_buildings
#'
#' Extract OSM buildings for given location (\code{city}), and save them in the
#' data directory
#' @param city Name of city for which buildings are to be obtained
#' @return The \pkg{sf}-formatted data object (invisibly)
#'
#' @export
get_who_buildings <- function (city = "kathmandu")
{
    region_shape <- getbb(place_name = city, format_out = "polygon")
    if (is.list (region_shape))
        region_shape <- region_shape [[1]]

    dat <- osmdata::opq (bbox = city) %>%
        osmdata::add_osm_feature (key = "building") %>%
        osmdata::osmdata_sf (quiet = FALSE) %>%
        osmdata::trim_osmdata (region_shape)

    # Reduce to only fields with > 1 unique value
    n <- apply (dat$osm_polygons, 2, function (i) length (unique (i)))
    dat$osm_polygons <- dat$osm_polygons [, which (n > 1)]
    n <- apply (dat$osm_multipolygons, 2, function (i) length (unique (i)))
    dat$osm_multipolygons <- dat$osm_multipolygons [, which (n > 1)]

    dat$osm_points <- dat$osm_lines <- dat$osm_multilines <- NULL

    write_who_data (dat, city = city, suffix = "bldg")

    invisible (dat)
}

write_who_data <- function (dat, city, suffix)
{
    nm <- paste0 (city, "_", suffix)
    assign (nm, dat)
    data_dir <- get_who_data_dir (city = city)
    fname <- file.path (data_dir, paste0 (city, "-", suffix, ".Rds"))
    saveRDS (get (nm), fname)
    message ("saved ", fname)
}

#' get_who_data_dir
#'
#' Find the "who-data" directory corresponding to the "who" directory of this
#' project, and the sub-directory within that corresponding to the named city.
#' The sub-dir will be created if it does not already exist.
#'
#' @param city Name of city for which data are obtained, and name of
#' corresponding sub-directory in "who-data" where data are to be stored.
#'
#' This assumes this repo ("who") sits in the same root directory as the
#' corresponding one named "who-data". The latter is where the function
#' \code{get_who_data} stores data.
#' @noRd
get_who_data_dir <- function (city)
{
    # NOTE: The substring command may not be platform independent, but will work
    # on linux
    dh <- substring (here::here (), 1, nchar (here::here()) - 4) %>%
        file.path ("who-data")
    if (!file.exists (dh))
        stop ("Directory who-data not found")

    dh <- file.path (dh, city)
    if (!file.exists (dh))
        dir.create (dh)

    return (dh)
}
