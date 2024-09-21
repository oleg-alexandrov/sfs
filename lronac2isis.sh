#!/bin/bash

f=$1
a=$(echo $f| perl -p -e "s#^.*\/(.*?)\..*?\$#\$1#g")
if [ ! -f $a.IMG ]; then
    echo Fetch: $f
    time wget $f 
fi

echo running lronac2isis.sh from sfs dir

lronac2isis from = $a.IMG to = $a.cub 
spiceinit from = $a.cub 

lronaccal from = $a.cub to = $a.cal.cub

lronacecho from = $a.cal.cub to = $a.cal.echo.cub

mapproject --mpp 50 Lunar_LRO_LOLA_Global_LDEM_118m_Mar2014.tif $a.cal.echo.cub $a.cal.echo.map.tif --tile-size 128  --t_srs '+proj=stere +lat_0=-90 +lat_ts=-90 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs ' 



