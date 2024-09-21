#!/bin/bash

if [ "$#" -lt 1 ]; then echo Usage: $0 tile; exit; fi

prefix=$1
tile=$2 # fix
if [ "$tile" -le 9 ]; then tile="0$tile"; fi;
echo Tile is $tile

if [ 1 -eq 0 ]; then 
crop.pl M1121217002RE.cal.echo.cub: 717 31751 4024 3789
crop.pl M1121209902LE.cal.echo.cub: 1643 30259 4006 4974
crop.pl M1108253386RE.cal.echo.cub: 406 15766 4567 4760

bundle_adjust M1121217002RE.cal.echo_crop.cub M1121209902LE.cal.echo_crop.cub M1108253386RE.cal.echo_crop.cub --min-matches 10 -o run_ap3_ba/run

# Then overwrite the match between 1st and third
stereo M1121217002RE.cal.echo_crop.cub M1121209902LE.cal.echo_crop.cub run_ap3/run --bundle-adjust-prefix run_ap3_ba/run --subpixel-mode 3

point2dem -r moon --csv-format '2:lon 3:lat 4:radius_km' --tr 1 --stereographic --proj-lon 3.6 --proj-lat 26.18 run_ap3/run-PC.tif                                               

point2dem -r moon --csv-format '2:lon 3:lat 4:radius_km' --tr 1 --stereographic --proj-lon 3.6 --proj-lat 26.18 RDR_3E4E_25N26NPointPerRow_csv_table.csv

pc_align --max-displacement 300 run_ap3/run-PC.tif RDR_3E4E_25N26NPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km' --save-transformed-source-points -o run_ap3/run

point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon 3.6 --proj-lat 26.18 run_ap3/run-trans_source.csv

# bug!!!
for f in M1121217002RE.cal.echo_crop.cub M1121209902LE.cal.echo_crop.cub M1108253386RE.cal.echo_crop.cub; do g=${f/.cub/}; echo $f $g; mapproject run_ap3/run-DEM.tif $f $g.map.tif --tr 1 --tile-size 512 --bundle-adjust-prefix run_ap3_ba/run; done


gdt run_ap3/run-DEM.tif -srcwin  282 2484 352 234 run_ap3/run-crop1-DEM.tif
gdt run_ap3/run-DEM.tif -srcwin 227 2914 323 230 run_ap3/run-crop2-DEM.tif
gdt -projwin -391 1416 -199 1243 run_ap3/run-DEM.tif run_ap3/run-crop4-DEM.tif

gdt run_ap3/run-DEM.tif -srcwin 1455 3180 192 181  run_ap3/run-crop5-DEM.tif
gdt run_ap3/run-DEM.tif -srcwin 393 2509 176 170   run_ap3/run-crop6-DEM.tif
gdt run_ap3/run-DEM.tif -srcwin 165 2988 324 2841  run_ap3/run-crop7-DEM.tif

gdt run_ap3/run-DEM.tif -srcwin 101 3189 533 578 run_ap3/run-crop8-DEM.tif
gdt run_ap3/run-DEM.tif -srcwin 145 519  516 551 run_ap3/run-crop9-DEM.tif
gdt run_ap3/run-DEM.tif -srcwin 1467 945 560 542 run_ap3/run-crop10-DEM.tif
gdt run_ap3/run-DEM.tif -srcwin 1458 1974 586 577 run_ap3/run-crop11-DEM.tif
gdt run_ap3/run-DEM.tif -srcwin 1245 3012 684 630 run_ap3/run-crop12-DEM.tif
gdt run_ap3/run-DEM.tif -srcwin  487 557 1484 1364 run_ap3/run-crop13-DEM.tif
gdt run_ap3/run-crop13-DEM.tif -srcwin 68 226 820 817 run_ap3/run-crop14-DEM.tif
gdt -srcwin 481 1844 1001 1138 run_ap3/run-DEM.tif run_ap3/run-crop15-DEM.tif

crop=8; level=0; hp ~/bin/time_run.sh sfs -i run_ap3/run-crop${crop}-DEM.tif M1121217002RE.cal.echo_crop.cub M1121209902LE.cal.echo_crop.cub M1108253386RE.cal.echo_crop.cub -o sfs_ap_crop${crop}_level${level}/run --threads 4 --smoothness-weight 0.06 --max-iterations 100 --reflectance-type 0 --float-exposure --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix run_ap3_ba/run --float-cameras > output_crop${crop}_level${level}.txt 2>&1&


job=2
tile.pl run_ap3/run-big3-DEM.tif 200 run_ap3_job${job} 30
er=10; dem_mosaic --weights-exponent 2 --erode-length $er --use-centerline-weights sfs_ap_run_ap3_job${job}_tile[0-9]*/run-DEM-final.tif -o run_ap3/run-sfs-job${job}
win=$(gdal_win.sh run_ap3/run-sfs-job${job}-tile-0.tif)
echo win is $win
gdal_translate -projwin $win run_ap3/run-DEM.tif run_ap3/run-before-sfs-job${job}.tif 

fi

level=0
sfs -i $prefix/tile-${tile}.tif M1121217002RE.cal.echo_crop.cub M1121209902LE.cal.echo_crop.cub M1108253386RE.cal.echo_crop.cub -o sfs_ap_${prefix}_tile${tile}/run --threads 4 --smoothness-weight 0.06 --max-iterations 100 --reflectance-type 0 --float-exposure --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix run_ap3_ba/run


# small
gdt run_ap3/run-DEM.tif -projwin 752 2963 1043 2736 run_ap3/run-crop16-DEM.tif

# big
gdt run_ap3/run-DEM.tif -projwin 534 3099 1347 2397 run_ap3/run-crop17-DEM.tif

a=M1121217002RE.cal.echo_crop; b=M1121209902LE.cal.echo_crop; c=M1108253386RE.cal.echo_crop; d=M119829425LE.cal.echo;

point2dem -r moon --csv-format '2:lon 3:lat 4:radius_km' --tr 1 --stereographic --proj-lon 3.6 --proj-lat 26.18 ap_stereo_map/run-PC.tif


gdt -projwin 533.500 3099.500 1346.500 2397.500 ap_stereo_map/run-DEM.tif ap_stereo_map/run-crop17-DEM.tif

pc_align ap_stereo_map/run-DEM.tif RDR_3E4E_25N26NPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km' -o ap_stereo_map/run --max-displacement 200  --save-transformed-source-points 

point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon 3.6 --proj-lat 26.18 ap_stereo_map/run-trans_source.csv

di ap_stereo_map/run-trans_source-DEM.tif  ap_stereo_map/run-DEM.tif 

ht=1000; ft=0; ref=0;

a=M1121217002RE.cal.echo_crop; b=M1121209902LE.cal.echo_crop; c=M1108253386RE.cal.echo_crop; d=M119829425LE.cal.echo;
lola5=ap_stereo_map/run-trans_source-DEM.tif
th=4 # num threads
reg=0.06; level=0; 
opt="";
if [ "$ft" -ne 0 ]; then opt="--float-cameras"; fi
dir=sfs_ap_acd_crop21_reg${reg}_ref${ref}_ht${ht}_ft${ft}
hp ~/projects/StereoPipeline/src/asp/Tools/sfs -i ap_stereo_map/run-crop21-DEM.tif $a.cub $c.cub $d.cub -o $dir/run --threads $th --smoothness-weight ${reg} --max-iterations 50 --reflectance-type $ref --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix ap_ba_map/run $opt --float-exposure --initial-dem-constraint-weight ${ht}  --use-rpc-approximation > output_${dir}.txt 2>&1&

#dir=sfs_ap_acd_crop22_reg${reg}_ref${ref}_ht${ht}_ft${ft}_sub2
#hp ~/projects/StereoPipeline/src/asp/Tools/sfs -i ap_stereo_map/run-crop22-DEM.tif $a.sub2.cub $c.sub2.cub $d.sub2.cub -o $dir/run --threads $th --smoothness-weight ${reg} --max-iterations 50 --reflectance-type $ref --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix ap_ba_map/run $opt --float-exposure --initial-dem-constraint-weight ${ht}  --use-rpc-approximation > output_${dir}.txt 2>&1&


di $lola5 ap_stereo_map/run-crop22-DEM.tif

for f in $(llt sfs*crop21* |grep -i -v sub | grep -i _fa |pc 0); do g=${f/_fa/}; if [ ! -d $g ]; then continue; fi; h=$(ls -altrd $f/*DEM*tif | grep -i -v hill | tail -n 1 | pc 0); r=$(ls -altrd $g/*DEM*tif | grep -i -v hill | tail -n 1 | pc 0); echo $r; di $lola5 $r; echo $h; di $lola5 $h; echo " "; done

for f in $(llt sfs*crop22* |grep -i -v sub | grep -i -v _fa |pc 0); do g=${f/_fa/}; h=$(ls -altrd $f/*DEM*tif | grep -i -v hill | tail -n 1 | pc 0); echo $h; di $lola5 $h; echo " "; done
