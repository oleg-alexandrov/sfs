#!/bin/bash

#if [ "$#" -lt 1 ]; then echo Usage: $0 argName; exit; fi

val=$1

file1=$2
file2=$3

if [ "$file1" = "$file2" ]; then echo equal; exit; fi
if [ "$val" -le 0 ]; then echo val must be positive; exit; fi

num=$(~/bin/intersect_files.pl $file1 $file2 | grep -i http | wc -l)
echo total is $num

if [ "$val" -gt "$num" ]; then echo out of bounds; exit; fi

link=$(~/bin/intersect_files.pl $file1 $file2 | grep -i http | head -n $val | ~/bin/print_col.pl 8 | tail -n 1 | perl -pi -e "s#,\s*\$##g")

echo $link

../sfs/fetch_lro.sh "$link"
