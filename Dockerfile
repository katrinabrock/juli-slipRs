FROM rocker/r-ver:4

RUN apt update \
    && apt install -y --no-install-recommends \
    libpng-dev \
    libcurl4-openssl-dev \
    pandoc \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    && rm -rf /var/lib/apt/lists/* 

RUN install2.r --error --ncpus -1 \
    #dplyr \
    #ggplot2 \
    JuliaCall \
    #markdown \
    #move2 \
    #pandoc \
    #pkgload \
    #maptiles \
    #readr \
    #remotes \
    #reticulate \
    #rmarkdown \
    terra \
    #tidyterra \
    #xaringanExtra \
    sf \
    && rm -rf /tmp/downloaded_packages \
    && strip /usr/local/lib/R/site-library/*/libs/*.so



RUN ["R", "-e", "JuliaCall::install_julia(); JuliaCall::julia_setup(); JuliaCall::julia_install_package('Circuitscape')"]


ADD terra_first.R /opt/terra_first.R
ADD julia_first.R /opt/julia_first.R
ADD magic.R /opt/magic.R

WORKDIR /opt

ENTRYPOINT [ "Rscript" ]