#' get_who_data
#'
#' Extract OSM data for given location (\code{city}), and save it in the data
#' directory
#' @param city Name of city for which data are to be obtained
#' @param key List of OSM keys
#' @param value List of corresponding OSM values
#' @return The \pkg{sf}-formatted data object (invisibly)
#'
#' @note \code{value} must either be \code{NULL}, or have the same length as
#' \code{key}. To return all values for one particular \code{key} from a vector,
#' set corresponding \code{value = ""}.
#'
#' @export
get_who_data <- function (city = "kathmandu", key = NULL, value = NULL)
{
    region_shape <- getbb(place_name = city, format_out = "polygon")
    if (is.list (region_shape))
        region_shape <- region_shape [[1]]

    if (length (key) == 1 & is.null (value))
        value <- ""
    else if (length (key) != length (value))
        stop ("value must have same length as key")

    q <- opq (bbox = city)
    for (i in seq (key))
        q <- add_osm_feature (q, key = key [i], value = value [i])

    dat <- osmdata_sf (q) %>% trim_osmdata (region_shape)

    nm <- paste0 (city, "_", key [1])
    assign (nm, dat)
    data_dir <- get_who_data_dir (city = city)
    fname <- file.path (data_dir, paste0 (city, "-", value))
    if (value [1] != "")
        fname <- paste0 (fname, "-", key)
    fname <- paste0 (fname, ".Rds")
    saveRDS (get (nm), fname)
    message ("saved ", fname)

    invisible (dat)
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
