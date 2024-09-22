#!/bin/bash

# Fetch a block of links from a list.
# Let w be the block size, and i the block index.
# will fetch from i * w to (i+1) * w - 1, inclusive.

if [ "$#" -lt 3 ]; then echo Usage: $0 list.txt w i; exit; fi

list=$1; shift
w=$1; shift
i=$1; shift

if [ ! -f "$list" ]; then echo "Error: Missing list file $list"; exit 1; fi
if [ "$w" = "" ]; then echo "Error: Missing w"; exit 1; fi
if [ "$i" = "" ]; then echo "Error: Missing i"; exit 1; fi

# Find the number lines in list
n=$(cat $list | wc -l)
echo n=$n

beg=$((i*w))
end=$(( (i+1)*w ))
echo beg=$beg end=$end, total is $n

export ISISDATA=$HOME/projects/isis3data
export ISISROOT=$HOME/miniconda3/envs/asp_deps
export ALESPICEROOT=$ISISDATA

s=StereoPipeline-3.4.0-alpha-2023-09-17-x86_64-Linux
export PATH=$HOME/projects/BinaryBuilder/$s/bin:$ISISROOT/bin:$PATH

mapproject=$(which mapproject)
if [ ! -f "$mapproject" ]; then
    echo "Error: Missing mapproject command. Ensure ASP is in the path."
    exit 1
fi

lronac2isis=$(which lronac2isis)
if [ ! -f "$lronac2isis" ]; then
    echo "Error: Missing lronac2isis command. Ensure an ISIS environment is in the path."
    exit 1
fi

if [ "$ISISDATA" = "" ]; then
    echo "Error: Must set ISISDATA."
    exit 1
fi

echo Will run $0 $list $beg $end $dem

for ((i=beg; i < end; i++)); do
    echo index is $i

    # Can have both http and https
    link=$(cat $list | head -n $i | tail -n 1)

    if [ "$link" = "" ]; then
       # This is a failure, skip
       echo "Error: Failed to get link at index $i"
       continue
    fi

    ~/projects/sfs/fetch_lro.sh $link $dem
done

