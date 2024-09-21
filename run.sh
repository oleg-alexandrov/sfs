# To run:
sw=0.001; iw=1.00; dw=1e-8; swpq=0.0001; export ISISROOT=$HOME/projects/base_system; sfs -i run_EF_sub10_stereo_ba_subpix3/run-crop1-DEM.tif E_crop_sub10.cub G_crop_sub10.cub H_crop_sub10.cub -o sfs_EGH_sw${sw}_iw${iw}_dw${dw}_sub10_fae_swpq${swpq}/run --reflectance-type 1 --smoothness-weight ${sw} --initial-dem-constraint-weight ${dw} --max-iterations 10 --integrability-constraint-weight ${iw} --bundle-adjust-prefix run_ba_sub10/run --use-approx-camera-models --use-rpc-approximation --crop-input-images --float-albedo --float-exposure --smoothness-weight-pq ${swpq}

Best results:
sfs_EGH_sw0.02_iw5.00_dw0.00_sub10_fae_swpq0.000/run-DEM-final.tif Minimum=0.000, Maximum=10.951, Mean=2.138, StdDev=1.342

sfs_EGH_sw0.08_iw0.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif Minimum=0.000, Maximum=10.951, Mean=1.810, StdDev=1.353

These have the iw constraint and no sw constraint
sfs_EGH_sw0.00_iw5.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif Minimum=0.000, Maximum=11.015, Mean=2.692, StdDev=1.535
sfs_EGH_sw0.00_iw5.00_dw0.00_sub10_fae_swpq0.001/run-DEM-final.tif Minimum=0.000, Maximum=11.014, Mean=2.692, StdDev=1.535
sfs_EGH_sw0.001_iw1.00_dw1e-8_sub10_fae_swpq0.0001/run-DEM-final.tif Minimum=0.000, Maximum=10.951, Mean=1.966, StdDev=1.404

sfs_EGH_sw0.00_iw1.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif Minimum=0.000, Maximum=10.951, Mean=2.252, StdDev=1.790
sfs_EGH_sw0.01_iw1.00_dw0.00_sub10_fae_swpq0.00/run-DEM-final.tif Minimum=0.000, Maximum=10.951, Mean=1.996, StdDev=1.350


Stats
for h in $(for f in $(llt *sfs* | pc 0); do llt $f/run-DEM*tif |grep -i -v hill | grep -i -v CMAP | grep -i -v diff.tif | tail -n 1; done | pc 0); do echo $h $(di run_EF_full_stereo_ba_subpix3/run-crop1-DEM.tif $h); done | tee output.txt
