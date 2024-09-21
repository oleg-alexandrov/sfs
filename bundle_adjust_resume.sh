#!/bin/bash

if [ "$#" -lt 5 ]; then echo Usage: $0 list inPrefix matchPrefix outPrefix currDir; exit; fi

# Run bundle_adjust. The list must have, on each line text of the form:
# <something>M<digits>{LE,RE}<something>. Extra text in it will be wiped,
# only the id will be kept: M<digits>{LE,RE}.
#
# Conventions for inputs:
# Images: cubes/<id>.cal.echo.cub
# Cameras: cubes/<id>.cal.echo.json

list=$1; shift
inPrefix=$1; shift
matchPrefix=$1; shift
outPrefix=$1; shift
currDir=$1; shift

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

rm -fv $out
echo Writing: $out

echo Head node: $(uname -n) >> $out
echo Machines: $(cat ${PBS_NODEFILE}) >> $out

cubes=$(cat $list | perl -pi -e "s#^.*?(M\d+[LR]E).*?\n#cubes/\$1.cal.echo.cub #g")
cams=$(cat  $list | perl -pi -e "s#^.*?(M\d+[LR]E).*?\n#cubes/\$1.cal.echo.json #g")

# These are too many, they don't fit on the command line
mkdir -p $(dirname $outPrefix)
ilist=${outPrefix}-image_list.txt
clist=${outPrefix}-camera_list.txt
echo $cubes > $ilist
echo $cams > $clist

# Use a high outlier removal threshold, to remove only the most obvious outliers.
# That because sometimes the outliers can prevent convergence to start with, and
# then aggressive outlier removal can remove good points.
# Use --robust-threshold 5 to make it work harder moving cameras

# Note how we drastically increase the number of iterations below and also
# the robust threshold and outlier removal params, to force the cameras
# to converge
echo Note that robust-threshold is 0.5
echo Note that we use 1 pass and matches without outlier filtering
/usr/bin/time -f                         \
    "Elapsed=%E memory=%M (kb)"          \
bundle_adjust                            \
    --skip-matching                      \
    --force-reuse-match-files            \
    --match-files-prefix $matchPrefix    \
    --input-adjustments-prefix $inPrefix \
    --image-list $ilist                  \
    --camera-list $clist                 \
    --camera-weight 0.00                 \
    --datum D_MOON                       \
    --ip-per-image 10000                 \
    --match-first-to-last                \
    --max-pairwise-matches 400           \
    --min-matches 1                      \
    --min-triangulation-angle 0.1        \
    --num-iterations 1000                \
    --num-passes 1                       \
    --remove-outliers-params             \
    "75.0 3.0 100 100"                   \
    --robust-threshold 0.5               \
    --overlap-limit 40                   \
    --parameter-tolerance 1e-12          \
    -o $outPrefix                        \
    >> $out 2>&1
