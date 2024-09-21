#!/bin/bash

# Fetch links from list. Start at $beg, and stop before $end. 

if [ "$#" -lt 3 ]; then echo Usage: $0 list.txt beg end; exit; fi

list=$1
beg=$2
end=$3
dem=$4

if [ ! -f "$list" ]; then echo "Error: Missing list file $list"; exit 1; fi
if [ ! -f "$dem" ]; then echo "Error: Missing dem file $dem"; exit 1; fi

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
    link=$(cat $list | grep "Experiment Data Record" | head -n $i | tail -n 1 | \
        perl -p -e "s#,#\n#g" |grep http | head -n 1 | perl -p -e "s#\s##g")

    if [ "$link" = "" ]; then
        # When the links are already direct links to IMG
        link=$(cat $list | head -n $i | tail -n 1 |grep -i .img)
    fi

    if [ "$link" = "" ]; then
        echo Invalid link "$link", will skip
        continue
    fi
        
    ~/projects/sfs/fetch_lro.sh $link $dem
done

