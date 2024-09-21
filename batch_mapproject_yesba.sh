#!/bin/bash

if [ "$#" -lt 5 ]; then echo Usage: $0 dem.tif list.txt beg end currDir; exit; fi

dem=$1
list=$2
baPrefix=$3
beg=$4
end=$5
currDir=$6

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

baDir=$(dirname $baPrefix)
if [[ "$baDir" = "" ]]; then
    echo Expecting an output prefix, got: $baDir
    exit 1
fi

mapDir=map_tr1_${baDir}
mkdir -p ${mapDir}

out=output_${mapDir}_${beg}_${end}.txt
rm -f $out
echo Writing: $out

for f in $(cat $list | ~/bin/print_line_range.pl $beg $end | ~/bin/print_col.pl 1 | perl -pi -e "s#^.*?(M.*?)\..*?\n#\$1\n#g"); do

    mapproject --tile-size 2048 --processes 10 --tr 1     \
        --bundle-adjust-prefix $baPrefix                  \
        $dem cubes/$f.cal.echo.cub cubes/$f.cal.echo.json \
        ${mapDir}/$f.cal.echo.map.tr1.tif                 \
        --nodes-list $PBS_NODEFILE >> $out
    
    stereo_gui --create-image-pyramids-only ${mapDir}/$f.cal.echo.map.tr1.tif >> $out
done
