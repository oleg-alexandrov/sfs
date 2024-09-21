crop from = img1/ESP_016777_1560_RED.mos_hijitreged.norm.cub to = img1/ESP_016777_1560_RED.mos_hijitreged.norm_crop.cub sample = 10701 line = 11637 nsamples = 1720 nlines = 1783
crop from = img2/ESP_018412_1560_RED.mos_hijitreged.norm.cub to = img2/ESP_018412_1560_RED.mos_hijitreged.norm_crop.cub sample = 4966 line = 3707 nsamples = 5034 nlines = 6444
ln -s img1/ESP_016777_1560_RED.mos_hijitreged.norm_crop.cub mars1.cub
ln -s img2/ESP_018412_1560_RED.mos_hijitreged.norm_crop.cub mars2.cub


bundle_adjust mars1.cub mars2.cub -o mars_ba/run
bundle_adjust mars1_sub10.cub mars2_sub10.cub -o mars_ba_sub10/run

parallel_stereo mars1.cub mars2.cub --bundle-adjust-prefix mars_ba/run mars_stereo_ba_crop_v3/run --subpixel-mode 3 --left-image-crop-win 1510 -50 6350 6680 --right-image-crop-win 1520 500 3500 4350 --nodes-list nodes.txt

stereo mars1_sub10.cub mars2_sub10.cub --bundle-adjust-prefix mars_ba_sub10/run mars_stereo_ba_crop_sub10_v3/run --subpixel-mode 3 --left-image-crop-win 151 -5 635 668 --right-image-crop-win 152 50 350 435

pc_align --max-displacement 50 mars_stereo_ba_crop_v3/run-PC.tif mars_stereo_ba_crop_sub10_v3/run-PC.tif -o mars_stereo_ba_crop_v3/run --save-inv-transformed-reference-points

pdm --tr .00005053363987 mars_stereo_ba_crop_v3/run-trans_reference.tif
pdm --tr .00005053363987 mars_stereo_ba_crop_sub10_v3/run-PC.tif
pdm --tr .00005053363987 mars_stereo_ba_crop_v3/run-PC.tif
gdt -projwin -33.7388605, -23.9276532 -33.7306740, -23.9343742 mars_stereo_ba_crop_v3/run-trans_reference-DEM.tif mars_stereo_ba_crop_v3/run-trans_reference-crop8-DEM.tif
gdt -projwin -33.7388605, -23.9276532 -33.7306740, -23.9343742 mars_stereo_ba_crop_sub10_v3/run-DEM.tif mars_stereo_ba_crop_sub10_v3/run-crop8-DEM.tif

export e=0.16; sfs -i mars_stereo_ba_crop_sub10_v3/run-crop8-DEM.tif mars1_sub10.cub mars2_sub10.cub -o sfs_mars12_v4_wt${e}_noalb_r1_crop8/run --threads 1 --smoothness-weight $e --max-iterations 100 --reflectance-type 1 --use-approx-camera-models --bundle-adjust-prefix mars_ba_sub10/run --float-exposure --float-cameras

diff.sh mars_stereo_ba_crop_v3/run-trans_reference-crop8-DEM.tif sfs_mars12_v4_wt0.16_noalb_r1_crop8/run-DEM-iter0.tif 
  Minimum=0.000, Maximum=3.763, Mean=0.706, StdDev=0.592


diff.sh mars_stereo_ba_crop_v3/run-trans_reference-crop8-DEM.tif sfs_mars12_v4_wt0.16_noalb_r1_crop8/run-DEM-iter29.tif
Minimum=0.000, Maximum=4.897, Mean=1.056, StdDev=0.977


