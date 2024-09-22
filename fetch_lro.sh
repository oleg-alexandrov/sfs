#!/bin/bash

if [ "$#" -lt 1 ]; then echo Usage: $0 link dem; exit; fi

# TODO(oalexan1): This must be a documented tool.

# Steps to do before using this script:
#  - Visit http://ode.rsl.wustl.edu/moon/indexproductsearch.aspx
#  - Select the LROC EDR product, NAC option, a search area, and search.
#  - Click to view the results in a table.
#  - Click on "Output Results" (which takes forever).
#  - Save the obtained text file.
#  - Pass each of those links to this script, as:

# link="https://ode.rsl.wustl.edu/moon/productPageAtlas.aspx?product_id=M104270814LE&product_idGeo=16375385"
# ./fetch_lro.sh "$link"

# To call this on a portion of that list, run:

# ./fetch_chunk.sh list.txt chunkSize chunkIndex
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
    id=$(echo $link | perl -p -e "s#^.*?product_id=\w*\.*([\w]*?)\&.*?\$#\$1#g") 
    out=$id.html
    echo Fetch: $link and save to $out
    wget "$link" -O $out  > /dev/null 2>&1
    
    # Parse the url to the actual product. Can have both http and https
    url=$(grep -i $id $out |grep -i href |grep IMG | head -n 1 | perl -pi -e "s#^.*?href=\"(.*?\.IMG).*?\$#\$1#g" |grep -i $id)
fi

echo url=$url

# If empty, that means we failed, so exit
if [ "$url" == "" ]; then 
echo "Error: Failed to parse the url from the page $link"; 
  exit 1; 
fi

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
    $HOME/miniconda3/envs/asp_deps/bin/python ~/projects/sfs/gen_csm.py $cub
fi

if [ ! -f "$cub" ]; then echo "Error: Missing cub file $cub"; exit 1; fi
if [ ! -f "$cam" ]; then echo "Error: Missing cam file $cam"; exit 1; fi

# if dem is not an empty string, then we will use it
if [ "$dem" != "" ]; then
    if [ ! -f "$map" ]; then
        prog=mapproject
        /usr/bin/time -f "$prog finished. Elapsed=%E memory=%M (kb)." $prog --tr 10 $dem $cub $cam $map --processes 4 --threads 2
    else
        echo Will use local map file $map
    fi

    stereo_gui --create-image-pyramids-only $map
fi
