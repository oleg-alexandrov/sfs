#!/bin/bash

if [ "$#" -lt 5 ]; then echo Usage: $0 list prevPrefix matchPrefix outPrefix currDir; exit; fi

# Run bundle_adjust. The list must have, on each line text of the form:
# <something>M<digits>{LE,RE}<something>. Extra text in it will be wiped,
# only the id will be kept: M<digits>{LE,RE}.
#
# Conventions for inputs:
# Images: cubes/<id>.cal.echo.cub
# Cameras: cubes/<id>.cal.echo.json

list=$1
prevPrefix=$2
matchPrefix=$3
outPrefix=$4
currDir=$5

out=output_$(dirname $outPrefix).txt

cd $currDir

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

rm -fv $out
echo Writing: $out

echo Head node: $(uname -n) >> $out
echo Machines: $(cat ${PBS_NODEFILE}) >> $out

cubes=""
cameras=""
for id in $(cat $list | perl -pi -e "s#^.*?(M\d+[LR]E).*?\n#\$1\n#g"); do
    cub=cubes/${id}.cal.echo.cub
    cam=cubes/${id}.cal.echo.json
    if [ ! -f "$cub" ]; then echo missing cub file $cub; exit 1; fi
    if [ ! -f "$cam" ]; then echo missing cam file $cam; exit 1; fi

    cubes="$cubes $cub"
    cams="$cams $cam"
done

# Note that robust threshold is set to 2. That may be too low if one starts from scratch.
# Use a high outlier removal threshold, to remove only the most obvious outliers.
# That because sometimes the outliers can prevent convergence to start with, and
# then aggressive outlier removal can remove good points.
bundle_adjust $cubes $cams                  \
    --skip-matching                         \
    --clean-match-files-prefix $matchPrefix \
    --input-adjustments-prefix $prevPrefix  \
    --camera-weight 0.0                     \
    --datum D_MOON                          \
    --ip-per-image 10000                    \
    --match-first-to-last                   \
    --max-pairwise-matches 400              \
    --min-matches 1                         \
    --min-triangulation-angle 0.1           \
    --num-iterations 100                    \
    --num-passes 2                          \
    --remove-outliers-params                \
    "75.0 3.0 100 100"                      \
    --overlap-limit 40                      \
    --parameter-tolerance 1e-12             \
    --robust-threshold 5                    \
    -o $outPrefix >> $out 2>&1
