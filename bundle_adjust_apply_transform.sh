#!/bin/bash

if [ "$#" -lt 5 ]; then echo Usage: $0 list inPrefix transform outPrefix currDir; exit; fi

# Run bundle_adjust. Reuse existing matches. The list must have, on each line text of the form:
# <something>M<digits>{LE,RE}<something>. Extra text in it will be wiped,
# only the id will be kept: M<digits>{LE,RE}.
#
# Conventions for inputs:
# Images: cubes/<id>.cal.echo.cub
# Cameras: cubes/<id>.cal.echo.json

list=$1
inPrefix=$2
transform=$3
outPrefix=$4
currDir=$5

cd $currDir

out=output_$(dirname $outPrefix).txt
rm -fv $out
echo Writing: $out

if [ "$PBS_O_WORKDIR" != "" ]; then
    echo cd $PBS_O_WORKDIR
    cd $PBS_O_WORKDIR
fi

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

cubes=$(cat $list | perl -pi -e "s#^.*?(M\d+[LR]E).*?\n#cubes/\$1.cal.echo.cub #g")
cams=$(cat  $list | perl -pi -e "s#^.*?(M\d+[LR]E).*?\n#cubes/\$1.cal.echo.json #g")

# These are too many, they don't fit on the command line
mkdir -p $(dirname $outPrefix)
ilist=${outPrefix}-image_list.txt
clist=${outPrefix}-camera_list.txt
echo $cubes > $ilist
echo $cams > $clist

echo Head node: $(uname -n) >> $out
echo Machines: $(cat ${PBS_NODEFILE}) >> $out

echo input cameras $inPrefix
echo transform: $transform
echo output cameras: $outPrefix

/usr/bin/time -f                         \
    "Elapsed=%E memory=%M (kb)"          \
    bundle_adjust                        \
    --image-list $ilist                  \
    --camera-list $clist                 \
    --skip-matching                      \
    --force-reuse-match-files            \
    --overlap-limit 500                  \
    --ip-per-image 15000                 \
    --max-pairwise-matches 400           \
    --num-iterations 100                 \
    --num-passes 1                       \
    --save-intermediate-cameras          \
    --min-matches 1                      \
    --match-first-to-last                \
    --min-triangulation-angle 0.1        \
    --initial-transform $transform       \
    --apply-initial-transform-only       \
    --input-adjustments-prefix $inPrefix \
    -o $outPrefix >> $out 2>&1

