#!/bin/bash

#if [ "$#" -lt 1 ]; then echo Usage: $0 argName; exit; fi

img=$1
reg=$2
tile=$3
crop=0
level=$4
ref=$5

# These have light on right rim and left rim (h and the next ones)
a=M134985003LE.cal.echo_crop; b=M134991788LE.cal.echo_crop; c=M165645700LE.cal.echo_crop; d=M1142241002LE.cal.echo_crop; e=M101949648RE.cal.echo_crop; g=M111578606LE.cal.echo_crop; h=M116113215RE.cal.echo_crop; j=M162107606LE.cal.echo_crop; k=M192753724RE.cal.echo_crop

if [ 1 -eq 0 ]; then
    bundle_adjust $a.cub $b.cub $d.cub $j.cub -o run_ap17_joint4/run --min-matches 1
    stereo $a.cub $b.cub --bundle-adjust-prefix run_ap17_joint4/run --subpixel-mode 3 run_ap17_stereo/run
    sg $a.map.tif $b.map.tif $c.map.tif $d.map.tif $e.map.tif
    
    point2dem -r moon --csv-format '2:lon 3:lat 4:radius_km' --tr 1 --stereographic --proj-lon 30.7385670 --proj-lat 20.1849495 ap17_joint_stereo/run-PC.tif 
    
    pc_align --csv-format '2:lon 3:lat 4:radius_km' --max-displacement 200 --save-transformed-source-points --save-inv-transformed-reference-points ap17_joint_stereo/run-PC.tif RDR_30E30E_20N20NPointPerRow_csv_table.csv -o ap17_joint_stereo/run
    
    #Translation vector (North-East-Down, meters): Vector3(-29.4882,17.0869,-5.14998)
    #Translation vector magnitude (meters): 34.468
    #Input: error percentile of smallest errors (meters): 16%: 3.57347, 50%: 5.90617, 84%: 8.4811
    #Output: error percentile of smallest errors (meters): 16%: 0.408301, 50%: 1.02077, 84%: 2.11099
    
    point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon 30.7385670 --proj-lat 20.1849495 ap17_joint_stereo/run-trans_source.csv
    
    diff.sh ap17_joint_stereo/run-DEM.tif ap17_joint_stereo/run-trans_source-DEM.tif

    bundle_adjust $a.cub $b.cub $d.cub $j.cub -o run_ap17_joint4/run --min-matches 1
    stereo $a.cub $b.cub --bundle-adjust-prefix run_ap17_joint4/run --subpixel-mode 3 \
        run_ap17_stereo/run

    point2dem -r moon --csv-format '2:lon 3:lat 4:radius_km' --stereographic --proj-lon 30.7385670 --proj-lat 20.1849495 --tr 1 run_ap17_stereo/run-PC.tif
    
    pc_align --csv-format '2:lon 3:lat 4:radius_km' --max-displacement 200 --save-transformed-source-points --save-inv-transformed-reference-points run_ap17_stereo/run-PC.tif RDR_30E30E_20N20NPointPerRow_csv_table.csv -o run_ap17_stereo/run

    point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon 30.7385670 --proj-lat 20.1849495 run_ap17_stereo/run-trans_source.csv

    # Note that crop15 was overwritten!!!!!! Get it back !!!!
    diff.sh run_ap17_stereo/run-trans_source-DEM.tif run_ap17_stereo/run-DEM.tif
    diff.sh run_ap17_stereo/run-trans_source-DEM.tif  run_ap17_stereo/run-crop12-DEM.tif
    diff.sh run_ap17_stereo/run-crop12-DEM.tif sfs_bdj_crop12_reg0.10_level2/run-DEM-final-level0.tif
    diff.sh run_ap17_stereo/run-crop12-DEM.tif sfs_bdj_crop12_reg0.06_level2/run-DEM-final-level0.tif
    echo " "
    
    diff.sh run_ap17_stereo/run-trans_source-DEM.tif run_ap17_stereo/run-DEM.tif
    diff.sh run_ap17_stereo/run-trans_source-DEM.tif  run_ap17_stereo/run-crop13-DEM.tif
    diff.sh run_ap17_stereo/run-crop13-DEM.tif sfs_bdj_crop13_reg0.10_level2/run-DEM-final-level0.tif
    diff.sh run_ap17_stereo/run-crop13-DEM.tif sfs_bdj_crop13_reg0.06_level2/run-DEM-final-level0.tif
    echo " "


ref=0

rm -fv output_ref$ref.txt
lola=run_ap17_stereo/run-trans_source-DEM.tif
dem=run_ap17_stereo/run-DEM.tif
for c in 12 13 14 15 16 17 18 19 20 21; do
    echo $c
    beg=run_ap17_stereo/run-crop${c}-DEM.tif
    end=sfs_bdj_crop${c}_reg0.06_level2_ref${ref}/run-DEM-final-level0.tif
    g=${end/.tif/}
    align_end=$g-trans_source-DEM.tif

    rm -fv $g-trans_source.tif $align_end
    echo $beg $end $align_end >> output_ref$ref.txt
    pc_align --max-displacement -1 -o $g --save-transformed-source-points $beg $end 2>&1 \
        | g "Translation vector magnitude"
    
    point2dem --tr 1 --search-radius-factor 2 -r moon --stereographic --proj-lon 30.7385670 --proj-lat 20.1849495 $g-trans_source.tif > /dev/null 2>&1
    
    echo Ref    $(diff.sh $lola $dem $ref 2>/dev/null) >> output_ref$ref.txt
    echo Bf SfS $(diff.sh $lola $beg $ref 2>/dev/null)                        >> output_ref$ref.txt
    echo Af SfS $(diff.sh $lola $end $ref 2>/dev/null)                        >> output_ref$ref.txt
    echo Af Al  $(diff.sh $lola $align_end $ref 2>/dev/null)                  >> output_ref$ref.txt
    echo " "                                                                  >> output_ref$ref.txt
done
  
  gdt run_ap17_stereo/run-DEM.tif -srcwin 894 647 444 247  run_ap17_stereo/run-crop12-DEM.tif
  gdt run_ap17_stereo/run-DEM.tif -srcwin 826 1067 500 279 run_ap17_stereo/run-crop13-DEM.tif
  gdt run_ap17_stereo/run-DEM.tif -srcwin 548 641 749 423  run_ap17_stereo/run-crop14-DEM.tif
  gdt run_ap17_stereo/run-DEM.tif -srcwin 262 1338 896 605 run_ap17_stereo/run-crop16-DEM.tif
  gdt run_ap17_stereo/run-DEM.tif -srcwin 648 991 717 393  run_ap17_stereo/run-crop17-DEM.tif
  gdt run_ap17_stereo/run-DEM.tif -srcwin 670 510 667 454  run_ap17_stereo/run-crop18-DEM.tif
  gdt run_ap17_stereo/run-DEM.tif -srcwin 240 158 823 420  run_ap17_stereo/run-crop19-DEM.tif
  gdt run_ap17_stereo/run-DEM.tif -srcwin 273 2334 779 420 run_ap17_stereo/run-crop20-DEM.tif
  gdt run_ap17_stereo/run-DEM.tif -srcwin 262 3492 807 415 run_ap17_stereo/run-crop21-DEM.tif
  
fi


if [ "$img" = "abc" ]; then str="$a.cub $b.cub $c.cub"; fi
if [ "$img" = "abd" ]; then str="$a.cub $b.cub $d.cub"; fi
if [ "$img" = "abe" ]; then str="$a.cub $b.cub $e.cub"; fi
if [ "$img" = "abcd" ]; then str="$a.cub $b.cub $c.cub $d.cub"; fi
if [ "$img" = "abce" ]; then str="$a.cub $b.cub $c.cub $e.cub"; fi
if [ "$img" = "abde" ]; then str="$a.cub $b.cub $d.cub $e.cub"; fi
if [ "$img" = "bdj" ]; then str="$b.cub $d.cub $j.cub"; fi

if [ "$crop" -eq 1 ]; then win="286 1378 835 734"; fi
if [ "$crop" -eq 2 ]; then win="689 594 812 773"; fi
if [ "$crop" -eq 3 ]; then win="314 107 751 695"; fi
if [ "$crop" -eq 4 ]; then win="669 970 671 416"; fi
if [ "$crop" -eq 5 ]; then win="621 550 708 486"; fi
if [ "$crop" -eq 6 ]; then win="259 668 1608 1202"; fi

#gdal_translate -srcwin $win ap17_joint_stereo/run-DEM.tif ap17_joint_stereo/run-crop$crop-DEM.tif

#dir=sfs_${img}_crop${crop}_reg${reg}_level${level}_ref${ref}
dir=sfs_${img}_tile${tile}_reg${reg}_level${level}_ref${ref}_fixex2

mkdir -p $dir
#gdal_translate -srcwin $win ap17_joint_stereo/run-DEM.tif $dir/run-crop$crop-DEM.tif
#~/projects/StereoPipeline/src/asp/Tools/sfs -i run_ap17_stereo/run-crop$crop-DEM.tif $str -o $dir/run --threads 4 --smoothness-weight $reg --max-iterations 100 --reflectance-type $ref --float-exposure --float-cameras --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix run_ap17_joint4/run

sfs -i run_ap17_stereo_tiles2/tile-${tile}.tif M134991788LE.cal.echo_crop.cub M1142241002LE.cal.echo_crop.cub M162107606LE.cal.echo_crop.cub -o $dir/run --threads 4 --smoothness-weight $reg --max-iterations 100 --reflectance-type $ref --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix sfs_bdj_crop19_reg0.06_level2_ref1/run --image-exposures-prefix sfs_bdj_crop19_reg0.06_level2_ref1/run
