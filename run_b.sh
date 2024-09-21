#!/bin/bash

if [ "$#" -lt 1 ]; then echo Usage: $0 win; exit; fi

run=$1
win=$2

# Redoing run6. 
i=601 # This is a very good example!
tha= ; thb= ; thc=; thd=;
#win="-126180 3500 -125150 2480"
#win="-126320 3680 -125040 2490"
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i
a=M173635550RE.cal.echo_crop
b=M173642339LE.cal.echo_crop
c=M114594996LE.cal.echo_crop
d=M114588166RE.cal.echo_crop
e=M109869814LE.cal.echo_crop # p1
z=M109863022RE.cal.echo_crop # p2
g=M140577849RE.cal.echo
h=M140584637LE.cal.echo
j=M1116910862LE.cal.echo
k=M1116917960RE.cal.echo

win1="-126046 3447 -125921 3324"
win2="-126102 3454 -125760 3100"
win3="-126281 3072 -125686 2545"
win4="-125779 3540 -125485 3284"
win5="-125764 2885 -125368 2522"
win6="-125461 3560 -125077 3217"

for sm in 0.08 0.06 0.10; do
    for level in 2 3 1; do
	if [ "$win" = "1" ]; then pwin=$win1; fi
	if [ "$win" = "2" ]; then pwin=$win2; fi
	if [ "$win" = "3" ]; then pwin=$win3; fi
	if [ "$win" = "4" ]; then pwin=$win4; fi
	if [ "$win" = "5" ]; then pwin=$win5; fi
	if [ "$win" = "6" ]; then pwin=$win6; fi

	dir=${sfs}_1m_abc_sm${sm}_level${level}_win${win}
	mkdir -p $dir
	gdal_translate -projwin $pwin ${st}/run-1m-DEM.tif $dir/init-DEM.tif

	~/bin/time_run.sh  sfs -i $dir/init-DEM.tif ${a}.cub ${b}.cub ${c}.cub \
	    -o $dir/run \
	    --threads 1 --smoothness-weight $sm  \
	    --max-iterations 100 --reflectance-type 0 --float-exposure        \
	    --float-cameras --use-approx-camera-models --coarse-levels $level
    done
done


