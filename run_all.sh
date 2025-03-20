docker build . -t juli-sliprs

docker run juli-sliprs julia_first.R 2> julia_first.log
docker run juli-sliprs terra_first.R 2> terra_first.log
docker run juli-sliprs magic.R > magic.log 2>&1 
