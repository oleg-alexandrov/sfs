ln -s ../sfs/M139939938LE.cal.echo.cub H.cub
ln -s ../sfs/M139946735RE.cal.echo.cub I.cub
ln -s ../sfs/M173004270LE.cal.echo.cub L.cub
ln -s ../sfs/M122270273LE.cal.echo.cub N.cub


# 1 image
#parallel_stereo --job-size-w 1024 --job-size-h 1024 H.cub I.cub --left-image-crop-win 0 7998 2728 2696 --right-image-crop-win 0 9377 2733 2505 --threads 16 --corr-seed-mode 1 --subpixel-mode 3 run_full/run
#point2dem -r moon --stereographic --proj-lon 0 --proj-lat -90 run_full/run-PC.tif
#gdal_translate -projwin -15471.9 150986 -14986.7 150549 run_full/run-DEM.tif run_full/run-crop-DEM.tif
#sfs -i run_full/run-crop-DEM.tif H.cub -o sfs/run --smoothness-weight 0.08 --reflectance-type 0  --max-iterations 100 --use-approx-camera-models

# many images

tl1 H_crop.cub I_crop.cub L_crop.cub N_crop.cub
crop from = H.cub to = H_crop.cub sample = 1 line = 6644 nsamples = 2192 nlines = 4982
crop from = I.cub to = I_crop.cub sample = 1 line = 7013 nsamples = 2531 nlines = 7337
crop from = L.cub to = L_crop.cub sample = 1 line = 1 nsamples = 2531 nlines = 8305
crop from = N.cub to = N_crop.cub sample = 1 line = 1 nsamples = 2531 nlines = 2740

for f in H I L N; do 
  reduce from = ${f}_crop.cub to = ${f}_crop_sub10.cub sscale = 10 lscale = 10
done

bundle_adjust H_crop.cub I_crop.cub L_crop.cub N_crop.cub --min-matches 1 -o run_ba/run --ip-per-tile 5000

for s in H I L N; do 
	reduce from = ${s}_crop.cub to = ${s}_crop_sub10.cub sscale = 10 lscale = 10
done


bundle_adjust H_crop_sub10.cub I_crop_sub10.cub L_crop_sub10.cub N_crop_sub10.cub --min-matches 1 -o run_ba_sub10/run --ip-per-tile 100000

stereo H_crop.cub I_crop.cub run_full2/run --subpixel-mode 3 --bundle-adjust-prefix run_ba/run

stereo H_crop_sub10.cub I_crop_sub10.cub run_sub10/run --subpixel-mode 3 --bundle-adjust-prefix run_ba_sub10/run

pc_align --max-displacement 200 run_full2/run-PC.tif run_sub10/run-PC.tif -o run_full2/run --save-inv-transformed-reference-points
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 run_full2/run-trans_reference.tif

gdal_translate -projwin -15540.7 151403 -14554.5 150473 run_full2/run-trans_reference-DEM.tif run_full2/run-crop-DEM.tif
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 run_sub10/run-PC.tif
gdal_translate -projwin -15540.7 151403 -14554.5 150473 run_sub10/run-DEM.tif run_sub10/run-crop-DEM.tif

export e=0.12; /usr/bin/time sfs -i run_sub10/run-crop-DEM.tif H_crop_sub10.cub L_crop_sub10.cub N_crop_sub10.cub -o sfs_yesalb_wt${e}/run --threads 1 --smoothness-weight ${e} --max-iterations 20 --reflectance-type 0 --float-albedo --float-exposure --float-cameras --use-approx-camera-models --bundle-adjust-prefix run_ba_sub10/run --shadow-thresholds "0.00162484 0.0012166 0.000781663"
mapproject sfs/run-DEM-iter59.tif H_crop_sub10.cub H_crop_sub10_map.tif --bundle-adjust-prefix run_ba_sub10/run




old

crop from = H.cub to = H_crop.cub sample = 1 line = 7785 nsamples = 2531 nlines = 2490
crop from = I.cub to = I_crop.cub sample = 1 line = 8647 nsamples = 2531 nlines = 3412

 crop from = L.cub to = L_crop.cub sample = 1 line = 263 nsamples = 2531 nlines = 3042
 crop from = N.cub to = N_crop.cub sample = 1 line = 1 nsamples = 2531 nlines = 2658

 reduce from = H_crop.cub to = H_crop_sub10.cub sscale = 10 lscale = 10

 bundle_adjust H_crop_sub10.cub I_crop_sub10.cub L_crop_sub10.cub N_crop_sub10.cub --min-matches 10 -o run_HILN3_sub10/run

 bundle_adjust H_crop.cub I_crop.cub L_crop.cub N_crop.cub --min-matches 10 -o run_HILN3/run
  point2dem  -r moon --nodata-value -32768  --tr 10 --stereographic --proj-lon 0 --proj-lat -90 run_HI_sub10_v7/run-PC.tif

 stereo H_crop.cub I_crop.cub run_HI_full_v7/run --subpixel-mode 3 --bundle-adjust-prefix run_HILN3/run

 point2dem -r moon --nodata-value -32768 --tr 10 --stereographic --proj-lon 0 --proj-lat -90 run_HI_sub10_v7/run-PC.tif

gdal_translate -co compress=lzw -co TILED=yes -co INTERLEAVE=BAND -co BLOCKXSIZE=256 -co BLOCKYSIZE=256 -projwin -15540.7 151403 -14554.5 150473 run_HI_sub10_v7/run-DEM.tif run_HI_sub10_v7/run-crop1-DEM.tif   


pc_align --max-displacement 100 run_HI_full_v7/run-PC.tif run_HI_sub10_v7/run-PC.tif  -o run_HI_full_v7/run --save-inv-transformed-reference-points 



parallel_stereo --job-size-w 1024 --job-size-h 1024 H.cub I.cub    \
                --left-image-crop-win -89 7998 2728 2696           \
                --right-image-crop-win -115 9377 2733 2505         \
                --threads 16 --corr-seed-mode 1  --subpixel-mode 3 \
                run_HI_full3/run

pd --tr 10 --stereographic --proj-lon 0 --proj-lat -90 run_HI_full3/run-PC.tif -o run_HI_full3/run-DEM_10mpp.tif

gdt -projwin -15435.000, 151465.000 -14665.000, 150705.000 run_HI_full3/run-DEM_10mpp.tif run_HI_full3/run-crop5-DEM.tif


parallel_stereo --job-size-w 1024 --job-size-h 1024 H_sub10.cub I_sub10.cub run_HI_sub10_v5/run --subpixel-mode 3

pd --tr 10 --stereographic --proj-lon 0 --proj-lat -90 run_HI_sub10_v5/run-PC.tif

gdt -projwin -15435.000, 151465.000 -14665.000, 150705.000 run_HI_sub10_v5/run-DEM.tif run_HI_sub10_v5/run-crop5-DEM.tif

bundle_adjust H_sub10.cub L_sub10.cub N_sub10.cub -o run_ba_HLN2/run --min-matches 1


export e=0.16; is; sfs -i run_HI_sub10_v5/run-crop5-DEM.tif H_sub10.cub L_sub10.cub N_sub10.cub -o sfs_HLN_s${e}_r0/run --threads 1 --smoothness-weight $e --max-iterations 100 --reflectance-type 0 --float-albedo --float-exposure --float-cameras --use-approx-camera-models

export e=0.16; is; sfs -i run_HI_sub10_v5/run-crop5-DEM.tif H_sub10.cub L_sub10.cub N_sub10.cub -o sfs_HLN_s${e}_r0_thresh/run --threads 1 --smoothness-weight $e --max-iterations 100 --reflectance-type 0 --float-albedo --float-exposure --float-cameras --use-approx-camera-models --shadow-thresholds "0.00170714 0.00123419 0.00125456"



old


bundle_adjust H.cub I.cub -o run_ba_HI/run

stereo H.cub I.cub --left-image-crop-win -0 7920 1890 2020 --right-image-crop-win 260 9410 1930 1940 run_HI_full/run --subpixel-mode 3  --bundle-adjust-prefix run_ba_HI/run

cd run_ba_HI
cp run-H.adjust run-H_sub10.adjust
cp run-I.adjust run-I_sub10.adjust

stereo H_sub10.cub I_sub10.cub --left-image-crop-win -0 792 189 202 --right-image-crop-win 26 941 193 194 run_HI_sub10/run --subpixel-mode 3 --bundle-adjust-prefix run_ba_HI/run

pd --tr 10 --stereographic --proj-lon 0 --proj-lat -90 run_HI_full/run-PC.tif 

pd --tr 10 --stereographic --proj-lon 0 --proj-lat -90 run_HI_sub10/run-PC.tif

gdt -projwin -15435.000, 151465.000 -14665.000, 150705.000 run_HI_full/run-DEM.tif run_HI_full/run-crop1-DEM.tif

gdt -projwin -15435.000, 151465.000 -14665.000, 150705.000 run_HI_sub10/run-DEM.tif run_HI_sub10/run-crop1-DEM.tif

diff.sh run_HI_full/run-crop1-DEM.tif run_HI_sub10/run-crop1-DEM.tif


export e=0.16; is; sfs -i run_HI_sub10/run-crop1-DEM.tif  H_sub10.cub L_sub10.cub N_sub10.cub -o sfs_HLN_s${e}_r0/run --threads 1 --smoothness-weight $e --max-iterations 100 --reflectance-type 0 --float-albedo --float-exposure --float-cameras


