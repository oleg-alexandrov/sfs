#!/bin/bash

if [ "$#" -lt 1 ]; then echo Usage: $0 win; exit; fi

# This is the testcase 13

i=13
a0=M139939938LE.cal.echo
b0=M139946735RE.cal.echo
c0=M173004270LE.cal.echo
d0=M122270273LE.cal.echo
a=${a0}_crop
b=${b0}_crop
c=${c0}_crop
d=${d0}_crop
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i
win="-15540.7 151403 -14554.5 150473"

#crop from = ${a0}.cub to = ${a}.cub sample = 1 line = 6644 nsamples = 2192 nlines = 4982
#crop from = ${b0}.cub to = ${b}.cub sample = 1 line = 7013 nsamples = 2531 nlines = 7337
#crop from = ${c0}.cub to = ${c}.cub sample = 1 line = 1 nsamples = 2531 nlines = 8305
#crop from = ${d0}.cub to = ${d}.cub sample = 1 line = 1 nsamples = 2531 nlines = 2740

# bundle_adjust ${a}.cub ${b}.cub --min-matches 10 -o ${ba}/run
# stereo ${a}.cub ${b}.cub ${st}/run --subpixel-mode 3 --bundle-adjust-prefix ${ba}/run
# point2dem -r moon --tr 1 --stereographic --proj-lon 0 --proj-lat -90 ${st}/run-PC.tif -o ${st}/run-1m
#  pc_align --max-displacement 200 run_stereo13/run-1m-DEM.tif RDR_354E355E_85p5S84SPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km' --save-inv-transformed-reference-points -o run_stereo13/run-lola --save-transformed-source-points

# The first SfS, to guess for the cameras
#gdt -projwin -15575 151561 -14229 150164 run_stereo13/run-1m-DEM.tif run_stereo13/run-1m-crop2-DEM.tif
# tile.pl run_stereo13/run-1m-crop2-DEM.tif 200 run_stereo13 30
# er=15; dem_mosaic --weights-exponent 2 --erode-length $er --use-centerline-weights sfs13_abcd_ref0_level0-tile*/run-DEM-final.tif -o run_stereo13/sfs


tile=$1 # fix
w=10    # fix
crop=1
threads=1 # fix
do_ba=1

if [ "$tile" -le 9 ]; then tile="0$tile"; fi;
echo Tile is $tile

sfs -i run_stereo13/tile-$tile.tif M139939938LE.cal.echo_crop.cub M139946735RE.cal.echo_crop.cub M173004270LE.cal.echo_crop.cub M122270273LE.cal.echo_crop.cub -o sfs13_abcd_ref0_level0-tile$tile/run --threads 1  --smoothness-weight 0.06 --max-iterations 100 --reflectance-type 0 --float-exposure  --use-approx-camera-models --coarse-levels 0 # --bundle-adjust-prefix sfs13_abcd_ref0_level4/run --crop-input-images

