# Julia and R spatial library incompatibilities

Hello! Thank you for your interest in this investigation. 

If you're looking for solution [this](#update) is my current best stake of knowledge.

## Goals


- [x] Find a way to run `Circuitscape.jl` via `JuliaCall` and `terra` and/or `sf` in the same R session. (It's magic.R)
- [x] Find a more "solutiony" and less "workaroundy" way to get these to run together. (It's gdal_overrides.R thanks @asinghvi17)

Next steps

- [] Generalize the solution 
- [] Figure otu why magic.R works



## Notes

- This issue impacts both `terra` and `sf` which both wrap `GDAL`. Likely impacts more packages on the julia side as well.
- This issue is probably linux specific.

## Short version

See [run_all.sh](.run_all.sh).

- `julia_first.R` demostrates that after loading `Circuitscape`, using `terra` fails
- `terra_first.R` demostrates that after loading `terra`, loading `Circuitscape` fails
- `magic.R` demostrates that if you first load one of the .so files loaded by `terra` and then attempt to load `Circuitscape` three times, the 3rd attempt succeeds and both packages work fine after that.
- `gdal_overrides.R` Actually fixes the issue (for a particular combo of R-package, julia package, OS) by telling Julia to use gdal and xml2 binaries that c is already using. 


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

## Update

Got a better solution! Had a lovely slack conversation with @asinghvi17 who suggested using Overrides.toml to tell Julia which binaries to use. The julia side on how to do this are documented [here](https://docs.binarybuilder.org/stable/jll/#Non-dev'ed-JLL-packages) and [here](https://pkgdocs.julialang.org/v1/artifacts/). 

tl;dr
- not sure the best way to pre-emptively figure out what overrides you need, but you can trial and error add the ones that show up as "can't find XXX" in the error messages
- the uuid comes from XXX_jl package where XX is the binary that needs to get overridden. This is the uuid of that _jl package itself
- the path is where where the binary (`.so` file) that you want julia to use is located. This will probably be one of the directories in your `LD_LIBRARY` path (run `Sys.getenv('LD_LIBRARY_PATH')`)
- The path in the toml file *must* have a folder named `lib` inside it and the binary should be inside that lib folder. (e.g. if your so file is `/usr/local/lib/XXX.so` you need to just put `/usr/local` in the toml file, not `/usr/local/lib`.) If your binary is in a folder not named lib, you can create a symlink named lib somewhere else and then put the path of that symlink in the toml file. This is what I've done in `gdal_overrides.R` in this repo.
- the `Overrides.toml` file goes in `~/.julia/artifacts`