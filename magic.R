try_julia_library <-  function(pkg) tryCatch(
  {JuliaCall::julia_library(pkg); return(TRUE)}, # fails tiff not found 
  error = function(e) FALSE
)

click_heels_3x <- function(pkg){
  dyn.load("/usr/lib/x86_64-linux-gnu/libgdal.so") # OR loadNamespace('terra') OR loadNamespace('sf')
  c(
    try_julia_library(pkg), # fails
    try_julia_library(pkg), # fails
    try_julia_library(pkg) # succeeds
  )
}

JuliaCall::julia_setup()
click_heels_3x('Circuitscape')

# TEST TERRA: load a raster
terra::rast(system.file("ex/elev.tif", package="terra"))
# SUCCESS

# TEST CIRCUITSCAPE: Navigate to Circuitscape test directory and run a test scenario
JuliaCall::julia_eval('cd(joinpath(dirname(pathof(Circuitscape)), "../test"))')
JuliaCall::julia_call('compute', 'input/network/mgNetworkVerify1.ini')
# SUCCESS