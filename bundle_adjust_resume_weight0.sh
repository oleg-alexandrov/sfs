#!/bin/bash

if [ "$#" -lt 3 ]; then echo Usage: $0 list outPrefix currDir; exit; fi

# Run bundle_adjust. Reuse existing matches. The list must have, on each line text of the form:
# <something>M<digits>{LE,RE}<something>. Extra text in it will be wiped,
# only the id will be kept: M<digits>{LE,RE}.
#
# Conventions for inputs:
# Images: cubes/<id>.cal.echo.cub
# Cameras: cubes/<id>.cal.echo.json

list=$1
outPrefix=$2
currDir=$3

out=output_$(dirname $outPrefix).txt

cd $currDir

if [ "$PBS_O_WORKDIR" != "" ]; then
    echo cd $PBS_O_WORKDIR
    cd $PBS_O_WORKDIR
fi
    
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

cubes=""
cameras=""
i=1
echo Number of items in the list $(cat $list | wc | ~/bin/print_col.pl 1)  >> $out 
for id in $(cat $list | perl -pi -e "s#^.*?(M\d+[LR]E).*?\n#\$1\n#g"); do
    cub=cubes/${id}.cal.echo.cub
    cam=cubes/${id}.cal.echo.json
    if [ ! -f "$cub" ]; then echo missing cub file $cub; exit 1; fi
    if [ ! -f "$cam" ]; then echo missing cam file $cam; exit 1; fi

    echo $i $cub >> $out
    ((i++))
    cubes="$cubes $cub"
    cams="$cams $cam"
done

echo Head node: $(uname -n) >> $out
echo Machines: $(cat ${PBS_NODEFILE}) >> $out

bundle_adjust $cubes $cams                   \
    --camera-weight 0                        \
    --force-reuse-match-files                \
    --input-adjustments-prefix ba/iter89/run \
    --ip-per-image 15000                     \
    --match-first-to-last                    \
    --max-pairwise-matches 400               \
    --min-matches 1                          \
    --min-triangulation-angle 0.001          \
    --num-iterations 100                     \
    --num-passes 1                           \
    --overlap-limit 500                      \
    --save-intermediate-cameras              \
    --skip-matching                          \
    -o $outPrefix >> $out 2>&1

