# Bryce Currey
# Last modified: 03/28/2023
# Hypertrace routine
# TO DO: make a function

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Note: must add file name as trailing argument!
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

mode='hypertrace' # make user input
#mode='radiance'

# libraries ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
import sys
import time
from os.path import join
import numpy as np
import xarray as xr
import netCDF4 as nc
import isofit
isofit.__version__
import scipy
import ray

from isofit.configs import configs
from isofit.core.forward import ForwardModel
from isofit.inversion.inverse import Inversion
from isofit.core.geometry import Geometry
from isofit.utils import surface_model

geom = Geometry()
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

start_time = time.time()

#paths
hyperSims = '/discover/nobackup/bcurrey/hypertrace_simulations' # make input in function
merraData = '/discover/nobackup/projects/SBG-DO/bcurrey/MERRA2/final' # keep static

# update surface mat
surface_config = 'surface/LPJ_basic_surface.json'
surface_model(join(hyperSims, surface_config)) # make function input

# config file
config_file = 'configs/LPJ_basic_config.json' # make funciton input
config_file = join(hyperSims, config_file)
config = configs.create_new_config(config_file)

# create the forward and inverse model
fm = ForwardModel(config)
iv = Inversion(config, fm)

# file name as user input
fn = 'lpj-prosail_levelC_BDR_version2a_m_2021.nc' # make function input
month = 6 # make function input
nameComps = fn.split('_')
year = nameComps[-1].split('.')[0]
var = nameComps[2]
version = nameComps[3]
print("Reflectance: ", var, "\nVersion: ", month), "\nYear: ", year)

# lpj reflectances
print("dataset: ", join(hyperSims, 'data', fn))
lpj = xr.open_dataset(join(hyperSims, 'data', fn), decode_times=False).sel(time=0))


# MERRA2 atmospheric data
h2o = xr.open_dataset(join(merraData, 'MERRA2-TQV_'+year+'.nc')).sel(time = year+'-01', method='nearest').TQV.values
aod = xr.open_dataset(join(merraData, 'MERRA2-TOTSCATAU_'+year+'.nc')).sel(time = year+'-01', method='nearest').TOTSCATAU.values

# read wavelengths and reflectances
wl = lpj.wavelength.values
rfl = lpj.reflectance_resv.values.transpose(1,2,0) # transposes to row,col,band or lat,lon,wl (aka BIP)
lat, lon, bands = rfl.shape
print('data dimensions: ', rfl.shape)

# reshape data 
rfl = rfl.reshape([lat*lon, bands])
aod = aod.reshape([lat*lon])
h2o = h2o.reshape([lat*lon])

# set nan values to zero
# all values gt zero will be excluded. This removes the NaN data as well as reflectance values lt or eq to 0
rfl = np.nan_to_num(rfl)

# match shape for radiance and retrievals 
rdn = rfl.copy().reshape([lat*lon, bands])
if mode =='hypertrace': rtr = rfl.copy().reshape([lat*lon, bands])

# extract cells gt zero
cells = rfl[:,-1]>0
rfl = rfl[cells,:]
rdn2 = rdn[cells,:]
if mode =='hypertrace': rtr2 = rtr[cells,:]
aod = aod[cells]
h2o = h2o[cells]

# loop across all cells
for i in range(rfl.shape[0]):
    atm_state = np.array([aod[i], h2o[i]])
    # conc. the atmosphere
    statevector = np.concatenate((rfl[i,:], atm_state))
    # forward to radiances
    rdn2[i,:] = fm.calc_rdn(statevector,geom)
    # inverse to retrievals
    if mode=='hypertrace':
    	rtr2[i,:] = iv.forward_uncertainty(
        iv.invert(rdn2[i,:], geom)[-1],
       	rdn2[i,:], geom)[0]
        
    if i%10000==0: 
        print('finished %i percent' % ((i+1)/rfl.shape[0]*100))
        
# add back in new data
rdn[cells,:]=rdn2
if mode =='hypertrace': rtr[cells,:]=rtr2

# reshape back to gridded format
lpj_rdn = rdn.reshape([lat,lon,bands])
if mode =='hypertrace': lpj_rtr = rtr.reshape([lat,lon,bands])

if outfiletype=='ENVI':
	# write images
	# envi.save_image(join(hyperSims, 'data', 'LPJ_TOA_radiance_2020_12.hdr'),
	#                 lpj_rdn)
	# envi.save_image(join(hyperSims, 'data', 'LPJ_retrieved_reflectance_2020_12.hdr'),
	#                 lpj_rtr)
else:
	rdn_name = 'LPJ_' + 'TOA_radiance_' + year + '_' + month
	if mode =='hypertrace': rtr_name = 'LPJ_' + 'retrieved_reflectance_' + year + '_' + month

	ncOutRdn = nc.Dataset(join(hyperSims, 'data', rdn_name), 'a'); # take this from user input
	if mode =='hypertrace': ncOutRtr = nc.Dataset(join(hyperSims, 'data', rtr_name), 'a'); 

	# create dimensions for Radiance
	ncOutRdn.createDimension('lon', lon); ncOutRdn.createDimension('lat', lat); ncOutRdn.createDimension('wavelength', bands);

	# create dimensions for Retreivals
	if mode =='hypertrace': ncOutRtr.createDimension('lon', lon); ncOutRtr.createDimension('lat', lat); ncOutRtr.createDimension('wavelength', bands);

	# create varaibles for Radiance
	lonvar = ncOutRdn.createVariable('lon','float32',('lon')); lonvar.setncattr('units', 'Degrees East'); lonvar[:] = lpj.lon.values;
	latvar = ncOutRdn.createVariable('lat','float32',('lat')); latvar.setncattr('units', 'Degrees North'); latvar[:] = lpj.lat.values;
	bins = ncOutRdn.createVariable('Bands','float64',('wavelength')); bins.setncattr('units', 'nm_from_400-2500nm'); bins[:] = wl;

	# write output for Radiance
	rdn_var = ncOutRdn.createVariable('Radiance','float32',('lat','lon','wavelength')); rdn_var.setncattr('units','W sr-1 m-2'); rdn_var[:] = lpj_rdn; 
	ncOutRdn.close();

	# create varaibles for Retreivals
	lonvar = ncOutRtr.createVariable('lon','float32',('lon')); lonvar.setncattr('units', 'Degrees East'); lonvar[:] = lpj.lon.values;
	latvar = ncOutRtr.createVariable('lat','float32',('lat')); latvar.setncattr('units', 'Degrees North'); latvar[:] = lpj.lat.values;
	bins = ncOutRtr.createVariable('Bands','float64',('wavelength')); bins.setncattr('units', 'nm_from_400-2500nm'); bins[:] = wl;

	# write output for Retreivals
	rtr_var = ncOutRtr.createVariable('Retrieved Reflectance','float32',('lat','lon','wavelength')); rtr_var.setncattr('units','Fraction'); rtr_var[:] = lpj_rtr; 
	ncOutRtr.close();

	print('finished writing file ', )
	print("Program took %s hours to run." % ((time.time() - start_time)/3600))
