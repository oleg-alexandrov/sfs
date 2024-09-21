#!/bin/bash

if [ "$#" -lt 8 ]; then echo Usage: $0 list a ht w qn numProc dem ba currDir; exit; fi

# Run jitter_solve. The list must have, on each line text of the form:
# <something>M<digits>{LE,RE}<something>. Extra text in it will be wiped,
# only the id will be kept: M<digits>{LE,RE}.
#
# Conventions for inputs:
# Images: cubes/<id>.cal.echo.cub
# Cameras: cubes/<id>.cal.echo.json

list=$1
a=$2
ht=$3
w=$4
qn=$5
numProc=$6
dem=$7
ba=$8
currDir=$9

cd $currDir
suff=$(echo $list | perl -pi -e "s#.txt##g")

export ISISDATA=$HOME/projects/isis3data
export ISISROOT=$HOME/miniconda3/envs/isis5.0.1
export ALESPICEROOT=$ISISDATA
s=StereoPipeline-3.1.1-alpha-2022-08-06-x86_64-Linux
export PATH=/home6/oalexan1/projects/BinaryBuilder/$s/bin:$PATH

win=$(~/bin/gdal_win.sh ${dem})

pref=jitter_v2_w${w}_qn${qn}_ht${ht}_a${a}_${suff} # produced optimized cameras

out=output_${pref}.txt
rm -fv $out
echo Writing: $out

if [ "$PBS_NODEFILE" = "" ]; then
    # To run locally
    PBS_NODEFILE=$(uname -n).txt
    echo $(uname -n) > $PBS_NODEFILE
fi
echo Head node: $(uname -n) >> $out
echo Machines: $(cat ${PBS_NODEFILE}) >> $out

images=$(cat $list | perl -pi -e "s#^.*?(M.*?E).*?\n#cubes/\$1.cal.echo.cub\n#g")
cameras=$(cat $list | perl -pi -e "s#^.*?(M.*?E).*?\n#cubes/\$1.cal.echo.json\n#g")
names=$(cat $list | perl -p -e "s#^.*?(M\d+\wE).*?(\s)\$#\$1\$2#g")

opts="elapsed=%E (hours:minutes:seconds), memory=%M (kb)"
/usr/bin/time -f "$opts"                              \
jitter_solve $images $cameras                         \
    --clean-match-files-prefix ba/run                 \
    --input-adjustments-prefix ${ba}/run              \
    --heights-from-dem lola/lola_clip_v2_big.tif      \
    --max-initial-reprojection-error 20               \
    -o $pref/run --num-iterations 200                 \
    --rotation-weight $w --translation-weight $w      \
    --quat-norm-weight $qn                            \
    --heights-from-dem-weight $ht                     \
    --heights-from-dem-robust-threshold $ht           \
    --anchor-weight $a >> $out 2>&1
# for t in $names; do
#     # Mapproject with optimized cameras
#     mapproject ${dem}                                 \
#         --t_projwin $win --tr 1                       \
#         --processes $numProc                          \
#         --nodes-list $PBS_NODEFILE                    \
#         cubes/${t}.cal.echo.cub                       \
#         ${pref}/run-${t}.cal.echo.adjusted_state.json \
#         ${pref}/${t}.after.tif # >> /dev/null
#     # Mapproject with original cameras
#     mapproject ${dem}                                 \
#         --t_projwin $win --tr 1                       \
#         --processes $numProc                          \
#         --nodes-list $PBS_NODEFILE                    \
#         cubes/${t}.cal.echo.cub                       \
#         cubes/${t}.cal.echo.json                      \
#         --bundle-adjust-prefix ${ba}/run              \
#         ${pref}/${t}.before.tif # >> /dev/null
# done
