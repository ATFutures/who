.onAttach <- function(libname, pkgname) {
    if (packageVersion ("osmdata") < '0.0.5.100')
        packageStartupMessage ("who requires osmdata >= 0.0.5.100; ",
                               "please update to latest dev version")
}
