#!/bin/bash

if [ "$#" -lt 1 ]; then echo Usage: $0 win; exit; fi

id=$1
crop=$2

# This is the testcase 13

if [ 1 -eq 0 ]; then 

i=12
p=M151255967LE.cal.echo_crop; q=M151262745RE.cal.echo_crop; p0=M151255967LE.cal.echo; q0=M151262745RE.cal.echo; r=M1152519193RE.cal.echo; s=M1147814041RE.cal.echo; t=M1119567517LE.cal.echo; u=M1117209299LE.cal.echo; v=M1114858098RE.cal.echo; w=M155972130RE.cal.echo; x=M153617063RE.cal.echo

#crop from = ${a0}.cub to = ${a}.cub sample = 1 line = 6644 nsamples = 2192 nlines = 4982
#crop from = ${b0}.cub to = ${b}.cub sample = 1 line = 7013 nsamples = 2531 nlines = 7337
#crop from = ${c0}.cub to = ${c}.cub sample = 1 line = 1 nsamples = 2531 nlines = 8305
#crop from = ${d0}.cub to = ${d}.cub sample = 1 line = 1 nsamples = 2531 nlines = 2740

ba=run_ba122
bundle_adjust ${p}.cub ${q}.cub --min-matches 10 -o ${ba}/run
# stereo ${a}.cub ${b}.cub ${st}/run --subpixel-mode 3 --bundle-adjust-prefix ${ba}/run
# point2dem -r moon --tr 1 --stereographic --proj-lon 0 --proj-lat -90 ${st}/run-PC.tif -o ${st}/run-1m
#  pc_align --max-displacement 200 run_stereo13/run-1m-DEM.tif RDR_354E355E_85p5S84SPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km' --save-inv-transformed-reference-points -o run_stereo13/run-lola --save-transformed-source-points

point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon -120.19242 --proj-lat -81.294072 run_stereo12/run-trans_source.tif        

# The first SfS, to guess for the cameras
#gdt -projwin -15575 151561 -14229 150164 run_stereo13/run-1m-DEM.tif run_stereo13/run-1m-crop2-DEM.tif
# tile.pl run_stereo13/run-1m-crop2-DEM.tif 200 run_stereo13 30
# er=15; dem_mosaic --weights-exponent 2 --erode-length $er --use-centerline-weights sfs13_abcd_ref0_level0-tile*/run-DEM-final.tif -o run_stereo13/sfs

pc_align run_stereo12_manual/run-DEM.tif RDR_239E240E_81p3596S81SPointPerRow_csv_table.csv --max-displacement 300 -o run_stereo12_manual/run2 --save-transformed-source-points

tile=$1 # fix
w=10    # fix
#crop=1
threads=1 # fix
do_ba=1
level=0
sm=0.06
sfs=sfs$i

if [ "$tile" -le 9 ]; then tile="0$tile"; fi;
echo Tile is $tile

sfs -i run_stereo${i}/tile-$tile.tif ${p}.cub ${q}.cub ${r}.cub                             \
    -o ${sfs}_pqr2_level${level}_sm${sm}_tile${tile}/run --threads 1 --smoothness-weight $sm \
    --max-iterations 100 --reflectance-type 0 --float-exposure                              \
    --use-approx-camera-models --coarse-levels $level --crop-input-images                   \
    --bundle-adjust-prefix sfs12_pqr_level0_sm0.06/run

point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon -120.19242 --proj-lat -81.294072 run_stereo12/run-PC.tif

crop=crop7; lola12=run_stereo12_manual/run-trans_source-DEM.tif; di $lola12 run_stereo12_manual/run-$crop-DEM.tif; for f in $(ls -d sfs_pqs*$crop*); do h=$(ls -altrd $f/*DEM*tif | grep -i -v hill | tail -n 1 | pc 0); echo $h; di $lola12 $h; done 

# crop goes crop3 crop4 crop5 crop6 crop7
fi

th=4; reg=0.06
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


p=M151255967LE.cal.echo_crop; q=M151262745RE.cal.echo_crop; p0=M151255967LE.cal.echo; q0=M151262745RE.cal.echo; r=M1152519193RE.cal.echo; s=M1147814041RE.cal.echo; t=M1119567517LE.cal.echo; u=M1117209299LE.cal.echo; v=M1114858098RE.cal.echo; w=M155972130RE.cal.echo; x=M153617063RE.cal.echo
if [ "$fa" -ne "0" ]; then opt="--float-albedo"; else opt=""; fi
dir=sfs_pqs_${crop}_reg${reg}_ref${ref}_wt${wt}_fa${fa}

echo dir is $dir

sfs -i run_stereo12_manual/run-${crop}-DEM.tif $p.cub $r.cub $s.cub -o $dir/run --threads ${th} --smoothness-weight ${reg} --max-iterations 50 --reflectance-type $ref --use-approx-camera-models --coarse-levels 0 --crop-input-images --bundle-adjust-prefix run_ba12_manual/run --initial-dem-constraint-weight ${wt}  --use-rpc-approximation --float-exposure --float-cameras $opt > output_${dir}.txt 2>&1


