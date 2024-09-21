#!/bin/bash

# Note the custom prefix and resolution below

if [ "$#" -lt 5 ]; then echo Usage: $0 leftPrefix rightPrefix outPrefix baPrefix currDir; exit; fi

leftPrefix=$1
rightPrefix=$2
outPrefix=$3
baPrefix=$4
currDir=$5


cd $currDir

out=output_$(dirname $outPrefix).txt
rm -fv $out
echo Writing the output to $out

export ISISDATA=$HOME/projects/isis3data
export ISISROOT=$HOME/miniconda3/envs/isis5.0.1
export ALESPICEROOT=$ISISDATA
s=StereoPipeline-3.1.1-alpha-2022-08-06-x86_64-Linux
export PATH=/home6/oalexan1/projects/BinaryBuilder/$s/bin:$PATH

if [ "$PBS_NODEFILE" = "" ]; then
    # To run locally
    PBS_NODEFILE=$(uname -n).txt
    echo $(uname -n) > $PBS_NODEFILE
fi

echo Head node: $(uname -n) >> $out
echo Machines: $(cat ${PBS_NODEFILE}) >> $out

dem=lola/lola_clip_Site20.tif
win=$(~/bin/gdal_win.sh ${dem})

parallel_stereo                        \
    --nodes-list $PBS_NODEFILE         \
    --stereo-algorithm asp_mgm         \
    --processes 4                      \
    --alignment-method affineepipolar  \
    --bundle-adjust-prefix $baPrefix   \
    $leftPrefix.cub $rightPrefix.cub   \
    $leftPrefix.json $rightPrefix.json \
    $outPrefix >> $out 2>&1

point2dem --errorimage --t_srs '+proj=stere +lat_0=-85.42088 +lon_0=31.6218 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs ' --t_projwin $win --tr 1 ${outPrefix}-PC.tif  >> $out 2>&1


