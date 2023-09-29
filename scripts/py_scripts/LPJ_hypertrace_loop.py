# Bryce Currey
# Last modified: 03/28/2023
# Hypertrace routine function for looping through LPJ reflectances using MERRA2 atmospheric data
# The function is called in run_LPJ_hypertrace.py



## start up ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# libraries ---------------------------------------------------
import sys
import time
import os
from os.path import join

import numpy as np
import xarray as xr
import netCDF4 as nc
import isofit
import scipy
import ray
from spectral.io import envi

from isofit.configs import configs
from isofit.core.forward import ForwardModel
from isofit.inversion.inverse import Inversion
from isofit.core.geometry import Geometry
from isofit.utils import surface_model


# function definition --------------------------------------------
def LPJ_hypertrace_routine (
        surface_json, # /discover/nobackup/bcurrey/hypertrace_sims/surface/LPJ_basic_surface.json
        config_json, # /discover/nobackup/bcurrey/hypertrace_sims/configs/LPJ_basic_surface.json
        reflectance_file, # e.g., /discover/nobackup/projects/SBG-DO/lpj-prosail/version2/lpj-prosail_levelC_HDR_version2a_m_2021.nc
        output_dir = '/discover/nobackup/projects/SBG-DO/lpj-prosail/version3',
        merra_dir = '/discover/nobackup/projects/SBG-DO/bcurrey/MERRA2/final',
        month = 7, # 1-12 for Jan - Dec
        outfiletype = 'netcdf', # options: ENVI or netcdf
        mode = 'hypertrace' # options: radiances or hypertrace, which outputs radiances and retrievals
        ):



# init info --------------------------------------------------------
        start_time = time.time()
        print('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
        print('Run started at:   ', start_time)
        print('Isofit version:   ', isofit.__version__)
        print('Config file:      ', config_json)
        print('Surface file:     ', surface_json)
        print('Reflectance file: ', reflectance_file)
        print('MERRA2 dir:       ', merra_dir)
        print('Output dir:       ', output_dir)
        print('Month:            ', month)
        print('Output file type: ', outfiletype)
        print('Run mode:         ', mode) 
        print('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')

## running isofit ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # to potentially do: add in config parts manually so that month can be looped through

        # update config file
        config = configs.create_new_config(config_json)

        # update surface model
        surface_model(surface_json)

        #update geometry
        geom = Geometry()

        # create the forward and inverse model
        fm = ForwardModel(config)
        iv = Inversion(config, fm)


## datasets ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LPJ reflectance data ------------------------------------------- 
        nameComps = reflectance_file.split('/')[-1].split('_'); # obtain the naming components
        year = nameComps[-1].split('.')[0];                     # data year
        var = nameComps[2];                                     # reflectance variable
        version = nameComps[3];                                 # data version
        print("Reflectance: ", var, "\nVersion: ", version, "\nMonth: ", month, "\nYear: ", year);    

        if version == 'version1':
            new_version = version[:-1]+'3'
        else:
            new_version = version[:-2] + '3' + version[-1:]



# check if file exists ---------------------------------------------

        if outfiletype == 'ENVI': # if ENVI output file is desired
            rdn_name = 'lpj-prosail_levelD_TOA-radiance_' + new_version + '_'+str(month)+'_' + str(year)
        else: 
            rdn_name = 'lpj-prosail_levelD_TOA-radiance_' + new_version + '_' + str(month) + '_' + str(year) +'.nc'


        if os.path.exists(join(output_dir, rdn_name)):
            print(rdn_name, "file already exists.")
            return;


        lpj = xr.open_dataset(reflectance_file, decode_times=False).sel(time=int(month)-1)
        wl = lpj.wavelength.values; # wavelengths
        rfl = lpj[var].values.transpose(1,2,0);     # transposes to row,col,band or lat,lon,wl (aka BIP)
        lat, lon, bands = rfl.shape;
        print('data dimensions: ', rfl.shape);

# MERRA2 atmospheric data ------------------------------------------
        merra_date = str(year)+'-'+str(month).rjust(2,'0');
        h2o = xr.open_dataset(join(merra_dir, 'MERRA2-TQV_'+str(year)+'.nc')).sel(time = merra_date, method='nearest').TQV.values;
        aod = xr.open_dataset(join(merra_dir, 'MERRA2-TOTSCATAU_'+str(year)+'.nc')).sel(time = merra_date, method='nearest').TOTSCATAU.values;


# reshaping the data for looping ---------------------------------------
        rfl = rfl.reshape([lat*lon, bands]);
        aod = aod.reshape([lat*lon]);
        h2o = h2o.reshape([lat*lon]);

        # set nan values to zero
        # all values gt zero will be excluded. 
        # This removes the NaN data as well as reflectance values lt or eq to 0
        rfl = np.nan_to_num(rfl);

        # match shape for radiance and retrievals 
        rdn = rfl.copy().reshape([lat*lon, bands]);
        if mode =='hypertrace': 
            rtr = rfl.copy().reshape([lat*lon, bands]);

        # extract cells gt zero
        cells = rfl[:,-1]>0;                                # probably a better way to check for this (maybe row sums?)
        rfl = rfl[cells,:];
        rdn2 = rdn[cells,:];
        if mode =='hypertrace': 
            rtr2 = rtr[cells,:];
        aod = aod[cells];
        h2o = h2o[cells];
        aod[aod==0]=0.01;
        h2o[h2o==0]=0.1;



## data processing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# looping isofit across all cells ---------------------------------

        for i in range(rfl.shape[0]):
            # create the atmosphere using MERRA data
            atm_state = np.array([aod[i], h2o[i]/10]);      # scale h2o from kg.m2 to g.cm2
            # create the state vector the atmosphere
            statevector = np.concatenate((rfl[i,:], atm_state));

            # forward mode to radiances
            rdn2[i,:] = fm.calc_rdn(statevector, geom);
        
            # inverse to retrievals (only in 'hypertrace' mode)
            if mode=='hypertrace':
                rtr2[i,:] = iv.forward_uncertainty(
                        iv.invert(rdn2[i,:], geom)[-1],     # inverts the radiance and uncertainties
                        rdn2[i,:], geom)[0];                # from radiances, obtains retrievals
    
            if i%10000==0: 
                print('finished %i percent' % ((i+1)/rfl.shape[0]*100));
        ## end isofit loop

        # add back in new data and reshape
        rdn[cells,:]=rdn2;
        lpj_rdn = rdn.reshape([lat,lon,bands])

        if mode =='hypertrace': 
            rtr[cells,:]=rtr2;
            lpj_rtr = rtr.reshape([lat,lon,bands]);



## Exporting resulting data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # rdn name: lpj-prosail_levelD_TOA-radiance_version3a_m_2021.nc
        # rtr name: lpj-prosail_levelE_retrieved-HDR_version3a_m_2021.nc


# output ENVI --------------------------------------------
        if outfiletype == 'ENVI': # if ENVI output file is desired
            rdn_out = join(output_dir, 'lpj-prosail_levelD_TOA-radiance_' + new_version + '_'+str(month)+'_' + str(year))
            envi.save_image(rdn_out, lpj_rdn);

            if modei == 'hypertrace':
                rtr_out = join(output_dir, 'Retrievals', 'lpj-prosail_levelE_retrieved-HDR_' + new_version + '_' + str(month) + '_' + str(year));
                envi.save_image(rdn_out, lpj_rtr);


# output ncdf -----------------------------------------------
        else: # else NCDF is output (default)
            rdn_out = join(output_dir, 'lpj-prosail_levelD_TOA-radiance_' + new_version + '_' + str(month) + '_' + str(year) +'.nc');
            rdn_out_nc = nc.Dataset(rdn_out, 'a'); 

            # create dimensions
            rdn_out_nc.createDimension('lon', lon);
            rdn_out_nc.createDimension('lat', lat);
            rdn_out_nc.createDimension('wavelength', bands);

            # create varaibles
            lonvar = rdn_out_nc.createVariable('lon','float32',('lon')); lonvar.setncattr('units', 'Degrees East'); lonvar[:] = lpj.lon.values;
            latvar = rdn_out_nc.createVariable('lat','float32',('lat')); latvar.setncattr('units', 'Degrees North'); latvar[:] = lpj.lat.values;
            bins = rdn_out_nc.createVariable('Bands','float64',('wavelength')); bins.setncattr('units', 'nm_from_400-2500nm'); bins[:] = wl;

            # write output
            rdn_var = rdn_out_nc.createVariable('Radiance','float32',('lat','lon','wavelength'));
            rdn_var.setncattr('units','W sr-1 m-2');
            rdn_var[:] = lpj_rdn; 
            rdn_out_nc.close();

            if mode =='hypertrace':
                rtr_out = join(output_dir, 'Retrievals', 'lpj-prosail_levelE_retrieved-HDR_' + new_version + '_' + str(month) + '_' + str(year) +'.nc');
                rtr_out_nc = nc.Dataset(rtr_out, 'a');

                # create dimensions
                rtr_out_nc.createDimension('lon', lon);
                rtr_out_nc.createDimension('lat', lat);
                rtr_out_nc.createDimension('wavelength', bands);


                # create varaibles for Radiance
                lonvar = rtr_out_nc.createVariable('lon','float32',('lon')); lonvar.setncattr('units', 'Degrees East'); lonvar[:] = lpj.lon.values;
                latvar = rtr_out_nc.createVariable('lat','float32',('lat')); latvar.setncattr('units', 'Degrees North'); latvar[:] = lpj.lat.values;
                bins = rtr_out_nc.createVariable('Bands','float64',('wavelength')); bins.setncattr('units', 'nm_from_400-2500nm'); bins[:] = wl;

                # write output for Radiance
                rtr_var = rtr_out_nc.createVariable('Reflectance','float32',('lat','lon','wavelength'));
                rtr_var.setncattr('units','fraction');
                rtr_var[:] = lpj_rtr; 
                rtr_out_nc.close();        

## end outfiletype conditional ---------------------------------------

        print('finished processing ', reflectance_file);
        if mode == 'hypertrace': 
            print('Hypertrace turned on. Retrieved HDR returned');
        else: 
            print('Only TOA radiances created.');
            print("Program took %s hours to run." % ((time.time() - start_time)/3600));

        return; 
## end function definition----------------------------------------------
