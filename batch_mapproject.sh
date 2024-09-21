#!/bin/bash

if [ "$#" -lt 6 ]; then echo Usage: $0 dem.tif list.txt beg end mapDir currDir; exit; fi

dem=$1
list=$2
beg=$3
end=$4
mapDir=$5
currDir=$6

cd $currDir

export ISISDATA=$HOME/projects/isis3data
export ISISROOT=$HOME/miniconda3/envs/isis5.0.1
export ALESPICEROOT=$ISISDATA
s=StereoPipeline-3.1.1-alpha-2022-08-06-x86_64-Linux
export PATH=/home6/oalexan1/projects/BinaryBuilder/$s/bin:$PATH

mkdir -p ${mapDir}

out=output_${mapDir}_${beg}_${end}.txt
rm -f $out

for f in $(cat $list | ~/bin/print_line_range.pl $beg $end | ~/bin/print_col.pl 1 | perl -pi -e "s#^.*?(M.*?)\..*?\n#\$1\n#g"); do

    mapproject --tile-size 2048 --processes 10 --tr 1 \
        $dem cubes/$f.cal.echo.cub cubes/$f.cal.echo.json \
        ${mapDir}/$f.cal.echo.map.tr1.tif >> $out
    
    stereo_gui --create-image-pyramids-only ${mapDir}/$f.cal.echo.map.tr1.tif >> $out

done
