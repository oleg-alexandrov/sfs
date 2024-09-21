#!/bin/bash

for f in M139939938LE.cal.echo.cub M139946735RE.cal.echo.cub \
    M173004270LE.cal.echo.cub M122270273LE.cal.echo.cub; do
    spiceinit from = $f
done

ln -s M139939938LE.cal.echo.cub A.cub
ln -s M139946735RE.cal.echo.cub B.cub
ln -s M173004270LE.cal.echo.cub C.cub
ln -s M122270273LE.cal.echo.cub D.cub

crop from = A.cub to = A_crop.cub sample = 1 line = 6644 nsamples = 2192 nlines = 4982
crop from = B.cub to = B_crop.cub sample = 1 line = 7013 nsamples = 2531 nlines = 7337
crop from = C.cub to = C_crop.cub sample = 1 line = 1 nsamples = 2531 nlines = 8305
crop from = D.cub to = D_crop.cub sample = 1 line = 1 nsamples = 2531 nlines = 2740

bundle_adjust A_crop.cub B_crop.cub C_crop.cub D_crop.cub    \
    --min-matches 10 -o run_ba/run
stereo A_crop.cub B_crop.cub run_full2/run --subpixel-mode 3 \
    --bundle-adjust-prefix run_ba/run

for f in A B C D; do 
    reduce from = "$f"_crop.cub to = "$f"_crop_sub10.cub sscale = 10 lscale = 10
done

bundle_adjust A_crop_sub10.cub B_crop_sub10.cub C_crop_sub10.cub D_crop_sub10.cub \
    --min-matches 1 -o run_ba_sub10/run --ip-per-tile 100000
stereo A_crop_sub10.cub B_crop_sub10.cub run_sub10/run --subpixel-mode 3           \
    --bundle-adjust-prefix run_ba_sub10/run

pc_align --max-displacement 200 run_full2/run-PC.tif run_sub10/run-PC.tif \
    -o run_full2/run --save-inv-transformed-reference-points

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    run_full2/run-trans_reference.tif
gdal_translate -projwin -15540.7 151403 -14554.5 150473  \
    run_full2/run-trans_reference-DEM.tif run_full2/run-crop-DEM.tif

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    run_sub10/run-PC.tif
gdal_translate -projwin -15540.7 151403 -14554.5 150473  \
    run_sub10/run-DEM.tif run_sub10/run-crop-DEM.tif

sfs -i run_sub10/run-crop-DEM.tif A_crop_sub10.cub C_crop_sub10.cub   \
    D_crop_sub10.cub -o sfs1/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run_ba_sub10/run                           

sfs -i run_sub10/run-crop-DEM.tif A_crop_sub10.cub C_crop_sub10.cub   \
    D_crop_sub10.cub -o sfs2/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run_ba_sub10/run                           \
    --shadow-thresholds "0.00140184 0.00125027 0.0000718167 "

sfs -i run_sub10/run-crop-DEM.tif A_crop_sub10.cub C_crop_sub10.cub   \
    D_crop_sub10.cub -o sfs3/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run_ba_sub10/run                           \
    --shadow-thresholds "0.00140184 0.00125027 0.000718167 "


for i in 1 2 3; do 
    geodiff --absolute run_full2/run-crop-DEM.tif run_sub10/run-crop-DEM.tif -o sfs$i/ref
    geodiff --absolute run_full2/run-crop-DEM.tif sfs$i/run-DEM-iter0.tif      -o sfs$i/beg
    geodiff --absolute run_full2/run-crop-DEM.tif sfs$i/run-DEM-final.tif      -o sfs$i/end
done

for i in 1 2 3; do 
    gim sfs$i/ref-diff.tif
    gim sfs$i/beg-diff.tif
    gim sfs$i/end-diff.tif
done

# Now try witout echo

ln -s ../M139939938LE.cal.cub A5.cub
ln -s ../M139946735RE.cal.cub B5.cub
ln -s ../M173004270LE.cal.cub C5.cub
ln -s ../M122270273LE.cal.cub D5.cub

crop from = A5.cub to = A5_crop.cub sample = 1 line = 6644 nsamples = 2192 nlines = 4982
crop from = B5.cub to = B5_crop.cub sample = 1 line = 7013 nsamples = 2531 nlines = 7337
crop from = C5.cub to = C5_crop.cub sample = 1 line = 1 nsamples = 2531 nlines = 8305
crop from = D5.cub to = D5_crop.cub sample = 1 line = 1 nsamples = 2531 nlines = 2740

bundle_adjust A5_crop.cub B5_crop.cub C5_crop.cub D5_crop.cub    \
    --min-matches 10 -o run5_ba/run
stereo A5_crop.cub B5_crop.cub run5_full/run --subpixel-mode 3 \
    --bundle-adjust-prefix run5_ba/run

for f in A5 B5 C5 D5; do 
    reduce from = "$f"_crop.cub to = "$f"_crop_sub10.cub sscale = 10 lscale = 10
done

bundle_adjust A5_crop_sub10.cub B5_crop_sub10.cub C5_crop_sub10.cub D5_crop_sub10.cub \
    --min-matches 1 -o run5_ba_sub10/run --ip-per-tile 100000
stereo A5_crop_sub10.cub B5_crop_sub10.cub run5_sub10/run --subpixel-mode 3           \
    --bundle-adjust-prefix run5_ba_sub10/run

pc_align --max-displacement 200 run5_full/run-PC.tif run5_sub10/run-PC.tif \
    -o run5_full/run --save-inv-transformed-reference-points

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    run5_full/run-trans_reference.tif
gdal_translate -projwin -15540.7 151403 -14554.5 150473  \
    run5_full/run-trans_reference-DEM.tif run5_full/run-crop-DEM.tif

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    run5_sub10/run-PC.tif
gdal_translate -projwin -15540.7 151403 -14554.5 150473  \
    run5_sub10/run-DEM.tif run5_sub10/run-crop-DEM.tif

sfs -i run5_sub10/run-crop-DEM.tif A5_crop_sub10.cub C5_crop_sub10.cub   \
    D5_crop_sub10.cub -o sfs51/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run5_ba_sub10/run                           

sfs -i run5_sub10/run-crop-DEM.tif A5_crop_sub10.cub C5_crop_sub10.cub   \
    D5_crop_sub10.cub -o sfs52/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run5_ba_sub10/run                           \
    --shadow-thresholds "0.00140184 0.00125027 0.0000718167 "

sfs -i run5_sub10/run-crop-DEM.tif A5_crop_sub10.cub C5_crop_sub10.cub   \
    D5_crop_sub10.cub -o sfs53/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run5_ba_sub10/run                           \
    --shadow-thresholds "0.00140184 0.00125027 0.000718167 "


for i in 1 2 3; do 
    geodiff --absolute run5_full/run-crop-DEM.tif run5_sub10/run-crop-DEM.tif -o sfs5$i/ref
    geodiff --absolute run5_full/run-crop-DEM.tif sfs5$i/run-DEM-iter0.tif      -o sfs5$i/beg
    geodiff --absolute run5_full/run-crop-DEM.tif sfs5$i/run-DEM-final.tif      -o sfs5$i/end
done

for i in 1 2 3; do 
    gim sfs5$i/ref-diff.tif
    gim sfs5$i/beg-diff.tif
    gim sfs5$i/end-diff.tif
done



# Second approach at sfs, BA only A and B, results are worse. Using more
# levels makes it worse too.
bundle_adjust A_crop.cub B_crop.cub --min-matches 10 -o run0_ba/run
stereo A_crop.cub B_crop.cub run0_full/run --subpixel-mode 3 \
    --bundle-adjust-prefix run0_ba/run

for f in A B C D; do 
    reduce from = "$f"_crop.cub to = "$f"_crop_sub10.cub sscale = 10 lscale = 10
done

bundle_adjust A_crop_sub10.cub B_crop_sub10.cub \
    --min-matches 1 -o run0_ba_sub10/run --ip-per-tile 100000
stereo A_crop_sub10.cub B_crop_sub10.cub run0_sub10/run --subpixel-mode 3           \
    --bundle-adjust-prefix run0_ba_sub10/run

pc_align --max-displacement 200 run0_full/run-PC.tif run0_sub10/run-PC.tif \
    -o run0_full/run --save-inv-transformed-reference-points

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    run0_full/run-trans_reference.tif
gdal_translate -projwin -15540.7 151403 -14554.5 150473 \
    run0_full/run-trans_reference-DEM.tif run0_full/run-crop-DEM.tif

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    run0_sub10/run-PC.tif
gdal_translate -projwin -15540.7 151403 -14554.5 150473 \
    run0_sub10/run-DEM.tif run0_sub10/run-crop-DEM.tif


sfs -i run0_sub10/run-crop-DEM.tif A_crop_sub10.cub C_crop_sub10.cub   \
    D_crop_sub10.cub -o sfs11/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run0_ba_sub10/run                           

sfs -i run0_sub10/run-crop-DEM.tif A_crop_sub10.cub C_crop_sub10.cub   \
    D_crop_sub10.cub -o sfs12/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run0_ba_sub10/run                           \
    --shadow-thresholds "0.00140184 0.00125027 0.0000718167 "

sfs -i run0_sub10/run-crop-DEM.tif A_crop_sub10.cub C_crop_sub10.cub   \
    D_crop_sub10.cub -o sfs13/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run0_ba_sub10/run                           \
    --shadow-thresholds "0.00140184 0.00125027 0.000718167 "

for i in 1 2 3; do 
    geodiff --absolute run0_full/run-crop-DEM.tif run0_sub10/run-crop-DEM.tif -o sfs1$i/ref
    geodiff --absolute run0_full/run-crop-DEM.tif sfs1$i/run-DEM-iter0.tif    -o sfs1$i/beg
    geodiff --absolute run0_full/run-crop-DEM.tif sfs1$i/run-DEM-final.tif    -o sfs1$i/end
done

for i in 1 2 3; do 
    gim sfs1$i/ref-diff.tif
    gim sfs1$i/beg-diff.tif
    gim sfs1$i/end-diff.tif
done

#end

sfs -i run0_sub10/run-crop-DEM.tif A_crop_sub10.cub C_crop_sub10.cub   \
    D_crop_sub10.cub -o sfs21/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run0_ba_sub10/run --coarse-levels 1                          

sfs -i run0_sub10/run-crop-DEM.tif A_crop_sub10.cub C_crop_sub10.cub   \
    D_crop_sub10.cub -o sfs22/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run0_ba_sub10/run                           \
    --shadow-thresholds "0.00140184 0.00125027 0.0000718167 " --coarse-levels 1

sfs -i run0_sub10/run-crop-DEM.tif A_crop_sub10.cub C_crop_sub10.cub   \
    D_crop_sub10.cub -o sfs23/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run0_ba_sub10/run                           \
    --shadow-thresholds "0.00140184 0.00125027 0.000718167 " --coarse-levels 1

for i in 1 2 3; do 
    geodiff --absolute run0_full/run-crop-DEM.tif run0_sub10/run-crop-DEM.tif -o sfs2$i/ref
    geodiff --absolute run0_full/run-crop-DEM.tif sfs2$i/run-DEM-iter0-level0.tif    -o sfs2$i/beg
    geodiff --absolute run0_full/run-crop-DEM.tif sfs2$i/run-DEM-final-level0.tif    -o sfs2$i/end
done

for i in 1 2 3; do 
    gim sfs2$i/ref-diff.tif
    gim sfs2$i/beg-diff.tif
    gim sfs2$i/end-diff.tif
done

#end

sfs -i run0_sub10/run-crop-DEM.tif A_crop_sub10.cub C_crop_sub10.cub   \
    D_crop_sub10.cub -o sfs31/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run0_ba_sub10/run --coarse-levels 2                          

sfs -i run0_sub10/run-crop-DEM.tif A_crop_sub10.cub C_crop_sub10.cub   \
    D_crop_sub10.cub -o sfs32/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run0_ba_sub10/run                           \
    --shadow-thresholds "0.00140184 0.00125027 0.0000718167 " --coarse-levels 2

sfs -i run0_sub10/run-crop-DEM.tif A_crop_sub10.cub C_crop_sub10.cub   \
    D_crop_sub10.cub -o sfs33/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix run0_ba_sub10/run                           \
    --shadow-thresholds "0.00140184 0.00125027 0.000718167 " --coarse-levels 2

for i in 1 2 3; do 
    geodiff --absolute run0_full/run-crop-DEM.tif run0_sub10/run-crop-DEM.tif -o sfs3$i/ref
    geodiff --absolute run0_full/run-crop-DEM.tif sfs3$i/run-DEM-iter0-level0.tif    -o sfs3$i/beg
    geodiff --absolute run0_full/run-crop-DEM.tif sfs3$i/run-DEM-final-level0.tif    -o sfs3$i/end
done

for i in 1 2 3; do 
    gim sfs3$i/ref-diff.tif
    gim sfs3$i/beg-diff.tif
    gim sfs3$i/end-diff.tif
done

#end

for f in A B C D; do 
    mapproject run_sub10/run-crop-DEM.tif ${f}_crop_sub10.cub ${f}_crop_sub10_map.tif \
	--bundle-adjust-prefix run_ba_sub10/run
done


# other
mapproject run_sub10/run-crop2-DEM.tif A_crop_sub10.cub A_crop_map.tif \
    --bundle-adjust-prefix run_ba_sub10/run --tile-size 64
mapproject run_sub10/run-crop2-DEM.tif B_crop_sub10.cub B_crop_map.tif \
    --bundle-adjust-prefix run_ba_sub10/run --tile-size 64
mapproject run_sub10/run-crop2-DEM.tif C_crop_sub10.cub C_crop_map.tif \
    --bundle-adjust-prefix run_ba_sub10/run --tile-size 64
mapproject run_sub10/run-crop2-DEM.tif D_crop_sub10.cub D_crop_map.tif \
    --bundle-adjust-prefix run_ba_sub10/run --tile-size 64


gdal_translate -projwin -15556.191 151703.09 -14357.869 150043.03 \
    run_sub10/run-DEM.tif run_sub10/run-crop2-DEM.tif
gdal_translate -projwin -15556.191 151703.09 -14357.869 150043.03 \
    run_full2/run-trans_reference-DEM.tif run_full2/run-crop2-DEM.tif
sfs -i run_sub10/run-crop2-DEM.tif A_crop_sub10.cub C_crop_sub10.cub \
    D_crop_sub10.cub -o sfs_crop2/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure              \
    --float-cameras --use-approx-camera-models                              \
    --bundle-adjust-prefix run_ba_sub10/run                                 \
    --shadow-thresholds "0.00162484 0.0012166 0.000781663"


crop.pl A.cub 1 5644 10000 6982  A2_crop.cub
crop.pl B.cub 1 7013 10000 7337  B2_crop.cub
crop.pl C.cub 1 1    10000 8305  C2_crop.cub
crop.pl D.cub 1 1    10000 2740  D2_crop.cub

sfs -i run_sub10/run-crop2-DEM.tif A_crop_sub10.cub C_crop_sub10.cub        \
     -o sfs_crop_AC/run --threads 1 --smoothness-weight 0.12                \
    --max-iterations 100 --reflectance-type 0 --float-exposure              \
    --float-cameras --use-approx-camera-models                              \
    --bundle-adjust-prefix run_ba_sub10/run                                 \
    --shadow-thresholds "0.00162484 0.0012166"

sfs -i run_sub10/run-crop2-DEM.tif A_crop_sub10.cub D_crop_sub10.cub        \
    -o sfs_crop_AD/run --threads 1 --smoothness-weight 0.12                 \
    --max-iterations 100 --reflectance-type 0 --float-exposure              \
    --float-cameras --use-approx-camera-models                              \
    --bundle-adjust-prefix run_ba_sub10/run                                 \
    --shadow-thresholds "0.00162484 0.000781663"

geodiff --absolute run_full2/run-crop-DEM.tif sfs/run-DEM-iter0.tif -o sfs/diff_start
geodiff --absolute run_full2/run-crop-DEM.tif sfs/run-DEM-final.tif -o sfs/diff_final
gim sfs_crop2/diff_start-diff.tif
gim sfs_crop2/diff_final-diff.tif


for dir in sfs sfs_crop2 sfs_crop_AC sfs_crop_AD; do 
    geodiff --absolute run_full2/run-crop-DEM.tif $dir/run-DEM-iter0.tif -o $dir/diff_start
    geodiff --absolute run_full2/run-crop-DEM.tif $dir/run-DEM-final.tif -o $dir/diff_final
done
    
for dir in sfs sfs_crop2 sfs_crop_AC sfs_crop_AD; do 
    gim $dir/diff_start-diff.tif
    gim $dir/diff_final-diff.tif
done

bundle_adjust A2_crop.cub B2_crop.cub C2_crop.cub D2_crop.cub    \
    --min-matches 10 -o run_ba_crop2/run
stereo A2_crop.cub B2_crop.cub run_full_crop2/run --subpixel-mode 3 \
    --bundle-adjust-prefix run_ba_crop2/run

for f in A B C D; do 
    reduce from = "$f"2_crop.cub to = "$f"2_crop_sub10.cub sscale = 10 lscale = 10
done

bundle_adjust A2_crop_sub10.cub B2_crop_sub10.cub C2_crop_sub10.cub D2_crop_sub10.cub \
    --min-matches 1 -o run_ba_crop2_sub10/run --ip-per-tile 100000

stereo A2_crop_sub10.cub B2_crop_sub10.cub run_crop2_sub10/run --subpixel-mode 3  \
    --bundle-adjust-prefix run_ba_crop2_sub10/run

pc_align --max-displacement 200 run_full_crop2/run-PC.tif run_crop2_sub10/run-PC.tif \
    -o run_full_crop2/run --save-inv-transformed-reference-points

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    run_full_crop2/run-trans_reference.tif
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    run_crop2_sub10/run-PC.tif

mapproject run_crop2_sub10/run-DEM.tif A2_crop_sub10.cub A2_crop_map.tif \
    --bundle-adjust-prefix run_ba_crop2_sub10/run --tile-size 64
mapproject run_crop2_sub10/run-DEM.tif B2_crop_sub10.cub B2_crop_map.tif \
    --bundle-adjust-prefix run_ba_crop2_sub10/run --tile-size 64
mapproject run_crop2_sub10/run-DEM.tif C2_crop_sub10.cub C2_crop_map.tif \
    --bundle-adjust-prefix run_ba_crop2_sub10/run --tile-size 64
mapproject run_crop2_sub10/run-DEM.tif D2_crop_sub10.cub D2_crop_map.tif \
    --bundle-adjust-prefix run_ba_crop2_sub10/run --tile-size 64

win="-15284.931 149210.04 -14074.992 147943.38"
gdal_translate -projwin $win \
    run_full_crop2/run-trans_reference-DEM.tif run_full_crop2/run-crop-DEM.tif
gdal_translate -projwin $win \
    run_crop2_sub10/run-DEM.tif run_crop2_sub10/run-crop-DEM.tif

for f in A B C D; do
    gdal_translate -projwin $win "$f"2_crop_map.tif "$f"2_crop2_map.tif
done

sfs -i run_crop2_sub10/run-crop-DEM.tif A2_crop_sub10.cub C2_crop_sub10.cub   \
     -o sfs_crop2_AC/run --threads 1 --smoothness-weight 0.12                 \
    --max-iterations 100 --reflectance-type 0 --float-exposure                \
    --float-cameras --use-approx-camera-models                                \
    --bundle-adjust-prefix run_ba_crop2_sub10/run                             \
    --shadow-thresholds "0.00242759 0.00495365"

sfs -i run_crop2_sub10/run-crop-DEM.tif B2_crop_sub10.cub C2_crop_sub10.cub   \
     -o sfs_crop2_BC/run --threads 1 --smoothness-weight 0.12                 \
    --max-iterations 100 --reflectance-type 0 --float-exposure                \
    --float-cameras --use-approx-camera-models                                \
    --bundle-adjust-prefix run_ba_crop2_sub10/run                             \
    --shadow-thresholds "0.00495365 0.00218003"


sfs -i run_crop2_sub10/run-crop-DEM.tif A2_crop_sub10.cub B2_crop_sub10.cub C2_crop_sub10.cub  \
     -o sfs_crop2_ABC/run --threads 1 --smoothness-weight 0.12                 \
    --max-iterations 100 --reflectance-type 0 --float-exposure                \
    --float-cameras --use-approx-camera-models                                \
    --bundle-adjust-prefix run_ba_crop2_sub10/run                             \
    --shadow-thresholds "0.00242759 0.00495365 0.00218003"

for r in AC BC ABC; do 
    geodiff --absolute run_full_crop2/run-crop-DEM.tif sfs_crop2_"$r"/run-DEM-iter0.tif \
	-o sfs_crop2_"$r"/diff_start
    geodiff --absolute run_full_crop2/run-crop-DEM.tif sfs_crop2_"$r"/run-DEM-final.tif \
	-o sfs_crop2_"$r"/diff_final
    colormap --min 0 --max 2 sfs_crop2_"$r"/diff_start-diff.tif
    colormap --min 0 --max 2 sfs_crop2_"$r"/diff_final-diff.tif
    echo sg sfs_crop2_"$r"/run-DEM-iter0.tif sfs_crop2_"$r"/run-DEM-final.tif \
	run_full_crop2/run-crop-DEM.tif
    echo sg sfs_crop2_"$r"/diff_start-diff_CMAP.tif  sfs_crop2_"$r"/diff_final-diff_CMAP.tif
done

for r in AC BC ABC; do 
    gim sfs_crop2_"$r"/diff_start-diff.tif
    gim sfs_crop2_"$r"/diff_final-diff.tif
done

# BA only for high res, and only for the pair
bundle_adjust A2_crop.cub B2_crop.cub --min-matches 10 -o run_ba_crop3/run
stereo A2_crop.cub B2_crop.cub run_full_crop3/run --subpixel-mode 3 \
    --bundle-adjust-prefix run_ba_crop3/run

stereo A2_crop_sub10.cub B2_crop_sub10.cub run_crop3_sub10/run --subpixel-mode 3 

pc_align --max-displacement 200 run_full_crop3/run-PC.tif run_crop3_sub10/run-PC.tif \
    -o run_full_crop3/run --save-inv-transformed-reference-points

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    run_full_crop3/run-trans_reference.tif
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    run_crop3_sub10/run-PC.tif

win="-15284.931 149210.04 -14074.992 147943.38"
gdal_translate -projwin $win \
    run_full_crop3/run-trans_reference-DEM.tif run_full_crop3/run-crop-DEM.tif
gdal_translate -projwin $win \
    run_crop3_sub10/run-DEM.tif run_crop3_sub10/run-crop-DEM.tif

for f in A B C D; do
    gdal_translate -projwin $win "$f"2_crop_map.tif "$f"2_crop3_map.tif
done

sfs -i run_crop3_sub10/run-crop-DEM.tif A2_crop_sub10.cub C2_crop_sub10.cub   \
     -o sfs_crop3_AC/run --threads 1 --smoothness-weight 0.12                 \
    --max-iterations 100 --reflectance-type 0 --float-exposure                \
    --float-cameras --use-approx-camera-models                                \
    --shadow-thresholds "0.00242759 0.00495365"

sfs -i run_crop3_sub10/run-crop-DEM.tif B2_crop_sub10.cub C2_crop_sub10.cub   \
     -o sfs_crop3_BC/run --threads 1 --smoothness-weight 0.12                 \
    --max-iterations 100 --reflectance-type 0 --float-exposure                \
    --float-cameras --use-approx-camera-models                                \
    --shadow-thresholds "0.00495365 0.00218003"


sfs -i run_crop3_sub10/run-crop-DEM.tif A2_crop_sub10.cub B2_crop_sub10.cub C2_crop_sub10.cub  \
     -o sfs_crop3_ABC/run --threads 1 --smoothness-weight 0.12                 \
    --max-iterations 100 --reflectance-type 0 --float-exposure                \
    --float-cameras --use-approx-camera-models                                \
    --shadow-thresholds "0.00242759 0.00495365 0.00218003"

for r in AC BC ABC; do 
    geodiff --absolute run_full_crop3/run-crop-DEM.tif sfs_crop3_"$r"/run-DEM-iter0.tif \
	-o sfs_crop3_"$r"/diff_start
    geodiff --absolute run_full_crop3/run-crop-DEM.tif sfs_crop3_"$r"/run-DEM-final.tif \
	-o sfs_crop3_"$r"/diff_final
    colormap --min 0 --max 2 sfs_crop3_"$r"/diff_start-diff.tif
    colormap --min 0 --max 2 sfs_crop3_"$r"/diff_final-diff.tif
    echo sg sfs_crop3_"$r"/run-DEM-iter0.tif sfs_crop3_"$r"/run-DEM-final.tif \
	run_full_crop3/run-crop-DEM.tif
    echo sg sfs_crop3_"$r"/diff_start-diff_CMAP.tif  sfs_crop3_"$r"/diff_final-diff_CMAP.tif
done

for r in AC BC ABC; do 
    gim sfs_crop3_"$r"/diff_start-diff.tif
    gim sfs_crop3_"$r"/diff_final-diff.tif
done

win="-99.962546 -86.575931 -99.455058 -86.608519"

# Start
a=M173635550RE_crop;
b=M173642339LE_crop;
c=M114588166RE_crop;
d=M109869814LE_crop;

# # M173635550RE M173642339LE M114588166RE M109869814LE

# # M173635550RE.cal.cub M173642339LE.cal.cub M114594996LE.cal.cub M114588166RE.cal.cub

# crop.pl M173635550RE.cal.cub -521 13487 3718 8763
# crop.pl M173642339LE.cal.cub -198 14600 3254 8514
# crop.pl M114594996LE.cal.cub -366 14251 3288 9981
# crop.pl M114588166RE.cal.cub -435 36365 3485 8398
# crop.pl M109869814LE.cal.cub -366 14251 3288 9981

#v2

for f in M173635550RE M173642339LE M114594996LE M114588166RE M109869814LE; do
    lronacecho from = $f.cal.cub to = $f.cal.echo.cub
done

crop.pl M173635550RE.cal.echo.cub -1689 9043 5762 16625
crop.pl M173642339LE.cal.echo.cub -618 9708 3989 16773
crop.pl M114594996LE.cal.echo.cub -283 5000 3014 8938
crop.pl M114588166RE.cal.echo.cub -606 36090 3619 9084
crop.pl M109869814LE.cal.echo.cub -366 14251 3288 9981

a=M173635550RE.cal.echo_crop
b=M173642339LE.cal.echo_crop
c=M114594996LE.cal.echo_crop
d=M114588166RE.cal.echo_crop
e=M109869814LE.cal.echo_crop

# stereo ${a}.cub ${b}.cub tmp1/run --subpixel-mode 1
# stereo ${c}.cub ${d}.cub tmp2/run --subpixel-mode 1

#### Run2
i=7

a=M173635550RE.cal.echo_crop
b=M173642339LE.cal.echo_crop
c=M114594996LE.cal.echo_crop
d=M114588166RE.cal.echo_crop
e=M109869814LE.cal.echo_crop

win="-126370 4060 -125150 2860"
# West: -88.467323 East: -88.439429 South: -85.848414 North: -85.846715

tha= ; thb= ; thc=; thd=;

ba=run_ba$i
st=run_stereo$i
sfs=sfs$i

for f in $a $b $c $d $e; do 
    reduce from = "$f".cub to = "$f"_sub10.cub sscale = 10 lscale = 10
done

bundle_adjust ${c}.cub ${d}.cub --min-matches 10 -o ${ba}/run
bundle_adjust ${c}_sub10.cub ${d}_sub10.cub \
    --min-matches 1 -o ${ba}_sub10/run --ip-per-tile 100000

stereo ${c}.cub ${d}.cub ${st}/run --subpixel-mode 3 --bundle-adjust-prefix ${ba}/run

stereo ${c}_sub10.cub ${d}_sub10.cub ${st}_sub10/run --subpixel-mode 3           \
    --bundle-adjust-prefix ${ba}_sub10/run

pc_align --max-displacement 200 ${st}/run-PC.tif ${st}_sub10/run-PC.tif \
    -o ${st}/run --save-inv-transformed-reference-points

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-trans_reference.tif
gdal_translate -projwin $win ${st}/run-trans_reference-DEM.tif ${st}/run-crop-DEM.tif

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-PC.tif
gdal_translate -projwin $win ${st}/run-DEM.tif ${st}/run-crop0-DEM.tif

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}_sub10/run-PC.tif
gdal_translate -projwin $win ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop-DEM.tif

sfs -i ${st}_sub10/run-crop-DEM.tif ${b}_sub10.cub ${d}_sub10.cub     \
    -o ${sfs}_bd/run --threads 1 --smoothness-weight 0.12             \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                            \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${b}_sub10.cub ${d}_sub10.cub \
    ${e}_sub10.cub -o ${sfs}_bde/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${c}_sub10.cub \
    ${e}_sub10.cub -o ${sfs}_ace/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${c}_sub10.cub ${b}_sub10.cub     \
    -o ${sfs}_cb/run --threads 1 --smoothness-weight 0.12             \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                            \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${c}_sub10.cub ${a}_sub10.cub \
    ${e}_sub10.cub -o ${sfs}_cae/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${c}_sub10.cub ${d}_sub10.cub \
    ${e}_sub10.cub -o ${sfs}_cde/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"


# mappproject
for f in $a $b; do 
    mapproject ${st}_sub10/run-crop-DEM.tif ${f}_sub10.cub ${f}_map.tif \
	--bundle-adjust-prefix ${ba}_sub10/run --tile-size 64
done
for f in $c $d $e; do 
    mapproject ${st}_sub10/run-crop-DEM.tif ${f}_sub10.cub ${f}_map.tif \
	--tile-size 64
done

geodiff --absolute ${st}/run-crop0-DEM.tif ${st}_sub10/run-crop-DEM.tif -o  ${st}_sub10/ref0
gim ${st}_sub10/ref0-diff.tif

geodiff --absolute ${st}/run-crop-DEM.tif ${st}_sub10/run-crop-DEM.tif -o  ${st}_sub10/ref
gim ${st}_sub10/ref-diff.tif

for t in bd bde ace cb cae cde; do 
    geodiff --absolute ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-iter0.tif \
	-o sfs${i}_${t}/start
    geodiff --absolute ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-final.tif \
	-o sfs${i}_${t}/final
    colormap --min 0 --max 5 sfs${i}_${t}/start-diff.tif
    colormap --min 0 --max 5 sfs${i}_${t}/final-diff.tif
done
    
for t in bd bde ace cb cae cde; do 
    gim sfs${i}_${t}/start-diff.tif
    gim sfs${i}_${t}/final-diff.tif
done

t=cde
sg ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-iter0.tif sfs${i}_${t}/run-DEM-final.tif

i=3;
win="-126040 4100 -125230 3410" # run3

# West: -88.467323 East: -88.439429 South: -85.848414 North: -85.846715
# -88.467323 -88.439429 -85.848414 -85.846715

# Run4
i=4
win=""
tha=; thb=; thc=; thd=;
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i

for f in $a $b $c $d $e; do 
    reduce from = "$f".cub to = "$f"_sub10.cub sscale = 10 lscale = 10
done

bundle_adjust ${a}.cub ${b}.cub --min-matches 10 -o ${ba}/run
bundle_adjust ${a}_sub10.cub ${b}_sub10.cub \
    --min-matches 1 -o ${ba}_sub10/run --ip-per-tile 100000

stereo ${a}.cub ${b}.cub ${st}/run --subpixel-mode 3 --bundle-adjust-prefix ${ba}/run

stereo ${a}_sub10.cub ${b}_sub10.cub ${st}_sub10/run --subpixel-mode 3           \
    --bundle-adjust-prefix ${ba}_sub10/run

pc_align --max-displacement 200 ${st}/run-PC.tif ${st}_sub10/run-PC.tif \
    -o ${st}/run --save-inv-transformed-reference-points

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-trans_reference.tif
gdal_translate -projwin $win ${st}/run-trans_reference-DEM.tif ${st}/run-crop-DEM.tif

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}_sub10/run-PC.tif
gdal_translate -projwin $win ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop-DEM.tif

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${c}_sub10.cub     \
    -o ${sfs}_ac/run --threads 1 --smoothness-weight 0.12             \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                            \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${c}_sub10.cub \
    ${e}_sub10.cub -o ${sfs}_ace/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${c}_sub10.cub \
    ${d}_sub10.cub -o ${sfs}_acd/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"


# mappproject
for f in $a $b; do 
    mapproject ${st}_sub10/run-crop-DEM.tif ${f}_sub10.cub ${f}_map.tif \
	--bundle-adjust-prefix ${ba}_sub10/run --tile-size 64
done
for f in $c $d $e; do 
    mapproject ${st}_sub10/run-crop-DEM.tif ${f}_sub10.cub ${f}_map.tif \
	--tile-size 64
done

geodiff --absolute ${st}/run-crop0-DEM.tif ${st}_sub10/run-crop-DEM.tif -o  ${st}_sub10/ref0
gim ${st}_sub10/ref0-diff.tif

geodiff --absolute ${st}/run-crop-DEM.tif ${st}_sub10/run-crop-DEM.tif -o  ${st}_sub10/ref
gim ${st}_sub10/ref-diff.tif

for t in ac ace acd; do 
    geodiff --absolute ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-iter0.tif \
	-o sfs${i}_${t}/start
    geodiff --absolute ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-final.tif \
	-o sfs${i}_${t}/final
done
    
for t in ac ace acd; do 
    gim sfs${i}_${t}/start-diff.tif
    gim sfs${i}_${t}/final-diff.tif
done


# run9
i=9
win="-129300 3020 -128320 2070"
a=M173635550RE.cal.echo_crop
b=M173642339LE.cal.echo_crop
c=M114594996LE.cal.echo_crop
d=M114588166RE.cal.echo_crop
e=M109869814LE.cal.echo_crop
tha=; thb=; thc=; thd=;
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i
i0=6
ba0=run_ba$i0
st0=run_stereo$i0

cp -rfv ${ba0}_sub10 ${ba}_sub10
cp -rfv $ba0 $ba
cp -rfv $st0 $st
cp -rfv ${st0}_sub10 ${st}_sub10

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-trans_reference.tif
gdal_translate -projwin $win ${st}/run-trans_reference-DEM.tif ${st}/run-crop-DEM.tif

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}_sub10/run-PC.tif
gdal_translate -projwin $win ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop-DEM.tif

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${c}_sub10.cub \
    ${e}_sub10.cub -o ${sfs}_ace/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${b}_sub10.cub ${c}_sub10.cub \
    ${d}_sub10.cub ${e}_sub10.cub -o ${sfs}_abcde/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${b}_sub10.cub ${e}_sub10.cub \
    -o ${sfs}_abe/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

for t in abe ace abcde; do 
    geodiff --absolute ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-iter0.tif \
	-o sfs${i}_${t}/start
    geodiff --absolute ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-final.tif \
	-o sfs${i}_${t}/final
    colormap --min 0 --max 5 sfs${i}_${t}/start-diff.tif
    colormap --min 0 --max 5 sfs${i}_${t}/final-diff.tif
done
    
for t in abe ace abcde; do 
    gim sfs${i}_${t}/start-diff.tif
    gim sfs${i}_${t}/final-diff.tif
done

t=abcde
sg ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-iter0.tif sfs${i}_${t}/run-DEM-final.tif sfs${i}_${t}/start-diff_CMAP.tif sfs${i}_${t}/final-diff_CMAP.tif &

t=ace
sg ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-iter0.tif sfs${i}_${t}/run-DEM-final.tif sfs${i}_${t}/start-diff_CMAP.tif sfs${i}_${t}/final-diff_CMAP.tif &


# Start here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# Redoing run6. 
i=601 # This is a very good example!
tha= ; thb= ; thc=; thd=;
#win="-126180 3500 -125150 2480"
win="-126320 3680 -125040 2490"
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i
a=M173635550RE.cal.echo_crop
b=M173642339LE.cal.echo_crop
c=M114594996LE.cal.echo_crop
d=M114588166RE.cal.echo_crop
e=M109869814LE.cal.echo_crop # p1
z=M109863022RE.cal.echo_crop # p2
g=M140577849RE.cal.echo
h=M140584637LE.cal.echo
j=M1116910862LE.cal.echo
k=M1116917960RE.cal.echo

crop.pl M109863022RE.cal.echo.cub -161 15249 2835 9960

for f in $a $b $c $d $e $z $g $h $j $k; do 
    reduce from = "$f".cub to = "$f"_sub10.cub sscale = 10 lscale = 10
done

bundle_adjust ${e}_sub10.cub ${z}_sub10.cub \
    --min-matches 1 -o ${ba}_sub10/run --ip-per-tile 100000
stereo ${e}_sub10.cub ${z}_sub10.cub ${st}_sub10/run --subpixel-mode 3   #        \
#    --bundle-adjust-prefix ${ba}_sub10/run
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}_sub10/run-PC.tif
gdal_translate -projwin $win ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop-DEM.tif

#bundle_adjust ${a}.cub ${b}.cub --min-matches 10 -o ${ba}/run
stereo ${e}.cub ${z}.cub ${st}/run --subpixel-mode 3 # --bundle-adjust-prefix ${ba}/run
pc_align --max-displacement 200 ${st}/run-PC.tif ${st}_sub10/run-PC.tif \
    -o ${st}/run --save-inv-transformed-reference-points
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-trans_reference.tif
gdal_translate -projwin $win ${st}/run-trans_reference-DEM.tif ${st}/run-crop-DEM.tif

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-PC.tif
gdal_translate -projwin $win ${st}/run-DEM.tif ${st}/run-crop0-DEM.tif

#pc_align --max-displacement 200 ${st}/run-PC.tif ${st}_sub10/run-crop-DEM.tif \
#    -o ${st}/run --save-inv-transformed-reference-points

for f in $a $b $c $d $e $z $g $h $j $k; do 
    mapproject --mpp 10 ${st}_sub10/run-DEM.tif $f.cub $f.map.tif --tile-size 128  --t_srs '+proj=stere +lat_0=-90 +lat_ts=-90 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs ' #  --t_projwin 131770 -91160 132920 -92370
done

ls $a.map.tif $b.map.tif $c.map.tif $d.map.tif $e.map.tif $z.map.tif $g.map.tif $h.map.tif $j.map.tif $k.map.tif

# No ba!
for ref in 0 1; do 
sfs -i ${st}_sub10/run-crop-DEM.tif ${e}_sub10.cub ${z}_sub10.cub     \
    ${c}_sub10.cub ${d}_sub10.cub   \
    -o ${sfs}_ezcd_ref$ref/run --threads 1 --smoothness-weight 0.12             \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                       # \
    #--bundle-adjust-prefix ${ba}_sub10/run                            \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"
done

# No ba!
for ref in 0 1; do 
sfs -i ${st}_sub10/run-crop-DEM.tif ${e}_sub10.cub ${z}_sub10.cub     \
    ${j}_sub10.cub ${k}_sub10.cub   \
    -o ${sfs}_ezjk_ref$ref/run --threads 1 --smoothness-weight 0.12             \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                       # \
    #--bundle-adjust-prefix ${ba}_sub10/run                            \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"
done

# No ba!
for ref in 0 1; do 
sfs -i ${st}_sub10/run-crop-DEM.tif ${e}_sub10.cub ${z}_sub10.cub     \
    ${a}_sub10.cub ${b}_sub10.cub   \
    -o ${sfs}_ezab_ref$ref/run --threads 1 --smoothness-weight 0.12             \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                       # \
    #--bundle-adjust-prefix ${ba}_sub10/run                            \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"
done

# No ba!
for ref in 0 1; do 
sfs -i ${st}_sub10/run-crop-DEM.tif ${e}_sub10.cub ${z}_sub10.cub     \
    ${a}_sub10.cub ${c}_sub10.cub  ${j}_sub10.cub   \
    -o ${sfs}_ezacj_ref$ref/run --threads 1 --smoothness-weight 0.12             \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                       # \
    #--bundle-adjust-prefix ${ba}_sub10/run                            \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"
done

# No ba!
for ref in 0 1; do 
sfs -i ${st}_sub10/run-crop-DEM.tif ${e}_sub10.cub ${z}_sub10.cub     \
    ${b}_sub10.cub ${d}_sub10.cub  ${k}_sub10.cub   \
    -o ${sfs}_ezbdk_ref$ref/run --threads 1 --smoothness-weight 0.12             \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                       # \
    #--bundle-adjust-prefix ${ba}_sub10/run                            \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"
done

# No ba!
for ref in 0 1; do 
sfs -i ${st}_sub10/run-crop-DEM.tif ${e}_sub10.cub ${z}_sub10.cub     \
    ${j}_sub10.cub ${h}_sub10.cub  ${k}_sub10.cub   \
    -o ${sfs}_ezjhk_ref$ref/run --threads 1 --smoothness-weight 0.12             \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                       # \
    #--bundle-adjust-prefix ${ba}_sub10/run                            \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"
done

# No ba!
for ref in 0 1; do 
sfs -i ${st}_sub10/run-crop-DEM.tif ${e}_sub10.cub ${z}_sub10.cub     \
    ${j}_sub10.cub ${h}_sub10.cub  ${k}_sub10.cub   \
    -o ${sfs}_ezjhk_ref$ref/run --threads 1 --smoothness-weight 0.12             \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                       # \
    #--bundle-adjust-prefix ${ba}_sub10/run                            \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"
done

# No ba!
for ref in 0 1; do 
sfs -i ${st}_sub10/run-crop-DEM.tif ${e}_sub10.cub ${z}_sub10.cub     \
    ${g}_sub10.cub ${h}_sub10.cub ${j}_sub10.cub  ${k}_sub10.cub   \
    -o ${sfs}_ezghjk_ref$ref/run --threads 1 --smoothness-weight 0.12             \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                       # \
    #--bundle-adjust-prefix ${ba}_sub10/run                            \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"
done

for t in sfs${i}_*ref*; do
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-iter0.tif \
	-o $t/start
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-final.tif \
	-o $t/final
    colormap --min 0 --max 6 $t/start-diff.tif
    colormap --min 0 --max 6 $t/final-diff.tif
done
    
for t in sfs${i}_*ref*; do
    echo $t
    #echo ${t}/start-diff_CMAP.tif
    #gim ${t}/start-diff.tif
    #echo " "
    #echo ${t}/final-diff_CMAP.tif
    gim ${t}/final-diff.tif
    #echo $t/run-DEM-iter0.tif 
    #echo $t/run-DEM-final.tif 
done

for f in $a $b $c $d $e $z $g $h $j $k; do 
    mapproject --mpp 1 ${st}/run-crop-DEM.tif $f.cub $f.map.tif --tile-size 128  --t_srs '+proj=stere +lat_0=-90 +lat_ts=-90 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs ' #  --t_projwin 131770 -91160 132920 -92370
done

win4="-126048 3449 -125923 3319"
point2dem -r moon --tr 1 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-PC.tif -o  ${st}/run-1m
gdal_translate -projwin $win4 ${st}/run-1m-DEM.tif ${st}/run-crop5-DEM.tif

sm=0.12
sfs -i ${st}/run-crop5-DEM.tif ${a}.cub ${b}.cub ${c}.cub \
    -o ${sfs}_1m_abc_${sm}/run --threads 1 --smoothness-weight $sm  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models

sm0.06
sfs -i ${st}/run-crop5-DEM.tif ${a}.cub ${b}.cub ${c}.cub \
    -o ${sfs}_1m_abc_${sm}/run --threads 1 --smoothness-weight $sm  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models

sm=0.04
sfs -i ${st}/run-crop5-DEM.tif ${a}.cub ${b}.cub ${c}.cub \
    -o ${sfs}_1m_abc_${sm}/run --threads 1 --smoothness-weight $sm  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models

for t in ${sfs}_1m*; do
    geodiff --absolute ${st}/run-crop5-DEM.tif $t/run-DEM-iter0.tif \
	-o $t/start
    geodiff --absolute ${st}/run-crop5-DEM.tif $t/run-DEM-final.tif \
	-o $t/final
    colormap --min 0 --max 6 $t/start-diff.tif
    colormap --min 0 --max 6 $t/final-diff.tif
done

level=1
sm=0.12
sfs -i ${st}/run-crop5-DEM.tif ${a}.cub ${b}.cub ${c}.cub \
    -o ${sfs}_1m_abc_${sm}_level${level}/run --threads 1 --smoothness-weight $sm  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models --coarse-levels $level                     

level=1
sm0.06
sfs -i ${st}/run-crop5-DEM.tif ${a}.cub ${b}.cub ${c}.cub \
    -o ${sfs}_1m_abc_${sm}_level${level}/run --threads 1 --smoothness-weight $sm  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models --coarse-levels $level

level=1
sm=0.04
sfs -i ${st}/run-crop5-DEM.tif ${a}.cub ${b}.cub ${c}.cub \
    -o ${sfs}_1m_abc_${sm}_level${level}/run --threads 1 --smoothness-weight $sm  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models --coarse-levels $level



level=2
sm=0.12
sfs -i ${st}/run-crop5-DEM.tif ${a}.cub ${b}.cub ${c}.cub \
    -o ${sfs}_1m_abc_${sm}_level${level}/run --threads 1 --smoothness-weight $sm  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models --coarse-levels $level                     

level=2
sm0.06
sfs -i ${st}/run-crop5-DEM.tif ${a}.cub ${b}.cub ${c}.cub \
    -o ${sfs}_1m_abc_${sm}_level${level}/run --threads 1 --smoothness-weight $sm  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models --coarse-levels $level


for t in ${sfs}_1m*; do
    echo $t
    #echo ${t}/start-diff_CMAP.tif
    #gim ${t}/start-diff.tif
    #echo " "
    #echo ${t}/final-diff_CMAP.tif
    gim ${t}/final-diff.tif
    #echo $t/run-DEM-iter0.tif 
    echo $t/run-DEM-final.tif 
done

    

# Redoing run6
i=602
tha= ; thb= ; thc=; thd=;
win="-126370 4060 -125150 2860"
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i
a=M173635550RE.cal.echo_crop
b=M173642339LE.cal.echo_crop
c=M114594996LE.cal.echo_crop
d=M114588166RE.cal.echo_crop
e=M109869814LE.cal.echo_crop # p1
z=M109863022RE.cal.echo # p2

#for f in $a $b $c $d $e $z; do 
#    reduce from = "$f".cub to = "$f"_sub10.cub sscale = 10 lscale = 10
#done

bundle_adjust ${c}_sub10.cub ${d}_sub10.cub \
    --min-matches 1 -o ${ba}_sub10/run --ip-per-tile 100000
stereo ${c}_sub10.cub ${d}_sub10.cub ${st}_sub10/run --subpixel-mode 3           \
    --bundle-adjust-prefix ${ba}_sub10/run
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}_sub10/run-PC.tif
gdal_translate -projwin $win ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop-DEM.tif

# Redoing run6
i=603
tha= ; thb= ; thc=; thd=;
win="-126370 4060 -125150 2860"
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i
a=M173635550RE.cal.echo_crop
b=M173642339LE.cal.echo_crop
c=M114594996LE.cal.echo_crop
d=M114588166RE.cal.echo_crop
e=M109869814LE.cal.echo_crop # p1
z=M109863022RE.cal.echo # p2
g=M140577849RE.cal.echo
h=M140584637LE.cal.echo

for f in $g $h; do 
    reduce from = "$f".cub to = "$f"_sub10.cub sscale = 10 lscale = 10
done

bundle_adjust ${g}_sub10.cub ${h}_sub10.cub \
    --min-matches 1 -o ${ba}_sub10/run --ip-per-tile 100000
stereo ${g}_sub10.cub ${h}_sub10.cub ${st}_sub10/run --subpixel-mode 3           \
    --bundle-adjust-prefix ${ba}_sub10/run
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}_sub10/run-PC.tif
gdal_translate -projwin $win ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop-DEM.tif

# Redoing run6
i=604
tha= ; thb= ; thc=; thd=;
win="-126370 4060 -125150 2860"
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i
a=M173635550RE.cal.echo_crop
b=M173642339LE.cal.echo_crop
c=M114594996LE.cal.echo_crop
d=M114588166RE.cal.echo_crop
e=M109869814LE.cal.echo_crop # p1
z=M109863022RE.cal.echo # p2
g=M140577849RE.cal.echo
h=M140584637LE.cal.echo
j=M1116910862LE.cal.echo
k=M1116917960RE.cal.echo

for f in $j $k; do 
    reduce from = "$f".cub to = "$f"_sub10.cub sscale = 10 lscale = 10
done

bundle_adjust ${j}_sub10.cub ${k}_sub10.cub \
    --min-matches 1 -o ${ba}_sub10/run --ip-per-tile 100000
stereo ${j}_sub10.cub ${k}_sub10.cub ${st}_sub10/run --subpixel-mode 3           \
    --bundle-adjust-prefix ${ba}_sub10/run
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}_sub10/run-PC.tif
gdal_translate -projwin $win ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop-DEM.tif



#### Run6. Does not work so well! Need to revisit with more imagery!
# West: -88.467323 East: -88.439429 South: -85.848414 North: -85.846715
# -88.467323 -88.439429 -85.848414 -85.846715
cds
i=6 
tha= ; thb= ; thc=; thd=;
win="-126370 4060 -125150 2860"
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i
a=M173635550RE.cal.echo_crop
b=M173642339LE.cal.echo_crop
c=M114594996LE.cal.echo_crop
d=M114588166RE.cal.echo_crop
e=M109869814LE.cal.echo_crop # p1
z=M109863022RE.cal.echo_crop # p2

for f in $a $b $c $d $e $z; do 
    reduce from = "$z".cub to = "$z"_sub10.cub sscale = 10 lscale = 10
done

bundle_adjust ${a}.cub ${b}.cub --min-matches 10 -o ${ba}/run
bundle_adjust ${a}_sub10.cub ${b}_sub10.cub \
    --min-matches 1 -o ${ba}_sub10/run --ip-per-tile 100000

stereo ${a}.cub ${b}.cub ${st}/run --subpixel-mode 3 --bundle-adjust-prefix ${ba}/run

stereo ${a}_sub10.cub ${b}_sub10.cub ${st}_sub10/run --subpixel-mode 3           \
    --bundle-adjust-prefix ${ba}_sub10/run

pc_align --max-displacement 200 ${st}/run-PC.tif ${st}_sub10/run-PC.tif \
    -o ${st}/run --save-inv-transformed-reference-points

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-trans_reference.tif
gdal_translate -projwin $win ${st}/run-trans_reference-DEM.tif ${st}/run-crop-DEM.tif

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-PC.tif
gdal_translate -projwin $win ${st}/run-DEM.tif ${st}/run-crop0-DEM.tif

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}_sub10/run-PC.tif
gdal_translate -projwin $win ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop-DEM.tif

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${c}_sub10.cub     \
    -o ${sfs}_ac_ref${ref}/run --threads 1 --smoothness-weight 0.12             \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                            \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${c}_sub10.cub \
    ${e}_sub10.cub -o ${sfs}_ace_ref${ref}/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${c}_sub10.cub \
    ${d}_sub10.cub -o ${sfs}_acd_ref${ref}/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${b}_sub10.cub \
    ${c}_sub10.cub ${d}_sub10.cub -o ${sfs}_abcd_ref${ref}/run --threads 1 \
    --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${b}_sub10.cub \
    ${c}_sub10.cub ${d}_sub10.cub ${e}_sub10.cub \
    -o ${sfs}_abcde_ref${ref}/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"


# mappproject
for f in $a $b; do 
    mapproject ${st}_sub10/run-crop-DEM.tif ${f}_sub10.cub ${f}_map.tif \
	--bundle-adjust-prefix ${ba}_sub10/run --tile-size 64
done
for f in $c $d $e; do 
    mapproject ${st}_sub10/run-crop-DEM.tif ${f}_sub10.cub ${f}_map.tif \
	--tile-size 64
done

for t in sfs${i}_*ref0*; do
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-iter0.tif \
	-o $t/start
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-final.tif \
	-o $t/final
    colormap --min 0 --max 6 $t/start-diff.tif
    colormap --min 0 --max 6 $t/final-diff.tif
done
    
for t in sfs${i}_*ref0*; do
    echo $t
    gim ${t}/start-diff.tif
    #echo ${t}/start-diff_CMAP.tif
    gim ${t}/final-diff.tif
    #echo ${t}/final-diff_CMAP.tif
    #echo $t/run-DEM-iter0.tif 
    #echo $t/run-DEM-final.tif 
done


for t in sfs${i}_*ref1*; do
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-iter0.tif \
	-o $t/start
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-final.tif \
	-o $t/final
    colormap --min 0 --max 6 $t/start-diff.tif
    colormap --min 0 --max 6 $t/final-diff.tif
done
    
for t in sfs${i}_*ref1*; do
    echo $t
    gim ${t}/start-diff.tif
    #echo ${t}/start-diff_CMAP.tif
    gim ${t}/final-diff.tif
    #echo ${t}/final-diff_CMAP.tif
    #echo $t/run-DEM-iter0.tif 
    #echo $t/run-DEM-final.tif 
done

t=acd
sg ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-iter0.tif sfs${i}_${t}/run-DEM-final.tif sfs${i}_${t}/start-diff_CMAP.tif sfs${i}_${t}/final-diff_CMAP.tif &

# run10
i=10
win="-136540 380 -135520 -750"
a=M173635550RE.cal.echo_crop
b=M173642339LE.cal.echo_crop
c=M114594996LE.cal.echo_crop
d=M114588166RE.cal.echo_crop
e=M109869814LE.cal.echo_crop
a0=M173635550RE.cal.echo
b0=M173642339LE.cal.echo
f=M109869814RE.cal.echo
g=M112239266LE.cal.echo
h=M112232498RE.cal.echo
j=M114601778LE.cal.echo

tha=; thb=; thc=; thd=;
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i
i0=6
ba0=run_ba$i0
st0=run_stereo$i0

for t in $f $g $h $j; do 
    reduce from = "$t".cub to = "$t"_sub10.cub sscale = 10 lscale = 10
done

rm -rfv ${ba}_sub10 ${st}_sub10
cp -rfv ${ba0}_sub10 ${ba}_sub10
cp -rfv $ba0 $ba
cp -rfv $st0 $st
cp -rfv ${st0}_sub10 ${st}_sub10

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-trans_reference.tif
gdal_translate -projwin $win ${st}/run-trans_reference-DEM.tif ${st}/run-crop-DEM.tif

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}_sub10/run-PC.tif
gdal_translate -projwin $win ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop-DEM.tif

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${b}_sub10.cub ${f}_sub10.cub \
    -o ${sfs}_abf/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${b}_sub10.cub ${g}_sub10.cub \
    -o ${sfs}_abg/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"


sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${f}_sub10.cub ${g}_sub10.cub \
    -o ${sfs}_afg/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${b}_sub10.cub ${f}_sub10.cub ${g}_sub10.cub \
    -o ${sfs}_abfg/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${b}_sub10.cub ${f}_sub10.cub ${h}_sub10.cub \
    -o ${sfs}_abfh/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${b}_sub10.cub ${f}_sub10.cub ${j}_sub10.cub \
    -o ${sfs}_abfj/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${f}_sub10.cub ${h}_sub10.cub ${j}_sub10.cub \
    -o ${sfs}_afhj/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type 0 --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"


for t in abf abg afg abfg abfh abfj afhj; do
    i=10
    ba=run_ba$i
    st=run_stereo$i
    sfs=sfs$i
    i0=6
    ba0=run_ba$i0
    st0=run_stereo$i0
    geodiff --absolute ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-iter0.tif \
	-o sfs${i}_${t}/start
    geodiff --absolute ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-final.tif \
	-o sfs${i}_${t}/final
    colormap --min 0 --max 5 sfs${i}_${t}/start-diff.tif
    colormap --min 0 --max 5 sfs${i}_${t}/final-diff.tif
done
    
for t in abf abg afg abfg abfh abfj afhj; do
    i=10
    ba=run_ba$i
    st=run_stereo$i
    sfs=sfs$i
    i0=6
    ba0=run_ba$i0
    st0=run_stereo$i0
    echo $t
    gim sfs${i}_${t}/start-diff.tif
    gim sfs${i}_${t}/final-diff.tif
done

t=abfg; sg ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-iter0.tif sfs${i}_${t}/run-DEM-final.tif sfs${i}_${t}/start-diff_CMAP.tif sfs${i}_${t}/final-diff_CMAP.tif &
t=abfi; sg ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-iter0.tif sfs${i}_${t}/run-DEM-final.tif sfs${i}_${t}/start-diff_CMAP.tif sfs${i}_${t}/final-diff_CMAP.tif &

# run11
i=11
#win="125230 -90620 126570 -91980" # small win
win="122110 -89910 124530 -92500" # big win
#win="122770 -90350 124300 -91830" # small win
win2="122460 -90300 123820 -91510"
win3="126890 -90790 128440 -92020"
j=M1135931915RE.cal.echo_crop
k=M1135938984LE.cal.echo_crop
l=M143915606LE.cal.echo
m=M113142611LE.cal.echo
n=M123735900LE.cal.echo
o=M126098322LE.cal.echo

tha=; thb=; thc=; thd=;
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i

crop.pl M1135931915RE.cal.echo.cub -840 -709 4212 14039
crop.pl M1135938984LE.cal.echo.cub -1135 39855 4507 13374

for f in $j $k $l $m $n $o; do 
    reduce from = "$f".cub to = "$f"_sub10.cub sscale = 10 lscale = 10
done

ls $j.map.tif $k.map.tif $l.map.tif $m.map.tif $n.map.tif $o.map.tif

bundle_adjust ${j}.cub ${k}.cub --min-matches 10 -o ${ba}/run
stereo ${j}.cub ${k}.cub ${st}/run --subpixel-mode 3 --bundle-adjust-prefix ${ba}/run

bundle_adjust ${j}_sub10.cub ${k}_sub10.cub \
    --min-matches 1 -o ${ba}_sub10/run --ip-per-tile 100000
stereo ${j}_sub10.cub ${k}_sub10.cub ${st}_sub10/run --subpixel-mode 3           \
    --bundle-adjust-prefix ${ba}_sub10/run
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}_sub10/run-PC.tif

pc_align --max-displacement 200 ${st}/run-PC.tif ${st}_sub10/run-PC.tif \
    -o ${st}/run --save-inv-transformed-reference-points

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-trans_reference.tif
gdal_translate -projwin $win ${st}/run-trans_reference-DEM.tif ${st}/run-crop-DEM.tif

gdal_translate -projwin $win ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop-DEM.tif

for f in  $j $k $l $m $n $o; do 
    mapproject --mpp 10  Lunar_LRO_LOLA_Global_LDEM_118m_Mar2014.tif $f.cub $f.map.tif --tile-size 128  --t_srs '+proj=stere +lat_0=-90 +lat_ts=-90 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs '
done

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${j}_sub10.cub ${k}_sub10.cub \
    ${l}_sub10.cub  \
    -o ${sfs}_jkl_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${j}_sub10.cub ${k}_sub10.cub \
    ${l}_sub10.cub ${m}_sub10.cub \
    -o ${sfs}_jklm_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${j}_sub10.cub ${k}_sub10.cub ${n}_sub10.cub ${o}_sub10.cub \
    -o ${sfs}_jkno_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${j}_sub10.cub ${l}_sub10.cub ${m}_sub10.cub \
    -o ${sfs}_jlm_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${j}_sub10.cub ${k}_sub10.cub ${l}_sub10.cub ${n}_sub10.cub \
    -o ${sfs}_jkln_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${j}_sub10.cub ${k}_sub10.cub ${m}_sub10.cub ${o}_sub10.cub \
    -o ${sfs}_jkmo_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"


ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${j}_sub10.cub ${l}_sub10.cub ${m}_sub10.cub ${n}_sub10.cub \
    -o ${sfs}_jlmn_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"


for t in sfs${i}_*ref0*; do
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-iter0.tif \
	-o $t/start
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-final.tif \
	-o $t/final
    colormap --min 0 --max 6 $t/start-diff.tif
    colormap --min 0 --max 6 $t/final-diff.tif
done
    
for t in sfs${i}_*ref0*; do
    echo $t
    gim ${t}/start-diff.tif
    #echo ${t}/start-diff_CMAP.tif
    gim ${t}/final-diff.tif
    #echo ${t}/final-diff_CMAP.tif
    #echo $t/run-DEM-iter0.tif 
    #echo $t/run-DEM-final.tif 
done


for t in sfs${i}_*ref1*; do
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-iter0.tif \
	-o $t/start
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-final.tif \
	-o $t/final
    colormap --min 0 --max 6 $t/start-diff.tif
    colormap --min 0 --max 6 $t/final-diff.tif
done
    
for t in sfs${i}_*ref*; do
    echo $t
    gim ${t}/start-diff.tif
    #echo ${t}/start-diff_CMAP.tif
    gim ${t}/final-diff.tif
    #echo ${t}/final-diff_CMAP.tif
    #echo $t/run-DEM-iter0.tif 
    #echo $t/run-DEM-final.tif 
done


for t in sfs11_jkl2_ref0 sfs11_jkl2_ref1; do
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-iter0.tif \
	-o $t/start
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-final.tif \
	-o $t/final
    colormap --min 0 --max 6 $t/start-diff.tif
    colormap --min 0 --max 6 $t/final-diff.tif
done
    
for t in sfs11_jkl2_ref0 sfs11_jkl2_ref1; do
    echo $t
    gim ${t}/start-diff.tif
    #echo ${t}/start-diff_CMAP.tif
    gim ${t}/final-diff.tif
    #echo ${t}/final-diff_CMAP.tif
    #echo $t/run-DEM-iter0.tif 
    #echo $t/run-DEM-final.tif 
done

gdal_translate -projwin $win3 ${st}/run-trans_reference-DEM.tif ${st}/run-crop3-DEM.tif
gdal_translate -projwin $win3 ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop3-DEM.tif

ref=0
sfs -i ${st}_sub10/run-crop3-DEM.tif ${j}_sub10.cub ${k}_sub10.cub \
    ${l}_sub10.cub ${m}_sub10.cub \
    -o ${sfs}_jklm3_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=0
sfs -i ${st}_sub10/run-crop3-DEM.tif ${j}_sub10.cub ${k}_sub10.cub \
    ${n}_sub10.cub ${o}_sub10.cub \
    -o ${sfs}_jkno3_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=0
sfs -i ${st}_sub10/run-crop3-DEM.tif ${j}_sub10.cub ${k}_sub10.cub \
    ${l}_sub10.cub ${n}_sub10.cub \
    -o ${sfs}_jkln3_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=0
sfs -i ${st}_sub10/run-crop3-DEM.tif ${j}_sub10.cub ${k}_sub10.cub \
    ${m}_sub10.cub ${o}_sub10.cub \
    -o ${sfs}_jkmo3_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
    --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"


for t in sfs11_jkno3_ref0 sfs11_jkln3_ref0 sfs11_jkmo3_ref0 sfs11_jklm3_ref0; do
    geodiff --absolute ${st}/run-crop3-DEM.tif $t/run-DEM-iter0.tif \
	-o $t/start
    geodiff --absolute ${st}/run-crop3-DEM.tif $t/run-DEM-final.tif \
	-o $t/final
    colormap --min 0 --max 6 $t/start-diff.tif
    colormap --min 0 --max 6 $t/final-diff.tif
done
    
for t in sfs11_jkno3_ref0 sfs11_jkln3_ref0 sfs11_jkmo3_ref0 sfs11_jklm3_ref0; do
    echo $t
    gim ${t}/start-diff.tif
    #echo ${t}/start-diff_CMAP.tif
    gim ${t}/final-diff.tif
    #echo ${t}/final-diff_CMAP.tif
    #echo $t/run-DEM-iter0.tif 
    echo $t/run-DEM-final.tif 
done



t=jkln; sg ${st}/run-crop-DEM.tif sfs${i}_${t}/run-DEM-iter0.tif sfs${i}_${t}/run-DEM-final.tif sfs${i}_${t}/start-diff_CMAP.tif sfs${i}_${t}/final-diff_CMAP.tif &

# run12. No BA! But with pc_align!
i=12
win="-227850 -132960 -226780 -133940"

tha=; thb=; thc=; thd=;
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i

p=M151255967LE.cal.echo_crop
q=M151262745RE.cal.echo_crop
p0=M151255967LE.cal.echo
q0=M151262745RE.cal.echo
r=M1152519193RE.cal.echo
s=M1147814041RE.cal.echo
t=M1119567517LE.cal.echo
u=M1117209299LE.cal.echo
v=M1114858098RE.cal.echo
w=M155972130RE.cal.echo
x=M153617063RE.cal.echo

crop.pl M151255967LE.cal.echo.cub -1323 -816 6293 18960
crop.pl M151262745RE.cal.echo.cub -1044 8903 5576 17607

for f in $p $q $r $s $t $u $v $w $x; do 
    reduce from = "$f".cub to = "$f"_sub10.cub sscale = 10 lscale = 10
done

for f in $p $q $r $s; do 
    mapproject Lunar_LRO_LOLA_Global_LDEM_118m_Mar2014.tif $f.cub $f.map.tif --tile-size 128  --t_srs '+proj=stere +lat_0=-90 +lat_ts=-90 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs ' --tr 10
done

#bundle_adjust ${p}.cub ${q}.cub --min-matches 10 -o ${ba}/run
stereo ${p}.cub ${q}.cub ${st}/run --subpixel-mode 3 # --bundle-adjust-prefix ${ba}/run
pc_align --max-displacement 200 ${st}/run-PC.tif ${st}_sub10/run-PC.tif \
    -o ${st}/run --save-inv-transformed-reference-points

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-PC.tif
point2dem -r moon --tr 1 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-PC.tif -o ${st}/run-1m

point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-trans_reference.tif
gdal_translate -projwin $win ${st}/run-DEM.tif ${st}/run-crop0-DEM.tif
gdal_translate -projwin $win ${st}/run-trans_reference-DEM.tif ${st}/run-crop-DEM.tif

gdal_translate -projwin $win ${st}/run-1m-DEM.tif ${st}/run-1m-crop0-DEM.tif     
gdal_translate -projwin -227728 -133464 -227396 -133803 ${st}/run-1m-DEM.tif ${st}/run-1m-crop1-DEM.tif
gdal_translate -projwin -227107 -133257 -226786 -133587 ${st}/run-1m-DEM.tif ${st}/run-1m-crop2-DEM.tif
gdt run_stereo12/run-1m-DEM.tif -projwin -120.25683 -81.284636 -120.1271 -81.304047 run_stereo12/run-1m-crop-DEM.tif

sm=0.10
sm=0.06
level=4
crop=1
hp sfs -i run_stereo12/run-1m-crop-DEM.tif ${p}.cub ${q}.cub ${r}.cub ${s}.cub           \
    -o ${sfs}_pqrs_level${level}_sm${sm}/run --threads 4 --smoothness-weight $sm  \
    --max-iterations 100 --reflectance-type 0 --float-exposure                         \
    --float-cameras --use-approx-camera-models --coarse-levels $level --crop-input-images   \
    > outputcrop${crop}_level${level}_sm${sm}.txt 2>&1&


# Note that image s does not work!
sfs12_pqrs_level5_sm0.06/run-DEM-final-level0.tif
gdt -projwin -228810 -132888 -226866 -134346 run_stereo12/run-1m-DEM.tif run_stereo12/run-1m-crop4-DEM.tif
gdt -projwin -228818 -132895 -227445 -133873 run_stereo12/run-1m-DEM.tif run_stereo12/run-1m-crop5-DEM.tif
tile.pl run_stereo12/run-1m-crop5-DEM.tif 200 run_stereo12 30

#bundle_adjust ${p}_sub10.cub ${q}_sub10.cub \
#    --min-matches 1 -o ${ba}_sub10/run --ip-per-tile 100000
stereo ${p}_sub10.cub ${q}_sub10.cub ${st}_sub10/run --subpixel-mode 3        #   \
#    --bundle-adjust-prefix ${ba}_sub10/run
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}_sub10/run-PC.tif
gdal_translate -projwin $win ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop-DEM.tif

# NO BA!
ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${p}_sub10.cub ${q}_sub10.cub \
    ${r}_sub10.cub ${s}_sub10.cub \
    -o ${sfs}_pqrs_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        # \
    # --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"


ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${p}_sub10.cub ${q}_sub10.cub \
    ${t}_sub10.cub ${u}_sub10.cub \
    -o ${sfs}_pqtu_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        # \
    # --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${p}_sub10.cub ${q}_sub10.cub \
    ${v}_sub10.cub ${w}_sub10.cub \
    -o ${sfs}_pqvw_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        # \
    # --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${p}_sub10.cub ${q}_sub10.cub \
    ${w}_sub10.cub ${x}_sub10.cub \
    -o ${sfs}_pqwx_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        # \
    # --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${p}_sub10.cub ${q}_sub10.cub \
    ${s}_sub10.cub ${t}_sub10.cub \
    -o ${sfs}_pqst_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        # \
    # --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"


ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${p}_sub10.cub ${t}_sub10.cub \
    ${w}_sub10.cub ${x}_sub10.cub \
    -o ${sfs}_ptwx_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        # \
    # --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${p}_sub10.cub ${t}_sub10.cub \
    ${u}_sub10.cub ${v}_sub10.cub ${x}_sub10.cub \
    -o ${sfs}_ptuvx_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        # \
    # --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${p}_sub10.cub ${q}_sub10.cub \
    ${t}_sub10.cub ${u}_sub10.cub ${v}_sub10.cub \
    -o ${sfs}_pqtuv_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        # \
    # --bundle-adjust-prefix ${ba}_sub10/run                           \
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"


for t in sfs${i}_*ref0*; do
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-iter0.tif \
	-o $t/start
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-final.tif \
	-o $t/final
    colormap --min 0 --max 6 $t/start-diff.tif
    colormap --min 0 --max 6 $t/final-diff.tif
done
    
for t in sfs${i}_*ref0*; do
    echo $t
    gim ${t}/start-diff.tif
    #echo ${t}/start-diff_CMAP.tif
    gim ${t}/final-diff.tif
    #echo ${t}/final-diff_CMAP.tif
    #echo $t/run-DEM-iter0.tif 
    #echo $t/run-DEM-final.tif 
done


for t in sfs${i}_*ref1*; do
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-iter0.tif \
	-o $t/start
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-final.tif \
	-o $t/final
    colormap --min 0 --max 6 $t/start-diff.tif
    colormap --min 0 --max 6 $t/final-diff.tif
done
    
for t in sfs${i}_*ref*; do
    echo $t
    gim ${t}/start-diff.tif
    #echo ${t}/start-diff_CMAP.tif
    gim ${t}/final-diff.tif
    #echo ${t}/final-diff_CMAP.tif
    #echo $t/run-DEM-iter0.tif 
    #echo $t/run-DEM-final.tif 
done

# Same as the first testcase!
i=13
a0=M139939938LE.cal.echo
b0=M139946735RE.cal.echo
c0=M173004270LE.cal.echo
d0=M122270273LE.cal.echo
a=${a0}_crop
b=${b0}_crop
c=${c0}_crop
d=${d0}_crop
ba=run_ba$i
st=run_stereo$i
sfs=sfs$i
win="-15540.7 151403 -14554.5 150473"

crop from = ${a0}.cub to = ${a}.cub sample = 1 line = 6644 nsamples = 2192 nlines = 4982
crop from = ${b0}.cub to = ${b}.cub sample = 1 line = 7013 nsamples = 2531 nlines = 7337
crop from = ${c0}.cub to = ${c}.cub sample = 1 line = 1 nsamples = 2531 nlines = 8305
crop from = ${d0}.cub to = ${d}.cub sample = 1 line = 1 nsamples = 2531 nlines = 2740

for f in $a $b $c $d; do 
    reduce from = "$f".cub to = "$f"_sub10.cub sscale = 10 lscale = 10
done
for f in $c0 $d0; do 
    reduce from = "$f".cub to = "$f"_sub10.cub sscale = 10 lscale = 10
done

bundle_adjust ${a}_sub10.cub ${b}_sub10.cub \
    --min-matches 1 -o ${ba}_sub10/run --ip-per-tile 100000
stereo ${a}_sub10.cub ${b}_sub10.cub ${st}_sub10/run --subpixel-mode 3           \
    --bundle-adjust-prefix ${ba}_sub10/run
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}_sub10/run-PC.tif
gdal_translate -projwin $win ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop-DEM.tif

bundle_adjust ${a}.cub ${b}.cub --min-matches 10 -o ${ba}/run
stereo ${a}.cub ${b}.cub ${st}/run --subpixel-mode 3 --bundle-adjust-prefix ${ba}/run
pc_align --max-displacement 200 ${st}/run-PC.tif ${st}_sub10/run-PC.tif \
    -o ${st}/run --save-inv-transformed-reference-points
point2dem -r moon --tr 10 --stereographic --proj-lon 0 --proj-lat -90 \
    ${st}/run-trans_reference.tif
gdal_translate -projwin $win ${st}/run-trans_reference-DEM.tif ${st}/run-crop-DEM.tif

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${c}_sub10.cub \
    ${d}_sub10.cub  \
    -o ${sfs}_acd_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
     --bundle-adjust-prefix ${ba}_sub10/run                           #\
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${b}_sub10.cub \
    ${c}_sub10.cub  ${d}_sub10.cub \
    -o ${sfs}_abcd_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
     --bundle-adjust-prefix ${ba}_sub10/run                           #\
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=1
sfs -i ${st}_sub10/run-crop-DEM.tif ${a}_sub10.cub ${b}_sub10.cub \
    ${d}_sub10.cub \
    -o ${sfs}_abd_ref$ref/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
     --bundle-adjust-prefix ${ba}_sub10/run                           #\
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

ref=0
sfs -i ${st}_sub10/run-crop2-DEM.tif ${a}_sub10.cub ${b}_sub10.cub \
    ${c}_sub10.cub  ${d}_sub10.cub \
    -o ${sfs}_abcd2_ref${ref}/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
     --bundle-adjust-prefix ${ba}_sub10/run #  --init-dem-height -1052.522 #\
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

sfs -i ${st}_sub10/run-crop2-DEM.tif ${a}_sub10.cub ${b}_sub10.cub \
    ${c}_sub10.cub  ${d}_sub10.cub \
    -o ${sfs}_abcd2_ref${ref}_flat/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
     --bundle-adjust-prefix ${ba}_sub10/run  --init-dem-height -1052.522 #\
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

for f in  $a $b $c $d; do 
    mapproject --mpp 10 Lunar_LRO_LOLA_Global_LDEM_118m_Mar2014.tif $f.cub $f.map4.tif --tile-size 128  --t_srs '+proj=stere +lat_0=-90 +lat_ts=-90 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs ' --bundle-adjust-prefix  ${ba}/run
done


for t in sfs${i}_*; do
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-iter0.tif \
	-o $t/start
    geodiff --absolute ${st}/run-crop-DEM.tif $t/run-DEM-final.tif \
	-o $t/final
    colormap --min 0 --max 45 $t/start-diff.tif
    colormap --min 0 --max 45 $t/final-diff.tif
done
    
for t in sfs${i}_abcd2_*; do
    echo $t
    #echo ${t}/start-diff.tif
    echo ${t}/start-diff_CMAP.tif
    #echo $t/run-DEM-iter0.tif 
    gim ${t}/start-diff.tif
    echo ${t}/final-diff_CMAP.tif
    #echo $t/run-DEM-final.tif 
    gim ${t}/final-diff.tif
done

win="-15790 151820 -14010 150040"
# UDPATE WIN

gdal_translate -projwin $win4 ${st}/run-trans_reference-DEM.tif ${st}/run-crop4-DEM.tif
gdal_translate -projwin $win4 ${st}_sub10/run-DEM.tif ${st}_sub10/run-crop4-DEM.tif


ref=0
sfs -i ${st}_sub10/run-crop4-DEM.tif ${a}_sub10.cub ${b}_sub10.cub \
    ${c0}_sub10.cub  ${d0}_sub10.cub \
    -o ${sfs}_abcd4_ref${ref}/run --threads 1 --smoothness-weight 0.12  \
    --max-iterations 100 --reflectance-type $ref --float-exposure        \
    --float-cameras --use-approx-camera-models                        \
     --bundle-adjust-prefix ${ba}_sub10/run #  --init-dem-height -1052.522 #\
    #--shadow-thresholds "0.00162484 0.0012166 0.000781663"

for f in $c0 $d0; do 
    mapproject --mpp 10 Lunar_LRO_LOLA_Global_LDEM_118m_Mar2014.tif $f.cub $f.map2.tif --tile-size 128  --t_srs '+proj=stere +lat_0=-90 +lat_ts=-90 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs '
done


i=6
sg ${st}/run-crop-DEM.tif sfs${i}_abcd_ref0/run-DEM-iter0.tif sfs${i}_abcd_ref0/run-DEM-final.tif sfs${i}_abcd_ref1/run-DEM-final.tif &
sg sfs${i}_abcd_ref0/start-diff_CMAP.tif sfs${i}_abcd_ref0/final-diff_CMAP.tif sfs${i}_abcd_ref1/final-diff_CMAP.tif&


i=11
sg sfs${i}_jlmn_ref0/run-DEM-iter0.tif sfs${i}_jlmn_ref0/run-DEM-final.tif sfs${i}_jlmn_ref1/run-DEM-iter0.tif sfs${i}_jlmn_ref1/run-DEM-final.tif &
sg sfs${i}_jlmn_ref0/final-diff_CMAP.tif sfs${i}_jlmn_ref1/final-diff_CMAP.tif&

i=12
sg sfs${i}_pqst_ref0/run-DEM-iter0.tif sfs${i}_pqst_ref0/run-DEM-final.tif sfs${i}_pqst_ref1/run-DEM-iter0.tif sfs${i}_pqst_ref1/run-DEM-final.tif &
sg sfs${i}_pqst_ref0/final-diff_CMAP.tif sfs${i}_pqst_ref1/final-diff_CMAP.tif&

i=13
sg sfs${i}_acd_ref0/run-DEM-iter0.tif sfs${i}_acd_ref0/run-DEM-final.tif sfs${i}_acd_ref1/run-DEM-iter0.tif sfs${i}_acd_ref1/run-DEM-final.tif &
sg sfs${i}_acd_ref0/final-diff_CMAP.tif sfs${i}_acd_ref1/final-diff_CMAP.tif&
