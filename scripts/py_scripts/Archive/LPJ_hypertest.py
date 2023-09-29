# Bryce Currey
# Last modified: 03/28/2023
# Hypertrace routine function for LPJ

# libraries ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
import sys
import time
from os.path import join
import numpy as np
import xarray as xr
import netCDF4 as nc
import isofit
import scipy
import ray
    
from isofit.configs import configs
from isofit.core.forward import ForwardModel
from isofit.inversion.inverse import Inversion
from isofit.core.geometry import Geometry
from isofit.utils import surface_model

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
   print('Config file:      ', config_json) 
   print('Surface file:     ', surface_json) 
   print('Reflectance file: ', reflectance_file) 
   print('MERRA2 dir:       ', merra_dir) 
   print('Output dir:       ', output_dir) 
   print('Month:            ', month) 
   print('Output file type: ', outfiletype) 
   print('Run mode:         ', mode)

   return
