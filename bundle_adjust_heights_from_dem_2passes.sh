#!/bin/bash

if [ "$#" -lt 10 ]; then echo Usage: $0 list dem matchPrefix inPrefix th demWt demTh mode outPrefix outDir; exit; fi

# Run bundle_adjust. The list must have, on each line text of the form:
# <something>M<digits>{LE,RE}<something>. Extra text in it will be wiped,
# only the id will be kept: M<digits>{LE,RE}.
#
# Conventions for inputs:
# Images: cubes/<id>.cal.echo.cub
# Cameras: cubes/<id>.cal.echo.json

list=$1; shift
dem=$1; shift
matchPrefix=$1; shift
inPrefix=$1; shift
th=$1; shift
demWt=$1; shift
demTh=$1; shift
mode=$1; shift
outPrefix=$1; shift
currDir=$1; shift

cd $currDir

out=output_$(dirname $outPrefix).txt
rm -fv $out
echo Writing: $out

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

opt=""
if [ "$mode" = "htDem" ]; then
    opt="--heights-from-dem $dem --heights-from-dem-robust-threshold $demTh --heights-from-dem-weight $demWt"
fi
if [ "$mode" = "refDem" ]; then
    opt="--reference-dem $dem --reference-dem-robust-threshold $demTh --reference-dem-weight $demWt"
fi

echo Note that we use original matches, not clean matches
echo Note that 2 passes are done

# Still need to figure out what a good robust threshold and weight is
/usr/bin/time -f                         \
    "Elapsed=%E memory=%M (kb)"          \
    bundle_adjust                        \
    --image-list $ilist                  \
    --camera-list $clist                 \
    --skip-matching                      \
    --match-files-prefix $matchPrefix    \
    --input-adjustments-prefix $inPrefix \
    --camera-weight 0.0                  \
    --datum D_MOON                       \
    --ip-per-image 10000                 \
    --match-first-to-last                \
    --max-pairwise-matches 800           \
    --min-matches 1                      \
    --min-triangulation-angle 0.1        \
    --num-iterations 1000                \
    --num-passes 2                       \
    --remove-outliers-params             \
    "75.0 3.0 150 150"                   \
    --overlap-limit 50                   \
    --parameter-tolerance 1e-12          \
    --robust-threshold $th               \
    $opt                                 \
    -o $outPrefix                        \
    >> $out 2>&1
