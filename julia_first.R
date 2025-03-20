JuliaCall::julia_setup()
JuliaCall::julia_library('Circuitscape')

# TEST TERRA: load a raster
terra::rast(system.file("ex/elev.tif", package="terra"))
# FAILS