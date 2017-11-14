devtools::load_all ()

message ("getting kathmandu streets ... ", appendLF = FALSE)
get_who_streets (city = "kathmandu")
message ("\ndone; getting kathmandu buildings ... ", appendLF = FALSE)
get_who_buildings (city = "kathmandu")

message ("\ndone; getting accra streets ... ", appendLF = FALSE)
get_who_streets (city = "accra")
message ("\ndone; getting accra buildings ... ", appendLF = FALSE)
get_who_buildings (city = "accra")
message ("\ndone")
