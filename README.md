# Julia and R spatial library incompatibilities

Hello! Thank you for your interest in this investigation. 

## Goals

- [x] Find a way to run `Circuitscape.jl` via `JuliaCall` and `terra` and/or `sf` in the same R session. (It's magic.R)
- [ ] Figure out the root cause...or at least the exactly what program or package is to blame so that it can be raised to the appropariate developers.

btw - This issue impacts both `terra` and `sf` which both wrap `GDAL`. Likely impacts more packages on the julia side as well.

## Short version

See [run_all.sh](.run_all.sh).

- `julia_first.R` demostrates that after loading `Circuitscape`, using `terra` fails
- `terra_first.R` demostrates that after loading `terra`, loading `Circuitscape` fails
- `magic.R` demostrates that if you first load one of the .so files loaded by `terra` and then attempt to load `Circuitscape` three times, the 3rd attempt succeeds and both packages work fine after that.


## Long version

An attempt to use [Circuitscape.jl](https://github.com/Circuitscape/Circuitscape.jl) is the proverbial tornado that brought me this land, but I think there are similar compatibility with other spatial libraries.

"You Should be able to call Circuitscape from R by using the JuliaCall R package." States the documentation. Makes sense to me!

Indeed it does... Once I've worked around [this issue](https://github.com/JuliaInterop/JuliaCall/issues/238) (doesn't impact the dockerfile), the following works splendedly:
```{r}
# Set everything up
JuliaCall::julia_setup()
JuliaCall::julia_install_package('Circuitscape')
JuliaCall::julia_library('Circuitscape')

# Dig into the package files to get to the tests
JuliaCall::julia_eval('cd(joinpath(dirname(pathof(Circuitscape)), "../test"))')

# Run an example
JuliaCall::julia_call('compute', 'input/network/mgNetworkVerify1.ini')
```

Works great! So now lets plot the results...trying to load up the trusty old [`terra` package](https://rspatial.github.io/terra/reference/terra-package.html), and I'm met with:

```
Error in dyn.load(file, DLLpath = DLLpath, ...) : 
  unable to load shared object '/usr/local/lib/R/site-library/terra/libs/terra.so':
  /usr/lib/x86_64-linux-gnu/libspatialite.so.8: undefined symbol: xmlNanoHTTPCleanup, version LIBXML2_2.4.30
Calls: loadNamespace -> library.dynam -> dyn.load
Execution halted
```

hmm...new R session, `library(terra)` first (now that runs without error at least..), then try `JuliaCall::julia_setup(); JuliaCall::julia_library('Circuitscape')` results in:

```
Error: Error happens in Julia.
InitError: could not load library "/root/.julia/artifacts/94430821ebeeac5f4e438c79b541c0e5408e74de/lib/libgdal.so"
/usr/lib/x86_64-linux-gnu/libtiff.so.6: version `LIBTIFF_4.6.1' not found (required by /root/.julia/artifacts/94430821ebeeac5f4e438c79b541c0e5408e74de/lib/libgdal.so)
Stacktrace:
  [1] dlopen(s::String, flags::UInt32; throw_error::Bool)
    @ Base.Libc.Libdl ./libdl.jl:117
  [2] dlopen(s::String, flags::UInt32)
    @ Base.Libc.Libdl ./libdl.jl:116
  [3] macro expansion
    @ ~/.julia/packages/JLLWrappers/GfYNv/src/products/library_generators.jl:63 [inlined]
  [4] __init__()
    @ GDAL_jll ~/.julia/packages/GDAL_jll/fyGA8/src/wrappers/x86_64-linux-gnu-cxx11.jl:78
  [5] register_restored_modules(sv::Core.SimpleVector, pkg::Base.PkgId, path::String)
    @ Base ./loading.jl:1115
  [6] _include_from_serialized(pkg::Base.PkgId, path::String, ocachepath::String, depmods::Vector{Any})
    @ Base ./loading.jl:1061
  [7] _require_search_from_serialized
Execution halted
```

Also...unloading the R library that was loaded first does not solve the problem so I couldn't find a way to cleanly switch a session from the state where `terra` is working to the state where `Circuitscape` is working and vice versa...so the only thing to do would be to close R and re-open fresh to switch between these two libraries.

Turns out I'm not the only one to have come down this brick road:
- [Similar Problem with terra and GeoArrays](https://stackoverflow.com/questions/78865514/)
- [Similar Problem with ResistanceGA and Circuitscape](https://discourse.julialang.org/t/julia-can-not-find-libtiff-r-4-4-0-julia-1-9-3-when-running-resistancega-in-r/124291)

After spending many hours (mostly fruitlessly) trying to understand how library linking works and how it interacts with R and Julia, I looked down at my console and saw both libraries working! It didn't quite make sense because all I did in that session was basicall load the two incompatible libraries over and over in different orders. Somehow that worked. I distilled the reproduceable workaround down as much as I good, which is what you'll find in `magic.R`. Basically, load the rgdal c(pp?) library, then make three attempts to load `Circuitscape`. Magically the 3rd one works and you can use it alongside R spatial packages like `sf` and `terra` to your hearts content.

But whyyyy?? What exactly is the library that both need and what versions do each need? Or is it just some kind LD_PATH related problem? Why does this magical combination work? Is there any way to make it work on the first try?

I'm hoping for a lovely good witch who understand the c(pp) and/or julia sides better than I do to teach me her ways.
