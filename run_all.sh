#!/bin/bash

tile=$1 # Must be between 1 and 4.
num=$2  # How many images to keep around the stereo pair
currDir=$3

cd $currDir

echo tile is $tile
echo num is $num

out=output_tile${tile}.txt

rm -fv $out
echo Writing: $out

export PATH=/home6/oalexan1/projects/BinaryBuilder/StereoPipeline-3.1.1-alpha-2022-08-06-x86_64-Linux/bin:$PATH

# Crop window for each tile
win=""

# win1="-8367.701 7615.141 -514.701 1692.141"
# win2="-8348.701 2354.141 -476.701 -3984.859"
# win3="-1498.701 7728.141 6505.299 1276.141"
# win4="-1593.701 2354.141 6562.299 -3984.859"

# For new projection
win1="-9336.500 8247.500 -1968.500 2543.500"
win2="-9336.500 2943.500 -1968.500 -2760.500"
win3="-2368.500 8247.500 4999.500 2543.500"
win4="-2368.500 2943.500 4999.500 -2760.500"

if [ "$tile" -eq 1 ]; then win="$win1"; fi
if [ "$tile" -eq 2 ]; then win="$win2"; fi
if [ "$tile" -eq 3 ]; then win="$win3"; fi
if [ "$tile" -eq 4 ]; then win="$win4"; fi

if [ "$tile" -gt 4 ] || [ "$tile" -lt 0 ]; then
    echo Unknown tile: $tile
    exit 0
fi

# stereo pairs
s1=M1103432901LE; s2=M1103475755LE; t1=M1101075756LE; t2=M1101097181LE; t3=M1101118606LE

# Bookeeping
if [ "$tile" -eq 1 ] || [ "$tile" -eq 2 ]; then
    a1=t1;  a2=t2
    b1=$t1; b2=$t2
else
    a1=s1;  a2=s2
    b1=$s1; b2=$s2
fi

proj='+proj=stere +lat_0=-85.42088 +lon_0=31.6218 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs'

st=st_${a1}_${a2}_ba_tile${tile}_num${num}

# Use just a subset of the images, about 2 * num
grep -B ${num} -A ${num} -E "$b1|$b2" tile${tile}_azimuth_good.txt \
    | grep cub > tile${tile}_azimuth_good_num${num}.txt

# Run bundle adjustment reusing the matches. Do some light outlier filtering.
~/projects/sfs/bundle_adjust_reuse_matches.sh       \
    tile${tile}_azimuth_good_num${num}.txt          \
    tiles/tile-${tile}-v1.tif                       \
    map_tr1_noba_tile${tile}                        \
    ba_tile${tile}/run ba_tile${tile}_num${num}/run \
    $(pwd) >> $out 2>&1

cat ba_tile${tile}_num${num}/run-final_residuals_stats.txt >> $out 2>&1

# Do stereo in the tile. Reuse a previus run, but with current adjustments.
~/projects/sfs/stereo_resume.sh           \
    cubes/$b1.cal.echo cubes/$b2.cal.echo \
    ${st}/run                             \
    st_${a1}_${a2}/run                    \
    ba_tile${tile}_num${num}/run          \
    $(pwd) >> $out 2>&1

~/bin/gdal_translate.pl -projwin $win \
    ${st}/run-DEM.tif                 \
    ${st}/run-DEM-crop.tif >> $out 2>&1

~/bin/gdal_translate.pl -projwin $win \
    ${st}/run-IntersectionErr.tif     \
    ${st}/run-IntersectionErr-crop.tif >> $out 2>&1

echo Printing stats in ${st}/run-IntersectionErr-crop.tif
gdalinfo -stats ${st}/run-IntersectionErr-crop.tif >> $out 2>&1

# Hard to find the max displacement. For tile 1 it should be 100.
pc_align --max-displacement 100                            \
    --csv-format '2:lon 3:lat 4:radius_km'                 \
    --datum D_MOON --save-inv-transformed-reference-points \
    ${st}/run-DEM-crop.tif                                 \
    RDR.csv                                                \
    --alignment-method point-to-plane           \
    -o ${st}/run-align >> $out 2>&1

point2dem --tr 1                        \
    --t_projwin $win                    \
    --t_srs "$proj"                     \
    ${st}/run-align-trans_reference.tif \
    -o  ${st}/run-align-crop

stereo_gui --create-image-pyramids-only --hillshade ${st}/run-align-crop-DEM.tif

stereo_gui -g --single-window --hillshade --hide-all ${st}/run-align-crop-DEM.tif \
    ${st}/run-DEM-crop.tif tiles/tile-${tile}.tif

geodiff --absolute --csv-format '2:lon 3:lat 4:radius_km' \
    ${st}/run-align-crop-DEM.tif RDR.csv \
    -o ${st}/run-align

~/projects/sfs/bundle_adjust_apply_transform.sh \
    tile${tile}_azimuth_good_num${num}.txt      \
    ba_tile${tile}_num${num}/run                \
    ${st}/run-align-inverse-transform.txt       \
    ba_tile${tile}_num${num}_align/run          \
    $currDir >> $out 2>&1


# Height-from-dem constraint
~/projects/sfs/bundle_adjust_heights_from_dem_th5.sh              \
    tile${tile}_azimuth_good_num${num}.txt tiles/tile-${tile}.tif \
    ba_tile${tile}_num500/run                                     \
    ba_tile${tile}_num500_align/run                               \
    ba_tile${tile}_num500_align_htdem/run                         \
    $(pwd)