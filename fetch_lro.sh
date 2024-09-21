#!/bin/bash

if [ "$#" -lt 1 ]; then echo Usage: $0 link dem; exit; fi

# TODO(oalexan1): This must be a documented tool.

# Steps to do before using this script:
#  - Visit http://ode.rsl.wustl.edu/moon/indexproductsearch.aspx
#  - Select the LROC EDR product, a search area, and search.
#  - Click to view the results in a table.
#  - Click on "Output Results" (which takes forever).
#  - Save the obtained text file.
#  - Pass each of those links to this script, as:

# link="https://ode.rsl.wustl.edu/moon/productPageAtlas.aspx?product_id=M104270814LE&product_idGeo=16375385"
# ./fetch_lro.sh "$link"

# To call this on a portion of that list, run:

# ./fetch_chunk.sh list.txt beg end
# which will call this script.

# Note that below we parse some html, which is fragile, as the html code can easily change,
# and then this script will breka.

link=$1
dem=$2

if [ "$(echo $link | grep -i .img)" != "" ]; then
    echo This is already the direct link
    url=$link
else
    # Fetch the page at the link
    id=$(echo $link | perl -p -e "s#^.*?product_id=(\w*).*?\$#\$1#g")
    
    out=$id.html
    echo Fetch: $link
    wget "$link" -O $out  > /dev/null 2>&1
    
    # Parse the url to the actual product. Can have both http and https
    url=$(cat $out | grep $id.IMG |grep lroc.asu.edu | head -n 1 | perl -p -e "s#^.*?(http\w*://pds.lroc.asu.edu[^\'\"]*?IMG).*?\n#\$1#g")
fi

echo url=$url

# If no luck, need to go to a subpage first
if [ "$url" = "" ]; then
    key=$(cat $out |grep -i "frame name" |grep -i productPageAtlas | perl -p -e "s#^.*?src=\"(productPageAtlas.*?)\".*?\n#\$1#g")

    key="http://ode.rsl.wustl.edu/moon/$key"
    echo Fetch: $key

    wget "$key" -O $out > /dev/null 2>&1

    key=$(cat $out |grep -i "ASU" | grep -i hlExternalLink | perl -p -e "s#^.*?href=\"(.*?)\".*?\$#\$1#g")
    echo Fetch: $key
    wget "$key" -O $out > /dev/null 2>&1

    url=$(cat $out |grep -i "Download EDR" | perl -p -e "s#^.*?href=\"(.*?)\".*?\$#\$1#g")
    echo url=$url
fi

# Fetch the .IMG
prefix=$(echo $url| perl -p -e "s#^.*\/(.*?)\..*?\$#\$1#g")
img="$prefix.IMG"

while [ ! -f "$img" ]; do
    echo Fetch: $url
    # Must redirect the output of /usr/bin/time to stdout to be appended to the file
    # in the right place.
    prog="wget"
    out="$img.out.txt" # to avoid verbose printing
    /usr/bin/time -f "$prog finished. Elapsed=%E memory=%M (kb)." $prog $url > $out 2>&1
    grep Elapsed $out
    
    if [ ! -f "$img" ]; then
        echo "Error: Failed to fetch $img. Sleep for 30 seconds and try again."
        sleep 30
    fi
done
    
echo "File exists: $img"

cub="$prefix.cal.echo.cub"
cam="$prefix.cal.echo.json"
map="$prefix.cal.echo.map.tr10.tif"

if [ -f "$cub" ]; then  
    echo Will use local cub file $cub
else
    lronac2isis from = $img to = $prefix.cub 
    spiceinit from = $prefix.cub 
    lronaccal from = $prefix.cub to = $prefix.cal.cub
    lronacecho from = $prefix.cal.cub to = $cub
fi

if [ -f "$cam" ]; then  
    echo Will use local cam file $cam
else
    $HOME/miniconda3/envs/ale_env/bin/python ~/projects/sfs/gen_csm.py $cub
fi


if [ ! -f "$cub" ]; then echo "Error: Missing cub file $cub"; exit 1; fi
if [ ! -f "$cam" ]; then echo "Error: Missing cam file $cam"; exit 1; fi

if [ ! -f "$map" ]; then
    prog=mapproject
    /usr/bin/time -f "$prog finished. Elapsed=%E memory=%M (kb)." $prog --tr 10 $dem $cub $cam $map
else
    echo Will use local map file $map
fi

stereo_gui --create-image-pyramids-only $map

