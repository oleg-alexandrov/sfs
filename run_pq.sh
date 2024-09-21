parallel_stereo P.cub Q.cub --left-image-crop-win -760 14530 3980 13770 --right-image-crop-win -1130 41260 4730 11030 run_PQ_full_ba/run --bundle-adjust-prefix run_ba_PQR/run

pd --tr 1 --stereographic --proj-lon 0 --proj-lat -90 -o run_PQ_full_ba/run-1m run_PQ_full_ba/run-PC.tif

gdt -projwin -33540 143020 -32270 141750 run_PQ_full_ba/run-10m-DEM.tif run_PQ_full_ba/run-10m-crop5-DEM.tif


l=0; export e=0.1; is; sfs -i run_PQ_full_ba/run-1m-crop1-DEM.tif P.cub Q.cub R.cub -o sfs_PQR_${e}v25_1mpp_yesba_level$l/run --threads 1 --smoothness-weight $e --max-iterations 100 --coarse-levels $l --max-coarse-iterations 20 --bundle-adjust-prefix run_ba_PQR/run --reflectance-type 0

