# Create a symlink with the directory name "lib" to the  location 
# of the binaries we want julia to use
file.symlink('/usr/lib/x86_64-linux-gnu', '/root/.local/lib')

# Tell Julia about it
cat('[a7073274-a066-55f0-b90d-d619367d196c]
GDAL = "/root/.local"

[02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a]
XML2 = "/root/.local"
', file = '/root/.julia/artifacts/Overrides.toml')

# terra first flow , load terra
loadNamespace('terra')
# Julia setup
JuliaCall::julia_setup()

# TEST CIRCUITSCAPE: Navigate to Circuitscape test directory and run a test scenario
JuliaCall::julia_library('Circuitscape')
JuliaCall::julia_eval('cd(joinpath(dirname(pathof(Circuitscape)), "../test"))')
JuliaCall::julia_call('compute', 'input/network/mgNetworkVerify1.ini')

# TEST TERRA: load a raster
terra::rast(system.file("ex/elev.tif", package="terra"))




