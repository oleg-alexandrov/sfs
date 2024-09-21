#!/bin/bash

tile=$1 # Must be between 1 and 4.
num=$2  # How many images to keep around the stereo pair
currDir=$3

cd $currDir

echo tile is $tile
echo num is $num

out=output_tile${tile}_th50.txt

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

# Use just a subset of the images, about 2 * num
grep -B ${num} -A ${num} -E "$b1|$b2" tile${tile}_azimuth_good.txt \
    | grep cub > tile${tile}_azimuth_good_num${num}.txt

# Run bundle adjustment reusing the matches. Do some light outlier filtering.
~/projects/sfs/bundle_adjust_reuse_matches_th50.sh       \
    tile${tile}_azimuth_good_num${num}.txt               \
    tiles/tile-${tile}-v1.tif                            \
    map_tr1_noba_tile${tile}                             \
    ba_tile${tile}/run ba_tile${tile}_num${num}_th50/run \
    $(pwd) >> $out 2>&1

cat ba_tile${tile}_num${num}/run-final_residuals_stats.txt >> $out 2>&1

