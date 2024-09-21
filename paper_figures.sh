#!/bin/bash

# Around south pole with one image

wget http://lroc.sese.asu.edu/data/LRO-L-LROC-2-EDR-V1.0/ROLRC_0005/DATA/SCI/2010267/NAC/M139939938LE.IMG
wget http://lroc.sese.asu.edu/data/LRO-L-LROC-2-EDR-V1.0/LROLRC_0005/DATA/SCI/2010267/NAC/M139946735RE.IMG
wget http://lroc.sese.asu.edu/data/LRO-L-LROC-2-EDR-V1.0/LROLRC_0009/DATA/SCI/2011284/NAC/M173004270LE.IMG
wget http://lroc.sese.asu.edu/data/LRO-L-LROC-2-EDR-V1.0/LROLRC_0002/DATA/MAP/2010062/NAC/M122270273LE.IMG

for f in *IMG; do
    f=${f/.IMG/}
    if [ -f ${f}.cal.echo.cub ]; then continue; fi
    lronac2isis from = ${f}.IMG     to = ${f}.cub
    spiceinit   from = ${f}.cub
    lronaccal   from = ${f}.cub     to = ${f}.cal.cub
    lronacecho  from = ${f}.cal.cub to = ${f}.cal.echo.cub
done

ln -s M139939938LE.cal.echo.cub A.cub
ln -s M139946735RE.cal.echo.cub B.cub
ln -s M173004270LE.cal.echo.cub C.cub
ln -s M122270273LE.cal.echo.cub D.cub

parallel_stereo --job-size-w 1024                      \
    --job-size-h 1024 A.cub B.cub                      \
    --left-image-crop-win 0 7998 2728 2696             \
    --right-image-crop-win 0 9377 2733 2505            \
    --threads 16 --corr-seed-mode 1  --subpixel-mode 3 \
    run_full1/run

point2dem -r moon --stereographic --proj-lon 0 \
    --proj-lat -90 run_full1/run-PC.tif
gdal_translate -projwin -15471.9 150986 -14986.7 150549  \
    run_full1/run-DEM.tif run_full1/run-crop-DEM.tif

sfs -i run_full1/run-crop1-DEM.tif A.cub -o sfs_ref1/run --reflectance-type 1 --smoothness-weight 0.08 --initial-dem-constraint-weight 0.0001 --max-iterations 10 --use-approx-camera-models --use-rpc-approximation --crop-input-images


# Around equator

#M1121224102LE, M1121209902LE, M1098830077LE, and M1149488705LE

wget http://lroc.sese.asu.edu/data/LRO-L-LROC-2-EDR-V1.0/LROLRC_0015/DATA/ESM/2013111/NAC/M1121224102LE.IMG
wget http://lroc.sese.asu.edu/data/LRO-L-LROC-2-EDR-V1.0/LROLRC_0015/DATA/ESM/2013111/NAC/M1121209902LE.IMG
wget http://lroc.sese.asu.edu/data/LRO-L-LROC-2-EDR-V1.0/LROLRC_0012/DATA/SCI/2012218/NAC/M1098830077LE.IMG
wget http://lroc.sese.asu.edu/data/LRO-L-LROC-2-EDR-V1.0/LROLRC_0018/DATA/ESM/2014074/NAC/M1149488705LE.IMG

for f in *IMG; do
    f=${f/.IMG/}
    if [ -f ${f}.cal.echo.cub ]; then continue; fi
    echo doing $f
    lronac2isis from = ${f}.IMG     to = ${f}.cub
    spiceinit   from = ${f}.cub
    lronaccal   from = ${f}.cub     to = ${f}.cal.cub
    lronacecho  from = ${f}.cal.cub to = ${f}.cal.echo.cub
done

#M1121224102LE M1121209902LE M1098830077LE M1149488705LE

for f in M1121224102LE M1121209902LE M1098830077LE M1149488705LE; do
    a=${f}.cal.echo.cub
    b=${f}.cal.echo_sub10.cub
    if [ -f "$b" ]; then continue; fi
    echo $f
    reduce.pl $a 10
done

ln -s M1121224102LE.cal.echo.cub E.cub
ln -s M1121209902LE.cal.echo.cub F.cub
ln -s M1098830077LE.cal.echo.cub G.cub
ln -s M1149488705LE.cal.echo.cub H.cub

crop.pl E.cub: 1203 29638 4163 3949
crop.pl F.cub: 931 28902 4336 3915
crop.pl G.cub: 1530 21210 3954 4176
crop.pl H.cub: 477 45419 4859 4548

stereo E_crop.cub F_crop.cub run_EF/run       
point2dem -r moon --stereographic --proj-lon 0 --proj-lat -90 run_full1/run-PC.tif
gdal_translate -co compress=lzw -co TILED=yes -co INTERLEAVE=BAND -co BLOCKXSIZE=256 -co BLOCKYSIZE=256 -srcwin 119 121 2518 2700  run_EF/run-DEM.tif run_EF/run-crop-DEM.tif

mapproject --tile-size 256 run_EF/run-crop-DEM.tif E_crop.cub E_crop.map.tif
mapproject --tile-size 256 run_EF/run-crop-DEM.tif F_crop.cub F_crop.map.tif
mapproject --tile-size 256 run_EF/run-crop-DEM.tif G_crop.cub G_crop.map.tif
mapproject --tile-size 256 run_EF/run-crop-DEM.tif H_crop.cub H_crop.map.tif

bundle_adjust E_crop.cub F_crop.cub G_crop.cub H_crop.cub -o run_ba_full/run --mapprojected-data "E_crop.map.tif F_crop.map.tif G_crop.map.tif H_crop.map.tif run_EF/run-crop-DEM.tif" --overlap-limit 10 --min-matches 1

parallel_stereo E_crop.cub F_crop.cub run_EF_full_stereo_ba/run --bundle-adjust-prefix run_ba_full/run 

point2dem run_EF_full_stereo_ba/run-PC.tif --stereographic --proj-lon 3.635 --proj-lat 26.167

gdal_translate -projwin -1555.183 1762.1176 1638.9725 -1692.293 run_EF_full_stereo_ba/run-DEM.tif run_EF_full_stereo_ba/run-crop-DEM.tif

gdal_translate -projwin -1490 1458 924 -990 run_EF_full_stereo_ba/run-DEM.tif run_EF_full_stereo_ba/run-crop1-DEM.tif

for f in run_ba_full/*adjust; do g=${f/full/sub10}; g=${g/_crop.adjust/_crop_sub10.adjust}; echo $f $g; cp -fv $f $g; done

for p in E F G H; do 
    mapproject --tile-size 512 run_EF_sub10_stereo_ba/run-DEM.tif ${p}_crop_sub10.cub ${p}_crop_sub10.map.tif --tr 10 --bundle-adjust-prefix run_ba_sub10/run
done

gdal_translate -projwin -1200 1340 920 -880 run_EF_sub10_stereo_ba/run-DEM.tif run_EF_sub10_stereo_ba/run-crop1-DEM.tif

stereo E_crop_sub10.cub F_crop_sub10.cub run_EF_sub10_stereo_ba/run --bundle-adjust-prefix run_ba_sub10_subpix3/run --subpixel-mode 3
point2dem run_EF_sub10_stereo_ba/run-PC.tif --stereographic --proj-lon 3.635 --proj-lat 26.167 --tr 10
gdal_translate -projwin -1200 1340 920 -880 run_EF_sub10_stereo_ba_subpix3/run-DEM.tif run_EF_sub10_stereo_ba_subpix3/run-crop1-DEM.tif   

parallel_stereo E_crop.cub F_crop.cub run_EF_full_stereo_ba_subpix3/run --bundle-adjust-prefix run_ba_full/run --subpixel-mode 3     
point2dem run_EF_full_stereo_ba_subpix3/run-PC.tif --stereographic --proj-lon 3.635 --proj-lat 26.167 --tr 10
gdal_translate -projwin -1200 1340 920 -880 run_EF_full_stereo_ba_subpix3/run-DEM.tif run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif

sfs -i run_EF_sub10_stereo_ba_subpix3/run-crop1-DEM.tif E_crop_sub10.cub G_crop_sub10.cub H_crop_sub10.cub -o run_sfs_EGH_sub10/run --bundle-adjust-prefix run_ba_sub10/run --reflectance-type 1 --smoothness-weight 0.08 --initial-dem-constraint-weight 0.0001 --max-iterations 10 --use-approx-camera-models --use-rpc-approximation --crop-input-images --integrability-constraint-weight 0.00 --float-albedo --float-exposure

# To run:sw=0.001; iw=1.00; dw=1e-8; swpq=0.0001; export ISISROOT=$HOME/projects/base_system; sfs -i run_EF_sub10_stereo_ba_subpix3/run-crop1-DEM.tif E_crop_sub10.cub G_crop_sub10.cub H_crop_sub10.cub -o sfs_EGH_sw${sw}_iw${iw}_dw${dw}_sub10_fae_swpq${swpq}/run --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --integrability-constraint-weight ${iw} --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-albedo --float-exposure --smoothness-weight-pq ${swpq}

Best results:
sfs_EGH_sw0.02_iw5.00_dw0.00_sub10_fae_swpq0.000/run-DEM-final.tif Minimum=0.000, Maximum=10.951, Mean=2.138, StdDev=1.342

sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif Minimum=0.000, Maximum=10.951, Mean=1.810, StdDev=1.353 # best one

These have the iw constraint and no sw constraint
sfs_EGH_sw0.00_iw5.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif Minimum=0.000, Maximum=11.015, Mean=2.692, StdDev=1.535
sfs_EGH_sw0.00_iw5.00_dw0.00_sub10_fae_swpq0.001/run-DEM-final.tif Minimum=0.000, Maximum=11.014, Mean=2.692, StdDev=1.535
sfs_EGH_sw0.001_iw1.00_dw1e-8_sub10_fae_swpq0.0001/run-DEM-final.tif Minimum=0.000, Maximum=10.951, Mean=1.966, StdDev=1.404

sfs_EGH_sw0.00_iw1.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif Minimum=0.000, Maximum=10.951, Mean=2.252, StdDev=1.790
sfs_EGH_sw0.01_iw1.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif Minimum=0.000, Maximum=10.951, Mean=1.996, StdDev=1.350

# Error before sfs
di run_EF_sub10_stereo_ba_subpix3/run-crop1-DEM.tif  run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif
  Minimum=0.000, Maximum=26.824, Mean=4.126, StdDev=2.282

  # Signed difference before sfs
geodiff run_EF_sub10_stereo_ba_subpix3/run-crop1-DEM.tif run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif -o run_EF_sub10_stereo_ba_subpix3/run-crop1-signed 
 gim run_EF_sub10_stereo_ba_subpix3/run-crop1-signed-diff.tif
  Minimum=-3.269, Maximum=26.824, Mean=4.100, StdDev=2.329

# Signed difference after sfs

geodiff  sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif -o sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-signed
gim sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-signed-diff.tif
  Minimum=-5.790, Maximum=10.951, Mean=0.982, StdDev=2.035



Stats
for h in $(for f in $(llt *sfs* | pc 0); do llt $f/run-DEM*tif |grep -i -v hill | grep -i -v CMAP | grep -i -v diff.tif | tail -n 1; done | pc 0); do echo $h $(di run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif $h) $(geodiff --absolute $h run_EF_full_stereo_ba_subpix3/run-trans_source.csv --csv-format '1:lon 2:lat 3:radius_km' 2>/dev/null | grep -i Mean) | perl -p -e "s#=# #g"; done | tee output.txt

gab run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif run_EF_sub10_stereo_ba_subpix3/run-crop1-DEM.tif -o run_EF_sub10_stereo_ba_subpix3/run-crop1

gab run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif -o sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final

colormap --min 0 --max 10 run_EF_sub10_stereo_ba_subpix3/run-crop1-diff.tif
colormap --min 0 --max 10 sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final-diff.tif

sg {E,G,H}_crop_sub10.map.tif run_EF_sub10_stereo_ba_subpix3/run-crop1-DEM.tif run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif run_EF_sub10_stereo_ba_subpix3/run-crop1-diff_CMAP.tif sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final-diff_CMAP.tif sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-comp-albedo-final.tif --grid-cols 3

gdal_translate -scale 0.86655212322369 1.7174157864545 0 255 -ot byte -of GTiff sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-comp-albedo-final.tif sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-comp-albedo-final_int.tif

convert +append fig2pic[1-3].jpeg fig2p1.jpg
convert -append fig2p[1-3].jpg  fig2.jpg      


# LOLA example

wget 'http://ode.rsl.wustl.edu/moon/downloadFile.aspx?type=datapoint&file_name=20180727T174258335/RDR_3E4E_26N27NPointPerRow_csv_table.csv' -O RDR_3E4E_26N27NPointPerRow_csv_table.csv

point2dem --stereographic --proj-lon 3.635 --proj-lat 26.167 --tr 10 --csv-format '2:lon 3:lat 4:radius_km' --datum moon RDR_3E4E_26N27NPointPerRow_csv_table.csv

pc_align --initial-ned-translation "0 0 -417" --max-displacement 50 run_EF_full_stereo_ba_subpix3/run-DEM.tif RDR_3E4E_26N27NPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km' -o run_EF_full_stereo_ba_subpix3/run --save-transformed-source-points

geodiff --absolute run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif run_EF_full_stereo_ba_subpix3/run-trans_source.csv --csv-format '1:lon 2:lat 3:radius_km' 2>/dev/null | grep -i Mean
Mean difference:      1.01492

geodiff --absolute sfs_EGH_sw0.08_iw0_dw1e-6_sub10_fa/run-DEM-iter0.tif run_EF_full_stereo_ba_subpix3/run-trans_source.csv --csv-format '1:lon 2:lat 3:radius_km' 2>/dev/null | grep -i Mean
Mean difference:      3.88312

geodiff --absolute sfs_EGH_sw0.08_iw0_dw1e-6_sub10_fa/run-DEM-final.tif run_EF_full_stereo_ba_subpix3/run-trans_source.csv --csv-format '1:lon 2:lat 3:radius_km' 2>/dev/null | grep -i Mean
Mean difference:      2.04615

sfs_EGH_sw0.08_iw0_dw1e-6_sub10_fa/run-DEM-final.tif Minimum 0.000 Maximum 10.951 Mean 1.808 StdDev 1.353 Mean difference: 2.04615
sfs_EGH_sw0.08_iw0_dw1e-5_sub10/run-DEM-final.tif Minimum 0.000 Maximum 10.951 Mean 1.811 StdDev 1.349 Mean difference: 2.01764
sfs_EGH_sw0.08_iw0_dw1e-6_sub10_fae/run-DEM-final.tif Minimum 0.000 Maximum 10.951 Mean 1.813 StdDev 1.354 Mean difference: 2.05465

ref=run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif
lola=run_EF_full_stereo_ba_subpix3/run-trans_source.csv
bsfs=run_EF_sub10_stereo_ba_subpix3/run-crop1-DEM.tif
asfs=sfs_EGH_sw0.08_iw0_dw1e-6_sub10_fae/run-DEM-final.tif 

# With high res dem
geodiff --absolute  $ref $lola -o $ref --csv-format '1:lon 2:lat 3:radius_km' 2>/dev/null |g mean
point2dem $ref-diff.csv --csv-format '1:lon 2:lat 3:height_above_datum'  --stereographic --proj-lon 3.635 --proj-lat 26.167 --tr 10   --datum moon 

# before opt
geodiff --absolute  $ref $bsfs  -o $bsfs 2>/dev/null
gim $bsfs-diff.tif
geodiff --absolute  $bsfs $lola -o $bsfs  --csv-format '1:lon 2:lat 3:radius_km'  2>/dev/null |g mean
point2dem $bsfs-diff.csv --csv-format '1:lon 2:lat 3:height_above_datum'  --stereographic --proj-lon 3.635 --proj-lat 26.167 --tr 10   --datum moon 

# after opt
geodiff --absolute  $ref $asfs  -o $asfs  2>/dev/null
gim $asfs-diff.tif
geodiff --absolute  $asfs $lola -o $asfs  --csv-format '1:lon 2:lat 3:radius_km'  2>/dev/null |g mean
point2dem $asfs-diff.csv --csv-format '1:lon 2:lat 3:height_above_datum'  --stereographic --proj-lon 3.635 --proj-lat 26.167 --tr 10   --datum moon 

export ISISROOT=$HOME/projects/base_system
sw=0.08; sfs -i $asfs E_crop_sub10.cub G_crop_sub10.cub H_crop_sub10.cub -o sfs_EGH_sw${sw}_iw0_dw1e-6_sub10_fae_pass2/run --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight 1e-6 --max-iterations 10 --integrability-constraint-weight 0 --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-albedo --float-exposure 
asfs2= sfs_EGH_sw${sw}_iw0_dw1e-6_sub10_fae_pass2/run-DEM-final.tif 
geodiff --absolute  $ref $asfs2  -o $asfs2  2>/dev/null
gim $asfs2-diff.tif
geodiff --absolute  $asfs2 $lola -o $asfs2  --csv-format '1:lon 2:lat 3:radius_km'  2>/dev/null |g mean

export ISISROOT=$HOME/projects/base_system
sw=0.04; sfs -i $asfs E_crop_sub10.cub G_crop_sub10.cub H_crop_sub10.cub -o sfs_EGH_sw${sw}_iw0_dw1e-6_sub10_fae_pass2/run --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight 1e-6 --max-iterations 10 --integrability-constraint-weight 0 --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-albedo --float-exposure 
asfs2=sfs_EGH_sw${sw}_iw0_dw1e-6_sub10_fae_pass2/run-DEM-final.tif 
geodiff --absolute  $ref $asfs2  -o $asfs2  2>/dev/null
gim $asfs2-diff.tif
geodiff --absolute  $asfs2 $lola -o $asfs2  --csv-format '1:lon 2:lat 3:radius_km'  2>/dev/null |g mean

export ISISROOT=$HOME/projects/base_system
sw=0.01; sfs -i $asfs E_crop_sub10.cub G_crop_sub10.cub H_crop_sub10.cub -o sfs_EGH_sw${sw}_iw0_dw1e-6_sub10_fae_pass2/run --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight 1e-6 --max-iterations 10 --integrability-constraint-weight 0 --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-albedo --float-exposure 
asfs2=sfs_EGH_sw${sw}_iw0_dw1e-6_sub10_fae_pass2/run-DEM-final.tif 
geodiff --absolute  $ref $asfs2  -o $asfs2  2>/dev/null
gim $asfs2-diff.tif
geodiff --absolute  $asfs2 $lola -o $asfs2  --csv-format '1:lon 2:lat 3:radius_km'  2>/dev/null |g mean

export ISISROOT=$HOME/projects/base_system
sw=0.00; sfs -i $asfs E_crop_sub10.cub G_crop_sub10.cub H_crop_sub10.cub -o sfs_EGH_sw${sw}_iw0_dw1e-6_sub10_fae_pass2/run --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight 1e-6 --max-iterations 10 --integrability-constraint-weight 0 --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-albedo --float-exposure 
asfs2=sfs_EGH_sw${sw}_iw0_dw1e-6_sub10_fae_pass2/run-DEM-final.tif 
geodiff --absolute  $ref $asfs2  -o $asfs2  2>/dev/null
gim $asfs2-diff.tif
geodiff --absolute  $asfs2 $lola -o $asfs2  --csv-format '1:lon 2:lat 3:radius_km'  2>/dev/null |g mean

# stats
for f in $(llt */*diff-DEM.tif | pc 0); do ec $f $(gim $f); colormap --min 0 --max 9.3745151945046 $f; sleep 3; done
colormap --min 0 --max 10.9720342898294 $bsfs-diff.tif; sleep 3
colormap --min 0 --max 10.9720342898294 $asfs-diff.tif

sg run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif-diff-DEM_CMAP.tif run_EF_sub10_stereo_ba_subpix3/run-crop1-DEM.tif-diff-DEM_CMAP.tif sfs_EGH_sw0.08_iw0_dw1e-6_sub10_fae/run-DEM-final.tif-diff-DEM_CMAP.tif run_EF_sub10_stereo_ba_subpix3/run-crop1-DEM.tif-diff_CMAP.tif sfs_EGH_sw0.08_iw0_dw1e-6_sub10_fae/run-DEM-final.tif-diff_CMAP.tif sfs_EGH_sw0.08_iw0_dw1e-6_sub10_fae/run-DEM-final.tif

#Charon

Before SfS: /home/oalexan1/projects/sfs_charon/LE25-Spock/clip_25_tr400_meter.tif
After SfS:  /home/oalexan1/projects/sfs_charon/LE25-Spock/sfs_d_clip25_reg140_ref0_wt64000_meter/run-DEM-final.tif

# Redo all this
pc_align --max-displacement -1 clip_25_big_tr400_meter.tif clip_25_big_tr400_meter.tif -o clip_25_big_tr400_align/run --save-transformed-source-points --num-iterations 0
point2dem clip_25_big_tr400_align/run-trans_source.tif --stereographic --proj-lon 25.455927 --proj-lat 14.612601 --tr 400
gdal_translate -projwin -73600 70000 80800 -80800 clip_25_big_tr400_align/run-trans_source-DEM.tif clip_25_big_tr400_align/run-trans_source-clip-DEM.tif

ref=0; q=4; dw=1e-${q}; export ISISROOT=~/projects/base_system; ~/projects/StereoPipeline/src/asp/Tools/sfs -i clip_25_big_tr400_align/run-trans_source-clip-DEM.tif d.cub -o sfs_d_clip25_reg140_ref${ref}_wt64000_meter_v2_dw${dw}/run --smoothness-weight 140  --reflectance-type ${ref} --initial-dem-constraint-weight ${dw} --max-iterations 10

#It gives very bad results with ref != 0. The problem eventually comes not from the model itself, or from the shadows, or from the regularization term, but the fact that the input DEM is highly noisy with steep and difficult slopes.  The lunar-Lambertian model, with its dependence on the viewing angle, was computing an unphysical reflection in places, which was resulting in a noisy optimized DEM.  If I use the same lunar Lambertian model with an initial guess which came from the result of the well-behaved output of SfS with the regular Lambertian model, I get decent results. I also used this well-behaved initial guess not only with the lunar Lambertian, but also with the Hapke model and the Lambertian itself. The results are quite difficult to tell apart visually, and we don't have ground truth to decide which is better. 

# With new weight (ignore this)

geodiff --absolute  $ref $asfs  -o $asfs  2>/dev/null
gim $asfs-diff.tif
geodiff --absolute  $asfs $lola -o $asfs  --csv-format '1:lon 2:lat 3:radius_km'  2>/dev/null |g mean
asfs2=sfs_EGH_sw${sw}_iw0_dw1e-6_sub10_fae_pass2/run-DEM-final.tif 
geodiff --absolute  $ref $asfs2  -o $asfs2  2>/dev/null
gim $asfs2-diff.tif
geodiff --absolute  $asfs2 $lola -o $asfs2  --csv-format '1:lon 2:lat 3:radius_km'  2>/dev/null |g mean
echo sw=$sw

# The south figure

ln -s ../sfs/M139939938LE.cal.echo.cub H.cub
ln -s ../sfs/M139946735RE.cal.echo.cub I.cub
ln -s ../sfs/M173004270LE.cal.echo.cub L.cub
ln -s ../sfs/M122270273LE.cal.echo.cub N.cub

export ISISROOT=$HOME/projects/isis

# 1 image
#parallel_stereo --job-size-w 1024 --job-size-h 1024 H.cub I.cub --left-image-crop-win 0 7998 2728 2696 --right-image-crop-win 0 9377 2733 2505 --threads 16 --corr-seed-mode 1 --subpixel-mode 3 run_full/run
#point2dem -r moon --stereographic --proj-lon 0 --proj-lat -90 run_full/run-PC.tif
#gdal_translate -projwin -15471.9 150986 -14986.7 150549 run_full/run-DEM.tif run_full/run-crop-DEM.tif
#sfs -i run_full/run-crop-DEM.tif H.cub -o sfs/run --smoothness-weight 0.08 --reflectance-type 0  --max-iterations 100 --use-approx-camera-models

# Many images South

crop from = H.cub to = H_crop.cub sample = 1 line = 6644 nsamples = 2192 nlines = 4982
crop from = I.cub to = I_crop.cub sample = 1 line = 7013 nsamples = 2531 nlines = 7337
crop from = L.cub to = L_crop.cub sample = 1 line = 1 nsamples = 2531 nlines = 8305
crop from = N.cub to = N_crop.cub sample = 1 line = 1 nsamples = 2531 nlines = 2740

for f in H I L N; do 
  reduce from = ${f}_crop.cub to = ${f}_crop_sub10.cub sscale = 10 lscale = 10
done

export ISISROOT=$HOME/projects/base_system

bundle_adjust H_crop_sub10.cub I_crop_sub10.cub L_crop_sub10.cub N_crop_sub10.cub --min-matches 1 -o run_ba_sub10/run --ip-per-tile 100000

# Use same adjust files in both cases
for f in run_ba_sub10/*adjust; do g=${f/_sub10/}; g=${g/_sub10/}; \cp -fv $f $g; done

#bundle_adjust H_crop.cub I_crop.cub L_crop.cub N_crop.cub --min-matches 1 -o run_ba/run --ip-per-tile 2000

stereo H_crop_sub10.cub I_crop_sub10.cub run_sub10/run --subpixel-mode 3 --bundle-adjust-prefix run_ba_sub10/run

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 run_sub10/run-PC.tif

mapproject run_sub10/run-DEM.tif  H_crop_sub10.cub  H_crop_sub10.map.tif  --bundle-adjust-prefix run_ba_sub10/run
mapproject run_sub10/run-DEM.tif I_crop_sub10.cub I_crop_sub10.map.tif --bundle-adjust-prefix run_ba_sub10/run        
mapproject run_sub10/run-DEM.tif L_crop_sub10.cub L_crop_sub10.map.tif --bundle-adjust-prefix run_ba_sub10/run        
mapproject run_sub10/run-DEM.tif N_crop_sub10.cub N_crop_sub10.map.tif --bundle-adjust-prefix run_ba_sub10/run        

parallel_stereo H_crop.cub I_crop.cub run_HI_full/run --subpixel-mode 3 --bundle-adjust-prefix run_ba/run --left-image-crop-win -49 1285 2269 1875 --right-image-crop-win -109 1924 2781 2782 --job-size-w 1024 --job-size-h 1024

parallel_stereo H_crop_sub10.cub I_crop_sub10.cub run_HI_sub10/run --subpixel-mode 3 --bundle-adjust-prefix run_ba_sub10/run --job-size-w 512 --job-size-h 512

point2dem -r moon run_HI_full/run-PC.tif --stereographic --proj-lon -5.6812589 --proj-lat -84.993503 --tr 10

gdal_translate -projwin -510 500 560 -600 run_HI_sub10/run-DEM.tif run_HI_sub10/run-crop-DEM.tif
gdal_translate -projwin -510 500 560 -600 run_HI_full/run-DEM.tif run_HI_full/run-crop-DEM.tif

sw=0.12; iw=0; dw=1e-8; swpq=0.00; export ISISROOT=$HOME/projects/base_system; sfs -i run_HI_sub10/run-crop-DEM.tif H_crop_sub10.cub L_crop_sub10.cub N_crop_sub10.cub -o sfs_HLN_sw${sw}_iw${iw}_dw${dw}_sub10_fae_swpq${swpq}/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --smoothness-weight-pq ${swpq} --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --integrability-constraint-weight ${iw} 

pc_align run_HI_full/run-PC.tif run_HI_sub10/run-DEM.tif -o run_pc/run --save-inv-transformed-reference-points --max-displacement 50

Stats
for h in run_HI_sub10/run-crop-DEM.tif $(for f in $(llt *sfs* | pc 0); do llt $f/run-DEM*tif |grep -i -v hill | grep -i -v CMAP | grep -i -v diff.tif | tail -n 1; done | pc 0); do echo $h $(di run_HI_full/run-crop-DEM.tif $h); done | tee output.txt

for h in run_HI_sub10/run-crop-DEM.tif $(for f in $(llt *sfs* | pc 0); do llt $f/run-DEM*tif |grep -i -v hill | grep -i -v CMAP | grep -i -v diff.tif | tail -n 1; done | pc 0); do echo $h $(di run_pc/run-trans_reference-DEM.tif $h); done | tee output2.txt

# Abs difference
gab run_pc/run-trans_reference-DEM.tif run_HI_sub10/run-crop2-DEM.tif -o run_HI_sub10/run-crop2
gab run_pc/run-trans_reference-DEM.tif sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00/run-DEM-final.tif -o sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00/run-DEM-final-crop2
gim run_HI_sub10/run-crop2-diff.tif                                            
  Minimum=0.000, Maximum=39.456, Mean=2.338, StdDev=2.356 # before SfS
gim sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00/run-DEM-final-crop2-diff.tif
  Minimum=0.000, Maximum=41.876, Mean=1.328, StdDev=1.577 # After SfS

# Signed difference
geodiff run_pc/run-trans_reference-DEM.tif run_HI_sub10/run-crop2-DEM.tif -o run_HI_sub10/run-crop2-signed
gim run_HI_sub10/run-crop2-signed-diff.tif
  Minimum=-39.456, Maximum=26.521, Mean=0.246, StdDev=3.310 # before SfS
geodiff run_pc/run-trans_reference-DEM.tif sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00/run-DEM-final.tif -o sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00/run-DEM-final-crop2-signed
gim sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00/run-DEM-final-crop2-signed-diff.tif
  Minimum=-41.876, Maximum=25.794, Mean=0.254, StdDev=2.046 # affter SfS

  
gdal_translate -projwin -455.000 405.000 825.000 -745.000 run_pc/run-trans_reference-DEM.tif run_pc/run-trans_reference-DEM-crop.tif

# Build color maps
gab run_HI_sub10/run-crop2-DEM.tif run_pc/run-trans_reference-DEM-crop.tif -o run_HI_sub10/run-crop2-DEM
gab sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00/run-DEM-final.tif run_pc/run-trans_reference-DEM-crop.tif -o sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00/run-DEM-final
>>> gim run_HI_sub10/run-crop2-DEM-diff.tif
  Minimum=0.000, Maximum=39.456, Mean=2.338, StdDev=2.356

oalexan1@lunokhod1:~/projects/sfs_south
>>> gim sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00/run-DEM-final-diff.tif
  Minimum=0.000, Maximum=41.876, Mean=1.328, StdDev=1.577

colormap --min 0 --max 10  run_HI_sub10/run-crop2-DEM-diff.tif           
colormap --min 0 --max 10  sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00/run-DEM-final-diff.tif
sg run_HI_sub10/run-crop2-DEM-diff_CMAP.tif sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00/run-DEM-final-diff_CMAP.tif

convert screenshot1.bmp ../sfs/fig3p5.jpg
convert screenshot2.bmp ../sfs/fig3p6.jpg                                                                            

#mapproject run_pc/run-trans_reference-DEM-crop.tif H_crop_sub10.cub H_crop_sub10.map.crop.tif --bundle-adjust-prefix run_ba_sub10/run --tr 10
mapproject  sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00_th/run-DEM-final.tif H_crop_sub10.cub H_crop_sub10.map.crop.tif --bundle-adjust-prefix run_ba_sub10/run --tr 10

# With shadow threshold
sfs -i run_HI_sub10/run-crop2-DEM.tif H_crop_sub10.cub L_crop_sub10.cub N_crop_sub10.cub -o sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00_th/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --smoothness-weight-pq 0.00 --reflectance-type 1 --smoothness-weight 0.16 --initial-dem-constraint-weight 1e-9 --max-iterations 10 --integrability-constraint-weight 0 --float-albedo --float-cameras --shadow-thresholds "0.00133182 0.00127656 0.000690809"

Best result:
sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00_th/run-DEM-final.tif
sg run_HI_sub10/run-crop2-DEM.tif run_pc/run-trans_reference-DEM-crop.tif sfs2_HLN_sw0.16_iw0_dw1e-9_sub10_faec_swpq0.00_th/run-DEM-final.tif H_crop_sub10.map.crop.tif

# The lola sub10 case

export ISISROOT=$HOME/projects/isis

for f in *IMG; do
    f=${f/.IMG/}
    if [ -f ${f}.cal.echo.cub ]; then continue; fi
    lronac2isis from = ${f}.IMG     to = ${f}.cub
    spiceinit   from = ${f}.cub
    lronaccal   from = ${f}.cub     to = ${f}.cal.cub
    lronacecho  from = ${f}.cal.cub to = ${f}.cal.echo.cub
done

ln -s M134985003LE.cal.echo.cub A.cub
ln -s M134991788LE.cal.echo.cub B.cub

#c=M165645700LE.cal.echo_crop;
ln -s M1142241002LE.cal.echo.cub D.cub
#; e=M101949648RE.cal.echo_crop; g=M111578606LE.cal.echo_crop; h=M116113215RE.cal.echo_crop;
ln -s M162107606LE.cal.echo.cub J.cub

crop from = A.cub to = A_crop.cub sample = 1 line = 4832 nsamples = 5063 nlines = 18324
crop from = B.cub to = B_crop.cub sample = 1 line = 6383 nsamples = 5063 nlines = 17955

for f in *crop.cub; do reduce.pl $f 10; done

export ISISROOT=$HOME/projects/base_system
parallel_stereo A_crop_sub10.cub B_crop_sub10.cub run_AB_crop_sub10/run --job-size-h 1024 --job-size-w 1024

point2dem run_AB_crop_sub10/run-PC.tif --stereographic --proj-lon 30.7383426 --proj-lat 20.1521625 --tr 10

wget 'http://ode.rsl.wustl.edu/moon/downloadFile.aspx?type=datapoint&file_name=20180725T145318178/RDR_30E30E_20N20NPointPerRow_csv_table.csv'

point2dem --stereographic --proj-lon 30.7383426 --proj-lat 20.1521625 --tr 20 --csv-format '2:lon 3:lat 4:radius_km' RDR_30E30E_20N20NPointPerRow_csv_table.csv --datum D_MOON

crop from = A.cub to = A_crop.cub sample = 1 line = 11123 nsamples = 5063 nlines = 7888
crop from = B.cub to = B_crop.cub sample = 1 line = 11391 nsamples = 5063 nlines = 7879
crop from = D.cub to = D_crop.cub sample = 1 line = 9913 nsamples = 5063 nlines = 5595
crop from = J.cub to = J_crop.cub sample = 1 line = 18474 nsamples = 5063 nlines = 8158

for f in *crop.cub; do reduce.pl $f 4; done

bundle_adjust *sub4.cub --min-matches 1 -o run_ba_sub4/run --ip-per-tile 5000 --overlap-limit 100

# Pick IP manually

bundle_adjust A_crop_sub4.cub B_crop_sub4.cub D_crop_sub4.cub J_crop_sub4.cub --min-matches 1 -o run_ba_sub4/run --ip-per-tile 5000 --overlap-limit 100 --ip-detect-method 1 --mapprojected-data "A_crop_sub4.map.tif B_crop_sub4.map.tif D_crop_sub4.map.tif J_crop_sub4.map.tif run_AB_crop_sub10/run-DEM.tif"

parallel_stereo A_crop_sub4.cub D_crop_sub4.cub run_AB_crop_sub4_tmp/run --job-size-h 1024 --job-size-w 1024 --bundle-adjust-prefix run_ba_sub4/run --min-num-ip 1 --subpixel-mode 3

point2dem run_AB_crop_sub4/run-PC.tif --stereographic --proj-lon 30.7383426 --proj-lat 20.1521625 --tr 4 --dem-hole-fill-len 100

pc_align run_AB_crop_sub4/run-DEM.tif RDR_30E30E_20N20NPointPerRow_csv_table.csv -o run_AB_crop_sub4/run/run --save-transformed-source-points --max-displacement 50

point2dem --stereographic --proj-lon 30.7383426 --proj-lat 20.1521625 --tr 4 --csv-format '1:lon 2:lat 3:radius_km' run_AB_crop_sub4/run/run-trans_source.csv --datum D_MOON

di run_AB_crop_sub4/run-DEM.tif run_AB_crop_sub4/run/run-trans_source-DEM.tif

for f in A B D J; do
    mapproject run_AB_crop_sub4/run-DEM.tif ${f}_crop_sub4.cub ${f}_crop_sub4.map.tif --tr 4 --bundle-adjust-prefix run_ba_sub4/run --tile-size 256
done

sw=0.06; dw=1e-9; parallel_sfs -i run_AB_crop_sub4/run-crop-DEM.tif A_crop_sub4.cub D_crop_sub4.cub J_crop_sub4.cub --tile-size 150 --padding 50 -o sfs_ADJ_sw${sw}_dw${dw}_sub4_faec/run --bundle-adjust-prefix run_ba_sub4/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --float-cameras --float-albedo

# Redoing everything at sub10, to get more convincing results
bundle_adjust A_crop_sub10.cub B_crop_sub10.cub D_crop_sub10.cub J_crop_sub10.cub --min-matches 1 -o run_ba_sub10/run --ip-per-tile 5000 --overlap-limit 100 --ip-detect-method 1 --mapprojected-data "A_crop_sub4.map.tif B_crop_sub4.map.tif D_crop_sub4.map.tif J_crop_sub4.map.tif run_AB_crop_sub10/run-DEM.tif"

for f in A B D J; do
    mapproject run_AB_crop_sub10/run-DEM.tif ${f}_crop_sub10.cub ${f}_crop_sub10.map.tif --tr 10 --bundle-adjust-prefix run_ba_sub10/run --tile-size 256
done

parallel_stereo A_crop_sub10.cub B_crop_sub10.cub run_AB_crop_sub10/run --job-size-h 512 --job-size-w 512 --bundle-adjust-prefix run_ba_sub10/run --min-num-ip 1 --subpixel-mode 3 --corr-tile-size 512

gdp -520 1650 660 -2150 run_AB_crop_sub10/run-DEM.tif run_AB_crop_sub10/run-crop-DEM.tif

pc_align run_AB_crop_sub10/run-crop-DEM.tif RDR_30E30E_20N20NPointPerRow_csv_table.csv -o run_AB_crop_sub10/run/run-crop --save-inv-transformed-reference-points --save-transformed-source-points --max-displacement 100

point2dem --stereographic --proj-lon 30.7383426 --proj-lat 20.1521625 --tr 10 --dem-hole-fill-len 100 run_AB_crop_sub10/run/run-crop-trans_reference.tif

geodiff --absolute run_AB_crop_sub10/run/run-crop-trans_reference-DEM.tif RDR_30E30E_20N20NPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km'

sw=0.06; dw=1e-9; sfs -i run_AB_crop_sub10/run-crop-DEM.tif A_crop_sub10.cub D_crop_sub10.cub J_crop_sub10.cub -o sfs_ADJ_sw${sw}_dw${dw}_sub10_fea/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --float-albedo


point2dem --stereographic --proj-lon 30.7383426 --proj-lat 20.1521625 --tr 10  --csv-format '1:lon 2:lat 3:height_above_datum' --datum D_MOON sfs_ADJ_sw0.06_dw1e-9_sub10_fe/run-crop-diff.csv 


gds -8 78 132 203 run_AB_crop_sub10/run-crop-DEM.tif run_AB_crop_sub10/run-crop3-DEM.tif

sw=0.12; dw=1e-9; sfs -i run_AB_crop_sub10/run-crop2-DEM.tif A_crop_sub10.cub D_crop_sub10.cub J_crop_sub10.cub -o sfs_ADJ_sw${sw}_dw${dw}_sub10_fe_th/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --shadow-thresholds '0.00133752392139285803 0.000953454291447997093 0.00324152735993266106'
sw=0.12; dw=1e-9; sfs -i run_AB_crop_sub10/run-crop2-DEM.tif A_crop_sub10.cub D_crop_sub10.cub J_crop_sub10.cub -o sfs_ADJ_sw${sw}_dw${dw}_sub10_fe/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10
sw=0.12; dw=1e-9; sfs -i run_AB_crop_sub10/run-crop2-DEM.tif A_crop_sub10.cub D_crop_sub10.cub J_crop_sub10.cub -o sfs_ADJ_sw${sw}_dw${dw}_sub10_fce/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --float-cameras
sw=0.12; dw=1e-9; sfs -i run_AB_crop_sub10/run-crop2-DEM.tif A_crop_sub10.cub D_crop_sub10.cub J_crop_sub10.cub -o sfs_ADJ_sw${sw}_dw${dw}_sub10_fae/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --float-albedo
sw=0.12; dw=1e-9; sfs -i run_AB_crop_sub10/run-crop2-DEM.tif A_crop_sub10.cub D_crop_sub10.cub J_crop_sub10.cub -o sfs_ADJ_sw${sw}_dw${dw}_sub10_face/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --float-albedo --float-cameras
sw=0.06; dw=1e-9; sfs -i run_AB_crop_sub10/run-crop2-DEM.tif A_crop_sub10.cub D_crop_sub10.cub J_crop_sub10.cub -o sfs_ADJ_sw${sw}_dw${dw}_sub10_fe_th/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --shadow-thresholds '0.00133752392139285803 0.000953454291447997093 0.00324152735993266106'
sw=0.06; dw=1e-9; sfs -i run_AB_crop_sub10/run-crop2-DEM.tif A_crop_sub10.cub D_crop_sub10.cub J_crop_sub10.cub -o sfs_ADJ_sw${sw}_dw${dw}_sub10_fe/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10
sw=0.06; dw=1e-9; sfs -i run_AB_crop_sub10/run-crop2-DEM.tif A_crop_sub10.cub D_crop_sub10.cub J_crop_sub10.cub -o sfs_ADJ_sw${sw}_dw${dw}_sub10_fce/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --float-cameras
sw=0.06; dw=1e-9; sfs -i run_AB_crop_sub10/run-crop2-DEM.tif A_crop_sub10.cub D_crop_sub10.cub J_crop_sub10.cub -o sfs_ADJ_sw${sw}_dw${dw}_sub10_fae/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --float-albedo
sw=0.06; dw=1e-9; sfs -i run_AB_crop_sub10/run-crop2-DEM.tif A_crop_sub10.cub D_crop_sub10.cub J_crop_sub10.cub -o sfs_ADJ_sw${sw}_dw${dw}_sub10_face/run --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-exposure --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --float-albedo --float-cameras

parallel_stereo A_crop.cub B_crop.cub run_AB_crop/run --job-size-h 512 --job-size-w 512 --bundle-adjust-prefix run_ba/run --min-num-ip 1 --subpixel-mode 3 --corr-tile-size 1024 --left-image-crop-win 67 1759 5118 4325

for dir in run_AB_crop run_AB_crop_sub10 sfs*sub10*; do dem=$(llt $dir/run*DEM*tif |grep -i -v hill | grep -i -v CMAP | grep -i -v diff | grep -i -v trans_reference | tail -n 1 | pc 0); pc_align --csv-format '2:lon 3:lat 4:radius_km' $dem RDR_30E30E_20N20NPointPerRow_csv_table.csv -o ${dir}/run-crop --save-inv-transformed-reference-points --save-transformed-source-points --max-displacement 100; point2dem --stereographic --proj-lon 30.7383426 --proj-lat 20.1521625 --tr 10 --dem-hole-fill-len 100 ${dir}/run-crop-trans_reference.tif; geodiff --absolute ${dir}/run-crop-trans_reference-DEM.tif RDR_30E30E_20N20NPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km' -o ${dir}/run-crop; done

g mean */run-crop-diff.csv | sortbycol.pl 0

point2dem --stereographic --proj-lon 30.7383426 --proj-lat 20.1521625 --tr 4 --csv-format '1:lon 2:lat 3:height_above_datum' --datum D_MOON sfs_ADJ_sw0.06_dw1e-9_sub10_fe/run-crop-diff.csv

for f in run_AB_crop_sub10/run-crop-diff-DEM.tif sfs_ADJ_sw0.06_dw1e-9_sub10_fe_th/run-crop-diff-DEM.tif sfs_ADJ_sw0.06_dw1e-9_sub10_fe/run-crop-diff-DEM.tif; do colormap --min 0 --max 10 $f; done

cd /home/oalexan1/projects/sfs_lola_sub10
sg run_AB_crop_sub10/run-crop-diff-DEM_CMAP.tif sfs_ADJ_sw0.06_dw1e-9_sub10_fe_th/run-crop-diff-DEM_CMAP.tif run_AB_crop_sub10/run-crop2-DEM.tif sfs_ADJ_sw0.06_dw1e-9_sub10_fe_th/run-DEM-final.tif

# Without correcting for alignment to LOLA:
geodiff --absolute run_AB_crop_sub10/run-crop2-DEM.tif  RDR_30E30E_20N20NPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km'
Max difference:       33.2717
Min difference:       0.469824
Mean difference:      9.9234
StdDev of difference: 4.46189

geodiff --absolute  sfs_ADJ_sw0.06_dw1e-9_sub10_fe_th/run-DEM-final.tif RDR_30E30E_20N20NPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km'
	--> Setting number of processing threads to: 8
	Found input nodata value for DEM: -3.40282e+38
Max difference:       30.5648
Min difference:       0.0836484
Mean difference:      10.6317
StdDev of difference: 5.07699

# Doing alignment
for dem in run_AB_crop_sub10/run-crop2-DEM.tif sfs_ADJ_sw0.06_dw1e-9_sub10_fe_th/run-DEM-final.tif; do
    dir=$(dirname $dem)
    pc_align --csv-format '2:lon 3:lat 4:radius_km' $dem RDR_30E30E_20N20NPointPerRow_csv_table.csv -o ${dir}/run-align --save-inv-transformed-reference-points --save-transformed-source-points --max-displacement 100
    point2dem --stereographic --proj-lon 30.7383426 --proj-lat 20.1521625 --tr 10 --dem-hole-fill-len 100 ${dir}/run-align-trans_reference.tif
    geodiff --absolute ${dir}/run-align-trans_reference-DEM.tif RDR_30E30E_20N20NPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km' -o ${dir}/run-align # abs diff
    geodiff ${dir}/run-align-trans_reference-DEM.tif RDR_30E30E_20N20NPointPerRow_csv_table.csv --csv-format '2:lon 3:lat 4:radius_km' -o ${dir}/run-align-signed     # signed diff
done

# Before sfs
Max difference:       15.8394
Min difference:       0.00232838
Mean difference:      2.56544
StdDev of difference: 2.38103

# After SfS
Max difference:       8.50961
Min difference:       0.00120037
Mean difference:      2.05671
StdDev of difference: 1.72044

# Mean difference:      2.565440115531573
# StdDev of difference: 2.381034166249015

g -A 2 mean sfs_ADJ_sw0.06_dw1e-9_sub10_fe_th/run-crop-diff.csv
# Mean difference:      2.056705706172215
# StdDev of difference: 1.72044423128955

# Signed difference
# Before
Mean difference:      0.0772988
StdDev of difference: 3.49926

# After
Mean difference:      0.040961
StdDev of difference: 2.6811


# Running around the equator
di sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif
  Minimum=0.000, Maximum=10.951, Mean=1.810, StdDev=1.353

# Starting with the exact solution
sfs -i run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif  E_crop_sub10.cub G_crop_sub10.cub H_crop_sub10.cub -o sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00_exact/run --reflectance-type 1 --smoothness-weight 0.08 --initial-dem-constraint-weight 0.00 --max-iterations 10 --integrability-constraint-weight 0.00 --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-albedo --float-exposure --smoothness-weight-pq 0.00 

for f in  sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fe_swpq0.00_exact/run-DEM-final.tif sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00_exact/run-DEM-final.tif; do echo $f; di $f run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif; done
sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif
  Minimum=0.000, Maximum=10.951, Mean=1.810, StdDev=1.353
sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fe_swpq0.00_exact/run-DEM-final.tif
  Minimum=0.000, Maximum=22.100, Mean=6.382, StdDev=4.941
sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00_exact/run-DEM-final.tif
  Minimum=0.000, Maximum=9.363, Mean=2.343, StdDev=1.580

sfs -i run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif  E_crop_sub10.cub G_crop_sub10.cub H_crop_sub10.cub -o sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00_exact_fixdem/run --reflectance-type 1 --smoothness-weight 0.08 --initial-dem-constraint-weight 0.00 --max-iterations 10 --integrability-constraint-weight 0.00 --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-albedo --float-exposure --smoothness-weight-pq 0.00 --fix-dem

Keping the dem fixed and floating the sun does not make much of a difference

export ISISROOT=$HOME/projects/base_system; sfs -i run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif E_crop_sub10.cub G_crop_sub10.cub H_crop_sub10.cub -o sfs_EGH_sw0.06_iw0.00_dw0.0015_sub10_faer3sc_swpq0.000_exact/run --reflectance-type 3 --smoothness-weight 0.06 --initial-dem-constraint-weight 0.0015 --max-iterations 10 --integrability-constraint-weight 0.00 --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-albedo --float-exposure --smoothness-weight-pq 0.000 --float-reflectance-model --float-sun-position --float-cameras

gdal_translate -projwin -1060 1540 700 -190 run_EF_sub10_stereo_ba_subpix3/run-DEM.tif run_EF_sub10_stereo_ba_subpix3/run-crop4-DEM.tif

./StereoPipeline-2.6.1-2018-08-24-x86_64-Linux/bin/sfs -i run_EF_sub10_stereo_ba_subpix3/run-crop4-DEM.tif E_crop_sub10.cub G_crop_sub10.cub H_crop_sub10.cub -o sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00_crop4/run --reflectance-type 1 --smoothness-weight 0.08 --initial-dem-constraint-weight 0.00 --max-iterations 10 --integrability-constraint-weight 0.00 --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-albedo --float-exposure --smoothness-weight-pq 0.00    

gdal_translate -projwin -250 1360 1220 -80 run_EF_sub10_stereo_ba_subpix3/run-DEM.tif run_EF_sub10_stereo_ba_subpix3/run-crop5-DEM.tif

Using SfS by avoiding the area of very bright terrain gives good results.

There are boundary effects. Changing the region changes the effects.

Floating DEM at the boundary does not help with boundary effects. Perhaphs it can help to float them DEM at the boundary but with a strong boundary constraint. Or need to think of honest boundary conditions. Or need to minimize the intensity at the boundary too, by computing the normal at boundary points. This last one may be promising.

Mars!

HIGH RESOLUTION DIGITAL TERRAIN MODELS OF THE MARTIAN SURFACE: COMPENSATION
OF THE ATMOSPHERE ON CTX IMAGERY.
https://www.hou.usra.edu/meetings/lpsc2018/pdf/2498.pdf
No details whatsoever. It fits some kind of polynomial. But good pointers to references. 
Uses CTX.
Image: D10_031288_1410_XN_39S200W

Fusion of photogrammetric and photoclinometric information for high-resolution DEMs from Mars in-orbit imagery
https://www.sciencedirect.com/science/article/pii/S0924271616306554
It cites our stereo and sfs work as inspiration.
It applies correction to the image for atmospheric effects based on CRISM.
Has a very simple and likely fast discretization. Need to look at it.
Image ID	G20_025904_2209_XN_40N102W	G20_025970_2217_XN_41N102W
Image ID	B20_017600_1538_XN_26S183W	B21_017745_1538_XN_26S183W
Image ID	B21_017786_1746_XN_05s222w	B21_017931_1746_XN_05s222w
See more here about weights used, etc.

The initial model does not come from CTX but from HiRISE and it is smoothed.
Then it is used for comparison.

Look at the pair given by Pragya
Also look at what Randy is saying about the model.

High-quality shape from multi-view stereo and shading under general illumination
CVPR 2011 (2011)

#Kirk's comments
#I think the authors overestimate the difficulties of photometric modeling for Mars. The first-order effects of atmospheric scattering are (a) attenuation of the signal from the surface, (b) illumination of the surface from the sky in a way that is fairly directional though less so than sunlight, and (c) contribution of a fairly uniform radiance across the scene by scattering from atmosphere to camera. The first two effects are essentially multiplicative and can be modeled along with exposure time and mean albedo in the factor T of Eq. 1. The state of the art for handling the third term is to introduce a uniform "haze" value for each image that is subtracted before it is compared to the model image. A quick test of this approach could be done by pre-subtracting a value based on shadow intensities as estimated with the thresholding tool, provided there are shadows. A much more powerful way to implement it would be to adjust the haze level for each image as part of the optimization, adding one more parameter per image. A test with the simpler approach might be in scope for revising this paper. I won't be surprised if the approach requiring software development isn't. In any case, there is little point in attempting Mars SfS without making some sort of haze correction.

#I also think the authors overestimate the difficulties of Mars's surface photometry a bit. The Moon also has mineralogical and roughness variations. The former influence albedo and to some extent photometric function "shape" quite a bit, the latter influences the "shape" strongly. However, the main impact of this photometric "shape" is on the contrast of shading for a given slope. This can be conveniently lumped in with haze parameter, which also affects fractional contrast of the model images. The approach has been used in the literature and works because the results are calibrated against pre-existing topography. Thus, the photometric parameters can be set and the "haze" adjusted to give the correct result. A slightly different photometric choice might yield a slightly different haze level but essentially the same topographic result because of the use of a priori topography to constrain the problem.


# Can even use a qudratic polynomial for reflectance, so I = a + b*R + c*R^2.

https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=5995388
We use a small smoothness weight
in regions with large image gradients, allowing the shading
constraint to capture fine detail.  In areas where the image
gradient is small, the shape is most likely smooth, so we use
a larger smoothness weight.

Still not clear why for the bright albedo blob the results are off. 

