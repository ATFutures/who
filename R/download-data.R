#' get_who_streets
#'
#' Extract OSM streets for given location (\code{city}), and save them in the
#' data directory
#'
#' @param city Name of city for which streets are to be obtained
#' @param n Number of chunks into which to divide the file (see details)
#' @return The \pkg{sf}-formatted data object (invisibly)
#'
#' @note github only stores single files under 5MB, so setting n > 1 enables a
#' file to be divided into individual chunks smaller than this limit which can
#' be stored and easily \code{rbind}-ed back together on loading.
#'
#' @export
get_who_streets <- function (city = "kathmandu", n = 1)
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
    len <- apply (dat, 2, function (i) length (unique (i)))
    dat <- dat [, which (len > 1)]

    indx <- seq (nrow (dat))
    if (n == 1)
        indx <- list (indx)
    else
        indx <- split (indx, cut (indx, n))

    np <- file_number_ext (n)

    for (i in seq (indx))
    {
        write_who_data (dat [indx [[i]], ], city = city, suffix = "hw",
                        n = np [i])
    }

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
get_who_buildings <- function (city = "kathmandu", n = 2)
{
    region_shape <- getbb(place_name = city, format_out = "polygon")
    if (is.list (region_shape))
        region_shape <- region_shape [[1]]

    dat <- osmdata::opq (bbox = city) %>%
        osmdata::add_osm_feature (key = "building") %>%
        osmdata::osmdata_sf (quiet = FALSE) %>%
        osmdata::trim_osmdata (region_shape)

    dat$osm_points <- dat$osm_lines <- dat$osm_multilines <- NULL

    # Reduce to only fields with > 1 unique value
    len <- apply (dat$osm_polygons, 2, function (i) length (unique (i)))
    dat$osm_polygons <- dat$osm_polygons [, which (len > 1)]
    len <- apply (dat$osm_multipolygons, 2, function (i) length (unique (i)))
    dat$osm_multipolygons <- dat$osm_multipolygons [, which (len > 1)]

    indx1 <- seq (nrow (dat$osm_polygons))
    indx2 <- seq (nrow (dat$osm_multipolygons))
    if (n == 1)
    {
        indx1 <- list (indx1)
        indx2 <- list (indx2)
    } else
    {
        indx1 <- split (indx1, cut (indx1, n))
        indx2 <- split (indx2, cut (indx2, n))
    }

    np <- file_number_ext (n)

    dat_full <- dat
    for (i in seq (n))
    {
        dat <- dat_full
        dat$osm_polygons <- dat$osm_polygons [indx1 [[i]], ]
        dat$osm_multipolygons <- dat$osm_multipolygons [indx2 [[i]], ]
        write_who_data (dat, city = city, suffix = "bldg", n = np [i])
    }

    invisible (dat_full)
}

# n is a number appended to file name when divided into chunks
write_who_data <- function (dat, city, suffix, n = NULL)
{
    nm <- paste0 (city, "_", suffix, n)
    assign (nm, dat)
    data_dir <- get_who_data_dir (city = city)
    fname <- file.path (data_dir, paste0 (city, "-", suffix, n, ".Rds"))
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

# convert a range number into a series of 0-padded file number extensions
file_number_ext <- function (n)
{
    np <- ""
    if (n > 1)
    {
        np <- sapply (seq (n), function (i)
                      formatC (i, width = ceiling (log10 (n + 1)), flag = "0"))
    }
    return (np)
}
