#!/bin/bash

# Note the custom prefix and resolution below

if [ "$#" -lt 5 ]; then echo Usage: $0 leftPrefix rightPrefix outPrefix baPrefix currDir; exit; fi

leftPrefix=$1
rightPrefix=$2
outPrefix=$3
baPrefix=$4
currDir=$5

out=output_$(dirname $outPrefix).txt

cd $currDir

export ISISDATA=$HOME/projects/isis3data
export ISISROOT=$HOME/miniconda3/envs/isis5.0.1
export ALESPICEROOT=$ISISDATA

export PATH=/home6/oalexan1/projects/BinaryBuilder/StereoPipeline-x86_64-redhat7.9-2022-08-01_14-53-03a143467-dirty/bin:$PATH


if [ "$PBS_NODEFILE" = "" ]; then
    # To run locally
    PBS_NODEFILE=curr_machine.txt
    echo $(uname -n) > $PBS_NODEFILE
fi

rm -fv $out
echo Writing the output to $out

echo Head node: $(uname -n) >> $out
echo Machines: $(cat ${PBS_NODEFILE}) >> $out

parallel_stereo                        \
    --nodes-list $PBS_NODEFILE         \
    --stereo-algorithm asp_mgm         \
    --processes 4                      \
    --alignment-method affineepipolar  \
    $leftPrefix.cub $rightPrefix.cub   \
    $leftPrefix.json $rightPrefix.json \
    $outPrefix >> $out 2>&1

point2dem --errorimage --t_srs '+proj=stere +lat_0=-85.42088 +lon_0=31.6218 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs ' --tr 1 ${outPrefix}-PC.tif  >> $out 2>&1



