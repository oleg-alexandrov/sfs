#f=$(cat list.txt | head -n $1 | tail -n 1)
f=$1

a=$(echo $f| perl -pi -e "s#^.*\/(.*?)\..*?\$#\$1#g");
echo $a; 
if [ ! -f $a.IMG ]; then 
	wget $f 
fi	

if [ ! -f $a.cal.echo.cub ]; then 
    lronac2isis from = $a.IMG to = $a.cub 
    spiceinit from = $a.cub 
    
    lronaccal from = $a.cub to = $a.cal.cub
    
    lronacecho from = $a.cal.cub to = $a.cal.echo.cub

fi

mapproject --mpp 10 run_stereo6_sub10/run-crop-DEM.tif $a.cal.echo.cub $a.cal.echo.map.tif --tile-size 128  --t_srs '+proj=stere +lat_0=-90 +lat_ts=-90 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs ' #  --t_projwin 131770 -91160 132920 -92370
image2qtree.pl $a.cal.echo.map.tif


