#!/bin/bash

if [ "$#" -lt 1 ]; then echo Usage: $0 win; exit; fi

id=$1
crop=$2

if [ 1 -eq 0 ]; then 
tile=$1 # fix
w=10    # fix
crop=1
threads=1 # fix
do_ba=1

if [ "$tile" -le 9 ]; then tile="0$tile"; fi;
echo Tile is $tile

run=7
#win="-126043 3438 -125910 3310"

echo Run is $run
echo Win is $win
# 1 level with 0.06 works best.

# Redoing run6. 
i=601 # This is a very good example!
#tha= ; thb= ; thc=; thd=;
#win="-126180 3500 -125150 2480"
#win="-126320 3680 -125040 2490"
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i
a=M173635550RE.cal.echo_crop; b=M173642339LE.cal.echo_crop; c=M114594996LE.cal.echo_crop; d=M114588166RE.cal.echo_crop; e=M109869814LE.cal.echo_crop; z=M109863022RE.cal.echo_crop; g=M140577849RE.cal.echo; h=M140584637LE.cal.echo; j=M1116910862LE.cal.echo; k=M1116917960RE.cal.echo

#win1="-126046 3447 -125921 3324"
#win2="-126102 3454 -125760 3100"
#win3="-126281 3072 -125686 2545"
#win4="-125779 3540 -125485 3284"
#win5="-125764 2885 -125368 2522"
#win6="-125461 3560 -125077 3217"
#win7="-125840 3439 -125097 2819"
#for sm in 0.08 0.06 0.10; do
#for level in 2 3 1; do

win1="-126244 3263 -126078 3098"
win2="-126309 3304 -126135 3136"
win3="-126302 3251 -126130 3095"
win4="-126244 3290 -126072 3122"
win5="-126142 3331 -125976 3158"
win6="-126122 3238 -125967 3084"
win7="-126096 3450 -125895 3254" # big
win8="-126236 3244 -126136 3143" # small
win9="-118383 4267 -117702 3666"
win10="-118222 4158 -117942 3862"

if [ "$run" = "1" ];  then q=$e; r=$z; s=$c; t=""; fi
if [ "$run" = "2" ];  then q=$e; r=$z; s=$d; t=""; fi
if [ "$run" = "3" ];  then q=$e; r=$z; s=$j; t=""; fi
if [ "$run" = "4" ];  then q=$e; r=$z; s=$k; t=""; fi
if [ "$run" = "5" ];  then q=$e; r=$z; s=$g; t=""; fi
if [ "$run" = "6" ];  then q=$e; r=$z; s=$h; t=""; fi
if [ "$run" = "7" ];  then q=$e; r=$z; s=$c; t=$d.cub; fi
if [ "$run" = "8" ];  then q=$e; r=$z; s=$j; t=$k.cub; fi
if [ "$run" = "9" ];  then q=$e; r=$z; s=$g; t=$h.cub; fi
if [ "$run" = "10" ]; then q=$e; r=$z; s=$c; t=$k.cub; fi
if [ "$run" = "11" ]; then q=$e; r=$z; s=$d; t=$j.cub; fi

#if [ "$run" = "2" ]; then q=$a; r=$b; s=$c; t=$d.cub; fi
#if [ "$run" = "3" ]; then q=$c; r=$d; s=$e; t=$z.cub; fi
#if [ "$run" = "4" ]; then q=$j; r=$h; s=$j; t=$k.cub; fi
#if [ "$run" = "5" ]; then q=$e; r=$z; s=$c; t=$d.cub; fi
#if [ "$run" = "6" ]; then q=$e; r=$z; s=$j; t=$k.cub; fi
#if [ "$run" = "7" ]; then q=$a; r=$b; s=$j; t=$k.cub; fi
# if [ "$run" = "5" ]; then q=$g; fi
# if [ "$run" = "6" ]; then q=$h; fi
# if [ "$run" = "7" ]; then q=$j; fi
# if [ "$run" = "8" ]; then q=$k; fi


#point2dem -r moon --tr 1 --stereographic --proj-lon 0 --proj-lat -90 ${st}/run-PC.tif -o  ${st}/run-1m


stereo $a.cub $b.cub run7_subpix1/run 
point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon -88.572434 --proj-lat -85.832098 run7_subpix1/run-PC.tif

f=$k; mapproject --tr 1 run7_subpix1/run-DEM.tif $f.cub $f.map.tr1.tif --t_projwin -1992 2035 2158 -2000 --tile-size 512
bundle_adjust $a.cub $b.cub $d.cub $k.cub --mapprojected-data "$a.map.tr1.tif $b.map.tr1.tif $d.map.tr1.tif $k.map.tr1.tif run7_subpix1/run-DEM.tif" -o run7_ba_manual/run --min-matches 1
stereo $a.cub $b.cub run7_subpix3/run --bundle-adjust-prefix run7_ba_manual/run --subpixel-mode 3
point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon -88.572434 --proj-lat -85.832098 run7_subpix3/run-PC.tif

pc_align run7_subpix3/run-DEM.tif RDR_270E273E_87S85SPointPerRow_csv_table.csv --max-displacement 100 -o run7_subpix3/run --save-transformed-source-points

pc_align run7_subpix3/run-crop1-DEM.tif RDR_270E273E_87S85SPointPerRow_csv_table.csv --max-displacement 100 -o run7_subpix3/run --save-transformed-source-points 

point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon -88.572434 --proj-lat -85.832098 run7_subpix3/run-trans_source.csv


#level=4
level=0 # fix
sm=0.06
#sm=0.12

if [ "$do_ba" = "1" ]; then
    echo do_ba is $do_ba 1
    opt="--bundle-adjust-prefix run_ezcd_ba/run"
else
    echo do_ba is $do_ba 0
    opt=""
fi
echo opt is $opt

if [ "$crop" = "1" ]; then
    echo crop is $crop 1
    opt_crop="--crop-input-images"
else
    echo crop is $crop 0
    opt_crop=""
fi
echo opt_crop is $opt_crop

# Init DEM coords
#Upper Left  ( -118383.500,    4267.500) 
#Lower Right ( -117702.500,    3666.500) 

#stereo --bundle-adjust-prefix run_ezcd_ba/run --subpixel-mode 3 --threads 32 --corr-seed-mode 1 --stereo-file ./stereo.default --tif-compress LZW M109869814LE.cal.echo_crop.cub M109863022RE.cal.echo_crop.cub run_ezcd/run
# pc_align --max-displacement 200 run_ezcd/run-DEM.tif RDR_270E272E_87p2398S85SPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km' --save-inv-transformed-reference-points -o run_ezcd/run-align-lola --save-transformed-source-points
#  gdt -srcwin 16471 593 1458 1161 run_ezcd/run-DEM.tif run_ezcd/run-crop-DEM.tif
# tile.pl run_ezcd/run-crop-DEM.tif 200 run_ezcd 30
# sfs -i sfs601_run7_level4_tile01_ref0_w9_ba1_crop1_th4_ezcd_sm0.06/init-DEM.tif M109869814LE.cal.echo_crop.cub M109863022RE.cal.echo_crop.cub M114594996LE.cal.echo_crop.cub M114588166RE.cal.echo_crop.cub -o sfs601_run7_level4_tile01_ref0_w9_ba1_crop1_th4_ezcd_sm0.06/run --threads 4 --smoothness-weight 0.06 --max-iterations 100 --reflectance-type 0 --float-exposure --max-coarse-iterations 100 --use-approx-camera-models --coarse-levels 4 --crop-input-images --float-cameras 
#tile.pl run_ezcd/run-crop-DEM.tif 200 run_ezcd 30


for p in 0; do
    for ref in 0; do

	if [ "$w" = "1" ]; then win=$win1; fi;
	if [ "$w" = "2" ]; then win=$win2; fi;
	if [ "$w" = "3" ]; then win=$win3; fi;
	if [ "$w" = "4" ]; then win=$win4; fi;
	if [ "$w" = "5" ]; then win=$win5; fi;
	if [ "$w" = "6" ]; then win=$win6; fi;
	if [ "$w" = "7" ]; then win=$win7; fi;
	if [ "$w" = "8" ]; then win=$win8; fi;
	if [ "$w" = "9" ]; then win=$win9; fi;
	if [ "$w" = "10" ]; then win=$win10; fi;

	dir=${sfs}_run${run}_level${level}_tile${tile}_ref${ref}_w${w}_ba${do_ba}_crop${crop}_th${threads}_ezcd_sm${sm}
	mkdir -p $dir
	
	#gdal_translate -projwin $win run_ezcd/run-DEM.tif $dir/init-DEM.tif # fix
	cp -fv run_ezcd/tile-$tile.tif $dir/init-DEM.tif # dir
	gdalinfo  $dir/init-DEM.tif
	
	~/bin/time_run.sh  sfs -i $dir/init-DEM.tif ${q}.cub ${r}.cub ${s}.cub $t \
	    -o $dir/run \
	    --threads $threads --smoothness-weight $sm  \
	    --max-iterations 100 --reflectance-type $ref --float-exposure        \
	    --max-coarse-iterations 100  \
	    --use-approx-camera-models --coarse-levels $level	$opt_crop \
	    --bundle-adjust-prefix sfs601_run7_level4_tile01_ref0_w9_ba1_crop1_th4_ezcd_sm0.06/run # fix
	    #--float-cameras
            # fix float cameras
	    # fix levels 
	# $opt 
    done
done


#for f in $c $d $e $z; do 
#    mapproject --mpp 10 Lunar_LRO_LOLA_Global_LDEM_118m_Mar2014.tif $f.cub $f.map7.tif --tile-size 128  --t_srs '+proj=stere +lat_0=-90 +lat_ts=-90 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs '
#     mapproject --mpp 1  run_ezcd/run-DEM.tif $f.cub $f.map7.tif --tile-size 128  --t_srs '+proj=stere +lat_0=-90 +lat_ts=-90 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs ' --t_projwin -127354 4599 -124594 2082 --bundle-adjust-prefix run_ezcd_ba/run
    
# #    mapproject --mpp 1  $dir/init-DEM.tif $f.cub $f.map2.tif --tile-size 128  --t_srs '+proj=stere +lat_0=-90 +lat_ts=-90 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs ' #  --t_projwin 131770 -91160 132920 -92370
#done

fi

# crop=crop9; lola7=run7_subpix3/run-trans_source-DEM.tif; di $lola7 run7_subpix3/run-$crop-DEM.tif; for f in $(ls -d sfs_adk*$crop* | grep -i -v _fa1); do h=$(ls -altrd $f/*DEM*tif | grep -i -v hill | tail -n 1 | pc 0); echo $h; di $lola7 $h; done

a=M173635550RE.cal.echo_crop; b=M173642339LE.cal.echo_crop; c=M114594996LE.cal.echo_crop; d=M114588166RE.cal.echo_crop; e=M109869814LE.cal.echo_crop; z=M109863022RE.cal.echo_crop; g=M140577849RE.cal.echo; h=M140584637LE.cal.echo; j=M1116910862LE.cal.echo; k=M1116917960RE.cal.echo

lola7=run7_subpix3/run-trans_source-DEM.tif

th=4; reg=0.06; 
if [ "$id" = "0" ]; then fa=0; wt=1000; ref=0; fi
if [ "$id" = "1" ]; then fa=0; wt=1000; ref=1; fi
if [ "$id" = "2" ]; then fa=1; wt=1000; ref=0; fi
if [ "$id" = "3" ]; then fa=1; wt=1000; ref=1; fi
if [ "$id" = "4" ]; then fa=0; wt=2000; ref=0; fi
if [ "$id" = "5" ]; then fa=0; wt=2000; ref=1; fi
if [ "$id" = "6" ]; then fa=1; wt=2000; ref=0; fi
if [ "$id" = "7" ]; then fa=1; wt=2000; ref=1; fi

if [ "$id" -ge "8" ] || [ "$id" -lt "0" ]; then echo "Invalid id $id"; exit; fi
echo id is $id

if [ "$fa" -ne "0" ]; then opt="--float-albedo"; else opt=""; fi
dir=sfs_adk_${crop}_reg${reg}_ref${ref}_wt${wt}_fa${fa}

echo dir is $dir
echo output goes to output_${dir}.txt

sfs -i run7_subpix3/run-${crop}-DEM.tif $a.cub $d.cub $k.cub -o $dir/run --threads ${th} --smoothness-weight ${reg} --max-iterations 50 --reflectance-type $ref --use-approx-camera-models --coarse-levels 0 --crop-input-images --bundle-adjust-prefix run7_ba_manual/run --initial-dem-constraint-weight ${wt}  --use-rpc-approximation --float-exposure --float-cameras $opt > output_${dir}.txt 2>&1

