export h=3937; export e=0.25;

crop.pl E.cub 336 48855 2196 2788
crop.pl E.cub 52 148 2423 2209
crop.pl F.cub 342 48849 2190 2530
crop.pl G.cub 477 27 2019 2239

stereo F_crop.cub E_crop.cub G_crop.cub run_FEG_yesba/run --bundle-adjust-prefix run_ba_EFG/run --ip-per-tile 4000

pd --t_srs '+proj=stere +lat_ts=-80 +lat_0=-80 +lon_0=-85 +x_0=0 +y_0=0 +a=1737400 +b=1737400 +units=m +no_defs ' --tr 10 run_FEG_yesba/run-PC.tif


sfs -i run_FEG_yesba/run-crop1-sub10-DEM.tif E_crop_sub10.cub F_crop_sub10.cub G_crop_sub10.cub -o sfs_EFG_crop_s${e}_h${h}_sub10_ba_before/run --threads 1 --smoothness-weight $e --max-iterations 100 --reflectance-type 0 --init-dem-height -$h --bundle-adjust-prefix run_ba_EFG4/run --float-albedo --float-exposure --float-cameras

