bundle_adjust A.cub B.cub -o run_ba_AB/run

reduce from = A.cub to = A_sub10.cub sscale = 10 lscale = 10

bundle_adjust A_sub10.cub B_sub10.cub -o run_ba_sub10_AB/run

parallel_stereo A.cub B.cub run_AB_full_ba/run --bundle-adjust-prefix run_ba_AB/run --left-image-crop-win 41 30572 5086 4068 --right-image-crop-win 8 28920 5064 4753 --subpixel-mode 3

stereo A_sub10.cub B_sub10.cub run_AB_sub10_ba/run --bundle-adjust-prefix run_ba_sub10_AB/run --left-image-crop-win 4 3057 508 406 --right-image-crop-win 0 2892 506 475 --subpixel-mode 3

pc_align --max-displacement 50  run_AB_full_ba/run-PC.tif run_AB_sub10_ba/run-PC.tif --save-inv-transformed-reference-points -o run_AB_full_ba/run

pd --tr .0003297788621680  run_AB_sub10_ba/run-PC.tif

pd --tr .0003297788621680   run_AB_full_ba/run-trans_reference.tif

gdt -projwin 3.59129 26.2052 3.62559 26.167 run_AB_sub10_ba/run-DEM.tif run_AB_sub10_ba/run-crop-DEM.tif 

gdt -projwin 3.59129 26.2052 3.62559 26.167 run_AB_full_ba/run-trans_reference-DEM.tif  run_AB_full_ba/run-crop-DEM.tif 

diff.sh  run_AB_full_ba/run-crop-DEM.tif run_AB_sub8_ba/run-crop-DEM.tif

diff.sh run_AB_full_ba/run-crop-DEM.tif run_AB_sub10_ba/run-crop-DEM.tif 10

/usr/bin/time sfs -i run_AB_sub10_ba/run-crop-DEM.tif A_sub10.cub B_sub10.cub D_sub10.cub -o sfs_ABD_wt0.04_v2_sub10_level4_yesalb/run --threads 1 --smoothness-weight 0.04 --max-iterations 20 --bundle-adjust-prefix run_ba_sub10_AB/run --float-exposure --float-cameras --use-approx-camera-models --coarse-levels 4 --max-coarse-iterations 20 --float-albedo


export l=4; export e0.06; is; time_run.sh sfs -i run_AB_sub10_ba/run-crop-DEM.tif A_sub10.cub B_sub10.cub D_sub10.cub -o sfs_ABD_wt${e}_v2_sub10_level${l}_yesalb/run --threads 1 --smoothness-weight $e --max-iterations 20 --bundle-adjust-prefix run_ba_sub10_AB/run --float-exposure --float-cameras --use-approx-camera-models --coarse-levels ${l} --max-coarse-iterations 20 --float-albedo

export e=0.04; is; sfs -i run_AB_sub10_ba/run-crop-DEM.tif A_sub10.cub B_sub10.cub D_sub10.cub -o sfs_ABD_wt${e}_v1_sub10_level0_noalb/run --threads 1 --smoothness-weight $e --max-iterations 50 --bundle-adjust-prefix run_ba_sub10_AB/run --float-exposure --float-cameras --use-approx-camera-models --coarse-levels 0 --max-coarse-iterations 50     

export e=0.04; is; sfs -i run_AB_sub10_ba/run-crop-DEM.tif A_sub10.cub B_sub10.cub D_sub10.cub -o sfs_ABD_wt${e}_v1_sub10_level0_yesalb/run --threads 1 --smoothness-weight $e --max-iterations 50 --bundle-adjust-prefix run_ba_sub10_AB/run --float-exposure --float-cameras --use-approx-camera-models --coarse-levels 0 --max-coarse-iterations 50 --float-albedo


