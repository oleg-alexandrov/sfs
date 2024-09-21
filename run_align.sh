#!/bin/bash

#if [ "$#" -lt 1 ]; then echo Usage: $0 argName; exit; fi


s1=sfs12_pqrs_level5_sm0.06/run-DEM-final-level0.tif
s2=sfs12_pqrs_level4_sm0.06/run-DEM-final-level0.tif
s3=sfs12_pqr_level0_sm0.06/run-DEM-final.tif
s4=run_stereo13/run-1m-sfs-tile-0.tif
s5=run_stereo13/run-1m-sfs2-tile-0.tif
s6=run_stereo13/run-1m-sfs3-tile-0.tif

sfs=$s1
csv=RDR_239E240E_81p3596S81SPointPerRow_csv_table

#point2dem -r moon --csv-format '2:lon 3:lat 4:radius_km' --tr 1 --stereographic --proj-lon 0 --proj-lat -90 $csv.csv

win=$(gdal_win.sh $csv-DEM.tif)
echo win is $win

dem=run_stereo12/run-1m-DEM.tif
base=$(dirname $dem)

crop_dem=${dem/.tif/_crop.tif}

lola_align=$base/lola-align
sfs_align=${sfs/.tif/_align}

lola_align_dem=${lola_align}-trans_source-DEM.tif
sfs_win=$(gdal_win.sh ${sfs})
before_sfs=${dem/.tif/_before_sfs.tif}

gdal_translate -projwin $win $dem $crop_dem

#pc_align --csv-format '2:lon 3:lat 4:radius_km' --max-displacement 200 $crop_dem $csv.csv -o $lola_align --save-transformed-source-points
#point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon 0 --proj-lat -90 ${lola_align}-trans_source.csv

gdal_translate -projwin $sfs_win $dem $before_sfs

echo $sfs $before_sfs
diff.sh ${lola_align_dem} $before_sfs
diff.sh ${lola_align_dem} $sfs
diff.sh ${before_sfs} $sfs


# pc_align --csv-format '2:lon 3:lat 4:radius_km' --max-displacement 200 $before_sfs $csv.csv -o $base/align_before_sfs --save-transformed-source-points --save-inv-transformed-reference-points

# pc_align --csv-format '2:lon 3:lat 4:radius_km' --max-displacement 200 $sfs $csv.csv -o $base/align_after_sfs --save-transformed-source-points --save-inv-transformed-reference-points

# point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon 0 --proj-lat -90  $base/align_before_sfs-trans_reference.tif

# point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon 0 --proj-lat -90  $base/align_after_sfs-trans_reference.tif

# echo $base/align_before_sfs-trans_reference-DEM.tif  $base/align_after_sfs-trans_reference-DEM.tif


# diff.sh $lola_align_dem $before_sfs
# diff.sh $lola_align_dem $sfs
# diff.sh $lola_align_dem ${lola_align_dem}

pc_align --max-displacement 300 run_ap3/run-PC.tif RDR_3E4E_25N26NPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km' --save-transformed-source-points -o run_ap3/run
point2dem -r moon --csv-format '1:lon 2:lat 3:radius_km' --tr 1 --stereographic --proj-lon 3.6 --proj-lat 26.18 run_ap3/run-trans_source.csv

ref=0
crop=8  0.940 2.487  -- before and after sfs+align error 
crop=9  0.852 2.715
crop=10 0.804 2.448
crop=11 0.834 1.879

ref=1
crop=8  0.940 2.145
crop=9  0.852 2.715
crop=10 0.804 2.465 -- 2.169 depending on weight
crop=11 0.834 1.879 -- 1.791  

crop=9
ref=1
if [ "$p" -eq 1 ]; then f=sfs_ap_crop${crop}_level0/run-DEM-final.tif; fi
if [ "$p" -eq 2 ]; then f=sfs_ap_crop${crop}_level0_reg0.09_ref${ref}/run-DEM-final.tif; fi
if [ "$p" -eq 3 ]; then f=sfs_ap_crop${crop}_level0_reg0.12_ref${ref}/run-DEM-final.tif; fi
if [ "$p" -eq 4 ]; then f=sfs_ap_crop${crop}_level0_reg0.15_ref${ref}/run-DEM-final.tif; fi

echo p=$p
g=${f/.tif/}; echo $g
pc_align --max-displacement -1 -o $g --save-transformed-source-points run_ap3/run-crop${crop}-DEM.tif $f 2>&1 |g "Translation vector magnitude"
point2dem --tr 1 --search-radius-factor 2 -r moon --stereographic --proj-lon 3.6 --proj-lat 26.18 $g-trans_source.tif > /dev/null 2>&1
diff.sh run_ap3/run-trans_source-DEM.tif run_ap3/run-crop${crop}-DEM.tif 
diff.sh run_ap3/run-trans_source-DEM.tif $f
diff.sh run_ap3/run-trans_source-DEM.tif $g-trans_source-DEM.tif

