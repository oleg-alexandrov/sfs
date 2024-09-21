#!/bin/bash

if [ "$#" -lt 4 ]; then echo Usage: $0 list dem outPrefix currDir; exit; fi

# Run bundle_adjust. The list must have, on each line text of the form:
# <something>M<digits>{LE,RE}<something>. Extra text in it will be wiped,
# only the id will be kept: M<digits>{LE,RE}.
#
# Conventions for inputs:
# Images: cubes/<id>.cal.echo.cub
# Cameras: cubes/<id>.cal.echo.json
# Mapprojected: map_tr1_noba/<id>.cal.echo.map.tr1.tif

list=$1
dem=$2
outPrefix=$3
currDir=$4

out=output_$(dirname $outPrefix).txt

cd $currDir

export ISISDATA=$HOME/projects/isis3data
export ISISROOT=$HOME/miniconda3/envs/isis5.0.1
export ALESPICEROOT=$ISISDATA

export PATH=/home6/oalexan1/projects/BinaryBuilder/StereoPipeline-x86_64-redhat7.9-2022-08-03_13-45-41a143467-dirty/bin:$PATH

if [ "$PBS_NODEFILE" = "" ]; then
    # To run locally
    PBS_NODEFILE=curr_machine.txt
    echo $(uname -n) > $PBS_NODEFILE
fi

cubes=""
cameras=""
maps=""
for id in $(cat $list | perl -pi -e "s#^.*?(M\d+[LR]E).*?\n#\$1\n#g"); do
    cub=cubes/${id}.cal.echo.cub
    cam=cubes/${id}.cal.echo.json
    map=map_tr1_noba_crop_tmp/${id}.cal.echo.map.tr1.tif
    if [ ! -f "$cub" ]; then echo missing cub file $cub; exit 1; fi
    if [ ! -f "$cam" ]; then echo missing cam file $cam; exit 1; fi
    if [ ! -f "$map" ]; then echo missing map file $map; exit 1; fi

    cubes="$cubes $cub"
    cams="$cams $cam"
    maps="$maps $map"
done

rm -fv $out
echo Writing the output to $out

echo Head node: $(uname -n) >> $out
echo Machines: $(cat ${PBS_NODEFILE}) >> $out

parallel_bundle_adjust $cubes $cams   \
    --camera-weight 0                 \
    --datum D_MOON                    \
    --ip-per-image 10000              \
    --mapprojected-data "$maps $dem"  \
    --match-first-to-last             \
    --max-pairwise-matches 400        \
    --min-matches 1                   \
    --min-triangulation-angle 0.1     \
    --nodes-list $PBS_NODEFILE        \
    --num-iterations 100              \
    --num-passes 1                    \
    --overlap-limit 20                \
    --parameter-tolerance 1e-12       \
    --processes 4                     \
    --save-intermediate-cameras       \
    --input-adjustments-prefix ba/run \
    -o $outPrefix >> $out 2>&1

