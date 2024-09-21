#!/bin/bash

if [ "$#" -lt 1 ]; then echo Usage: $0 argName; exit; fi

id=$1
crop=$2

if [ 1 -eq 0 ]; then 
tile=$1 # fix
    
# These have light on right rim and left rim (h and the next ones)
a=M134985003LE.cal.echo_crop; b=M134991788LE.cal.echo_crop; c=M165645700LE.cal.echo_crop; d=M1142241002LE.cal.echo_crop; e=M101949648RE.cal.echo_crop; g=M111578606LE.cal.echo_crop; h=M116113215RE.cal.echo_crop; j=M162107606LE.cal.echo_crop; k=M192753724RE.cal.echo_crop

tile=$1

prog=$0
dir=$(dirname $prog)
cd $dir
pwd


wt=4000
ref=0
ref2=1
fm=0 # float model
img=bdj
crop=0
level=0

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

    # to visualize easier
    point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon 30.7385670 --proj-lat 20.1849495 run_ap17_stereo/run-trans_source.csv -o run_ap17_stereo/run-trans_source-search5 --search-radius-factor 5


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

er=20; dem_mosaic --weights-exponent 2 --erode-length $er --use-centerline-weights sfs_dbj_tile01_reg0.06_level0_ref0_wt4000/run-DEM-final.tif -o ap17_ba_stereo_dabkj2/run-after-sfs

lola17=ap17_ba_stereo_dabkj2/run-trans_source-DEM.tif

  di $lola17 ap17_ba_stereo_dabkj2/run-before-sfs-tile-0-crop.tif
  Minimum=0.003, Maximum=2.236, Mean=0.752, StdDev=0.445

  di $lola17 ap17_ba_stereo_dabkj2/run-after-sfs-tile-0-crop.tif
  Minimum=0.000, Maximum=2.437, Mean=0.729, StdDev=0.543

  
rm -fv output3_ref$ref.txt
lola=run_ap17_stereo/run-trans_source-DEM.tif
dem=run_ap17_stereo/run-DEM.tif
for c in 1 2 3 4 91 92 93 94 95 96; do
#for c in 1 2 3 4 5 6 7; do
#for c in 12 13 14 15 16 17 18 19 20 21; do
    echo $c
    #beg=run_ap17_stereo/run-crop${c}-DEM.tif
    #end=sfs_bdj_crop${c}_reg0.06_level2_ref${ref}/run-DEM-final-level0.tif
    #beg=run_ap17_stereo_tiles/tile-${c}.tif
    #end=sfs_bdj_tile${c}_reg0.06_level0_ref${ref}_fixex/run-DEM-final.tif
    beg=run_ap17_stereo_tiles2/tile-${c}.tif
    end=sfs_bdj_tile${c}_reg0.06_level0_ref${ref}_fixex2/run-DEM-final.tif
    g=${end/.tif/}
    align_end=$g-trans_source-DEM.tif

    rm -fv $g-trans_source.tif $align_end
    echo $beg $end $align_end
    echo $beg $end $align_end >> output3_ref$ref.txt
    pc_align --max-displacement -1 -o $g --save-transformed-source-points $beg $end 2>&1 \
        | g "Translation vector magnitude"
    
    point2dem --tr 1 --search-radius-factor 2 -r moon --stereographic --proj-lon 30.7385670 --proj-lat 20.1849495 $g-trans_source.tif > /dev/null 2>&1
    
    echo Ref    $(diff.sh $lola $dem $ref 2>/dev/null) >> output3_ref$ref.txt
    echo Bf SfS $(diff.sh $lola $beg $ref 2>/dev/null)                        >> output3_ref$ref.txt
    echo Af SfS $(diff.sh $lola $end $ref 2>/dev/null)                        >> output3_ref$ref.txt
    echo Af Al  $(diff.sh $lola $align_end $ref 2>/dev/null)                  >> output3_ref$ref.txt
    echo " "                                                                  >> output3_ref$ref.txt

    er=20; dem_mosaic --weights-exponent 2 --erode-length $er --use-centerline-weights sfs_bdj_tile*_reg0.06_level0_refw0_wt500/*DEM-final.tif -o run_ap17_stereo/mosaic_refw0_wt500
    
    er=20; dem_mosaic --weights-exponent 2 --erode-length $er --use-centerline-weights sfs_bdj_tile*_reg0.06_level0_refw1_wt500/*DEM-final.tif -o run_ap17_stereo/mosaic_refw1_wt500
    
    gdt -projwin -699.500 1779.500 413.500 -45.500 run_ap17_stereo/run-DEM.tif run_ap17_stereo/tiles5-tile-0.tif

    gdt -projwin -670 1750 385 -13 run_ap17_stereo/tiles5-tile-0.tif run_ap17_stereo/tiles5-crop.tif
    gdt -projwin -670 1750 385 -13 run_ap17_stereo/mosaic_refw0_wt500-tile-0.tif run_ap17_stereo/mosaic_refw0_wt500-crop.tif
    gdt -projwin -670 1750 385 -13 run_ap17_stereo/mosaic_refw1_wt500-tile-0.tif run_ap17_stereo/mosaic_refw1_wt500-crop.tif

    di $lola run_ap17_stereo/tiles5-crop.tif
    di $lola run_ap17_stereo/mosaic_refw0_wt500-crop.tif
    di $lola run_ap17_stereo/mosaic_refw1_wt500-crop.tif

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

  ap17_ba_stereo_dabkj2/run-after-sfs-tile-0.tif


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
#dir=sfs_${img}_tile${tile}_reg${reg}_level${level}_ref${ref}_fixex
#mkdir -p $dir
#gdal_translate -srcwin $win ap17_joint_stereo/run-DEM.tif $dir/run-crop$crop-DEM.tif
#~/projects/StereoPipeline/src/asp/Tools/sfs -i run_ap17_stereo/run-crop$crop-DEM.tif $str -o $dir/run --threads 4 --smoothness-weight $reg --max-iterations 100 --reflectance-type $ref --float-exposure --float-cameras --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix run_ap17_joint4/run

#sfs -i run_ap17_stereo_tiles/tile-${tile}.tif M134991788LE.cal.echo_crop.cub M1142241002LE.cal.echo_crop.cub M162107606LE.cal.echo_crop.cub -o $dir/run --threads 4 --smoothness-weight $reg --max-iterations 100 --reflectance-type $ref --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix sfs_bdj_crop${crop}_reg${reg}_level2_ref1/run --image-exposures-prefix sfs_bdj_crop${crop}_reg${reg}_level2_ref1/run

opt=""
if [ "$fm" -eq 1 ]; then opt=" --float-reflectance-model "; fi


#~/projects/StereoPipeline/src/asp/Tools/sfs -i run_ap17_stereo/run-crop${crop}-DEM.tif M134991788LE.cal.echo_crop.cub M1142241002LE.cal.echo_crop.cub M162107606LE.cal.echo_crop.cub -o sfs_bdj_crop${crop}_reg${reg}_level${level}_refv${ref}_wt${wt}/run --threads 4 --smoothness-weight ${reg} --max-iterations 100 --reflectance-type $ref --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix sfs_bdj_crop${crop}_reg${reg}_level2_ref${ref2}/run --image-exposures-prefix sfs_bdj_crop${crop}_reg${reg}_level2_ref${ref2}/run --float-cameras --initial-dem-constraint-weight $wt  $opt --float-exposure

~/projects/StereoPipeline/src/asp/Tools/sfs -i run_ap17_stereo_tiles4/tile-$tile.tif M134991788LE.cal.echo_crop.cub M1142241002LE.cal.echo_crop.cub M162107606LE.cal.echo_crop.cub -o sfs_bdj_tile${tile}_reg${reg}_level${level}_refw${ref}_wt${wt}/run --threads 4 --smoothness-weight ${reg} --max-iterations 100 --reflectance-type $ref --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix sfs_bdj_crop19_reg0.06_level0_refv${ref}_wt500/run --image-exposures-prefix sfs_bdj_crop19_reg0.06_level0_refv${ref}_wt500/run --initial-dem-constraint-weight $wt  $opt


qsub -N job -l select=1:ncpus=1:model=wes -l walltime=15:30:00 -W group_list=s1704 -j oe -m n -- ~/bin/time_run.sh $HOME/bin/driver.sh $(pwd)/output_sfs_dbj_crop19_reg${reg}_level${level}_refv${ref}_wt${wt}_yesrpc.txt $(pwd) ~/projects/StereoPipeline/src/asp/Tools/sfs -i ap17_ba_stereo_dabkj2/run-crop19-DEM.tif $d.cub $b.cub $j.cub -o sfs_dbj_crop19_reg${reg}_level${level}_refv${ref}_wt${wt}_yesrpc/run --threads 4 --smoothness-weight ${reg} --max-iterations 50 --reflectance-type $ref --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix ap17_ba_map_dabkj2/run --float-cameras --initial-dem-constraint-weight ${wt}  --float-exposure --use-rpc-approximation

level=0; ref=0; for th in 1000 2000 4000; do 
    qsub -N job -l select=1:ncpus=1:model=wes -l walltime=15:30:00 -W group_list=s1704 -j oe -m n -- ~/bin/time_run.sh $HOME/bin/driver.sh $(pwd)/output_sfs_dbj_crop19_reg${reg}_level${level}_refv${ref}_wt${wt}_yesrpc_fixcam.txt $(pwd) ~/projects/StereoPipeline/src/asp/Tools/sfs -i ap17_ba_stereo_dabkj2/run-crop19-DEM.tif $d.cub $b.cub $j.cub -o sfs_dbj_crop19_reg${reg}_level${level}_refv${ref}_wt${wt}_yesrpc_fixcam/run --threads 4 --smoothness-weight ${reg} --max-iterations 50 --reflectance-type $ref --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix sfs_dbj_crop19_reg0.06_level0_refv0_wt1000_yesrpc/run  --image-exposures-prefix sfs_dbj_crop19_reg0.06_level0_refv0_wt1000_yesrpc/run --initial-dem-constraint-weight ${wt}  --use-rpc-approximation
done

fi

id=$(echo $tile | perl -pi -e "s#^.*?tile-(\d+).*?\$#\$1#g")

echo $tile $id

dir=sfs_dbj_tile${id}_reg${reg}_level${level}_ref${ref}_wt${wt}

echo id is $id      > output_${dir}.txt # init the file
echo pwd is $(pwd) >> output_${dir}.txt
echo tile is $tile >> output_${dir}.txt

echo sleep6 >> output_${dir}.txt
sleep 2;
#exit

a=M134985003LE.cal.echo_crop; b=M134991788LE.cal.echo_crop; c=M165645700LE.cal.echo_crop; d=M1142241002LE.cal.echo_crop; e=M101949648RE.cal.echo_crop; g=M111578606LE.cal.echo_crop; h=M116113215RE.cal.echo_crop; j=M162107606LE.cal.echo_crop; k=M192753724RE.cal.echo_crop

~/projects/StereoPipeline/src/asp/Tools/sfs -i $tile $d.cub $b.cub $j.cub -o $dir/run --threads 1 --smoothness-weight ${reg} --max-iterations 50 --reflectance-type $ref --use-approx-camera-models --coarse-levels $level --crop-input-images --bundle-adjust-prefix sfs_dbj_crop19_reg0.06_level0_refv0_wt4000_yesrpc_fixcam/run  --image-exposures-prefix sfs_dbj_crop19_reg0.06_level0_refv0_wt4000_yesrpc_fixcam/run --initial-dem-constraint-weight ${wt}  --use-rpc-approximation >> output_${dir}.txt 2>&1


for f in $(llt sfs_db*crop19* |g -v txt|pc 0); do h=$(ls -altrd $f/*DEM*tif | grep -i -v hill | tail -n 1 | pc 0); echo $h; di $lola17 $h; done


a=M134985003LE.cal.echo_crop; b=M134991788LE.cal.echo_crop; c=M165645700LE.cal.echo_crop; d=M1142241002LE.cal.echo_crop; e=M101949648RE.cal.echo_crop; g=M111578606LE.cal.echo_crop; h=M116113215RE.cal.echo_crop; j=M162107606LE.cal.echo_crop; k=M192753724RE.cal.echo_crop; i=$a; mapproject --tr 1 --tile-size 512 run_ap17_stereo/run-DEM.tif $a.cub $a.map.tif

bundle_adjust $a.cub $b.cub $d.cub $j.cub -o run_ba17/run --mapprojected-data "$a.map.tif $b.map.tif $d.map.tif $j.map.tif run_ap17_stereo/run-DEM.tif" --min-matches 1

stereo $a.cub $b.cub --subpixel-mode 3 run_stereo17/run --bundle-adjust-prefix run_ba17/run

point2dem -r moon --csv-format '2:lon 3:lat 4:radius_km' --tr 1 --stereographic --proj-lon 30.7385670 --proj-lat 20.1849495 run_stereo17/run-PC.tif

pc_align --csv-format '2:lon 3:lat 4:radius_km' --max-displacement 200 --save-transformed-source-points --save-inv-transformed-reference-points run_stereo17/run-DEM.tif RDR_30E30E_20N20NPointPerRow_csv_table.csv -o run_stereo17/run

point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon 30.7385670 --proj-lat 20.1849495 run_stereo17/run-trans_source.csv

lola17=run_stereo17/run-trans_source-DEM.tif

di run_stereo17/run-trans_source-DEM.tif run_stereo17/run-DEM.tif
  Minimum=0.000, Maximum=9.472, Mean=1.191, StdDev=1.002

  crop=crop1; lola17=run_stereo17/run-trans_source-DEM.tif; di $lola17 run_stereo17/run-${crop}-DEM.tif; for f in $(ls -d sfs_dbj_*$crop*wt*fa* |grep -i -v fe |grep -i -v rpc | grep -i -v xxx_fa1); do h=$(ls -altrd $f/*DEM*tif | grep -i -v hill | tail -n 1 | pc 0); echo $h; di $lola17 $h; done

  # crop1 to crop4
fi

a=M134985003LE.cal.echo_crop; b=M134991788LE.cal.echo_crop; c=M165645700LE.cal.echo_crop; d=M1142241002LE.cal.echo_crop; e=M101949648RE.cal.echo_crop; g=M111578606LE.cal.echo_crop; h=M116113215RE.cal.echo_crop; j=M162107606LE.cal.echo_crop; k=M192753724RE.cal.echo_crop;

lola17=run_stereo17/run-trans_source-DEM.tif

th=4; reg=0.06; 
if [ "$id" = "0" ]; then fa=0; wt=1000; ref=0; fi
if [ "$id" = "1" ]; then fa=0; wt=1000; ref=1; fi
if [ "$id" = "2" ]; then fa=1; wt=1000; ref=0; fi
if [ "$id" = "3" ]; then fa=1; wt=1000; ref=1; fi
if [ "$id" = "4" ]; then fa=0; wt=2000; ref=0; fi
if [ "$id" = "5" ]; then fa=0; wt=2000; ref=1; fi
if [ "$id" = "6" ]; then fa=1; wt=2000; ref=0; fi
if [ "$id" = "7" ]; then fa=1; wt=2000; ref=1; fi

if [ "$id" = "8" ];  then fa=0; wt=1000; ref=2; fi
if [ "$id" = "9" ];  then fa=1; wt=1000; ref=2; fi
if [ "$id" = "10" ]; then fa=0; wt=2000; ref=2; fi
if [ "$id" = "11" ]; then fa=1; wt=2000; ref=2; fi

if [ "$id" = "12" ];  then fa=0; wt=1000; ref=3; fi
if [ "$id" = "13" ];  then fa=1; wt=1000; ref=3; fi
if [ "$id" = "14" ];  then fa=0; wt=2000; ref=3; fi
if [ "$id" = "15" ];  then fa=1; wt=2000; ref=3; fi

if [ "$id" -ge "16" ] || [ "$id" -lt "0" ]; then echo "Invalid id $id"; exit; fi
echo id is $id

if [ "$fa" -ne "0" ]; then opt="--float-albedo"; else opt=""; fi
dir=sfs_dbj_${crop}_reg${reg}_ref${ref}_wt${wt}_fa${fa}

echo dir is $dir

sfs -i run_stereo17/run-${crop}-DEM.tif $d.cub $b.cub $j.cub -o $dir/run --threads ${th} --smoothness-weight ${reg} --max-iterations 50 --reflectance-type $ref --use-approx-camera-models --coarse-levels 0 --crop-input-images --bundle-adjust-prefix run_ba17/run --initial-dem-constraint-weight ${wt}  --use-rpc-approximation --float-exposure --float-cameras $opt > output_${dir}.txt 2>&1


