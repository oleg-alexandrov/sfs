#!/bin/bash

if [ "$#" -lt 6 ]; then echo Usage: $0 dem baPrefix exposures estimError outPrefix currDir; exit; fi

dem=$1
baPrefix=$2
exposures=$3
estimError=$4
outPrefix=$5
currDir=$6

# If estimError is 1, the DEM passed in must be the produced SfS DEM (after sfs_blend).
# On output, it will write:
# <output prefix>-height-error.tif
# The DEM will not change.

# Note. Exposures have been precomputed.

cd $currDir

export ISISDATA=$HOME/projects/isis3data
export ISISROOT=$HOME/miniconda3/envs/isis5.0.1
export ALESPICEROOT=$ISISDATA
s=StereoPipeline-3.1.1-alpha-2022-08-06-x86_64-Linux
export PATH=/home6/oalexan1/projects/BinaryBuilder/$s/bin:$PATH

outDir=$(dirname $outPrefix)
out=output_${outDir}.txt
err=error_${outDir}.txt

rm -fv $out $err
echo Writing: $out $err

if [ "$PBS_NODEFILE" = "" ]; then
    # To run locally
    PBS_NODEFILE=$(uname -n).txt
    echo $(uname -n) > $PBS_NODEFILE
fi
echo Head node: $(uname -n) >> $out
echo Machines: $(cat ${PBS_NODEFILE}) >> $out

cubes=$(cat $exposures | perl -pi -e "s#^.*?(M\d+[LR]E).*?\n#cubes/\$1.cal.echo.cub #g")
cams=$(cat  $exposures | perl -pi -e "s#^.*?(M\d+[LR]E).*?\n#cubes/\$1.cal.echo.json #g")

# About 650 jobs with 10 jobs per machine. Each job takes maybe an
# hour or two. Use 8 machines for 16 hours.

# Note that we precomputed the exposures. That was done with:
#    --compute-exposures-only

mkdir -p $(dirname $outPrefix)
/bin/cp -fv $exposures ${outPrefix}-exposures.txt

opt=""
if [ "$estimError" -eq "1" ]; then
    opt="--estimate-height-errors"
fi

parallel_sfs --resume                     \
    -i $dem $cubes $cams                  \
    --shadow-threshold 0.005              \
    --bundle-adjust-prefix $baPrefix      \
    -o $outPrefix                         \
    --crop-input-images                   \
    --blending-dist 10                    \
    --min-blend-size 50                   \
    --threads 4                           \
    --smoothness-weight 0.08              \
    --initial-dem-constraint-weight 0.001 \
    --reflectance-type 1                  \
    --max-iterations 5                    \
    --save-sparingly                      \
    --tile-size 200 --padding 50          \
    --processes 10                        \
    --nodes-list ${PBS_NODEFILE}          \
    --image-exposures-prefix $outPrefix   \
    $opt                                  \
    >> $out 2> $err


