# Bryce Currey
# 02/21/2023
# Hypertrace routine
# TO DO: make a function

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Note: must add file name as trailing argument!
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# libraries ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
import sys
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

geom = Geometry()
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#paths
efs = '/efs/bcurrey/LPJ_isofit_SBG'

# update surface mat
surface_model(join(efs, 'surface', 'LPJ_basic_surface.json'))

# config file
config_file = join(efs,'configs','LPJ_basic_config.json')
config = configs.create_new_config(config_file)

# create the forward and inverse model
fm = ForwardModel(config)
iv = Inversion(config, fm)

# set atmosphere
h2o_column = 1.7
aod550 = 0.01
atm_state = np.array([h2o_column, aod550])

# add ~~~~~~~~~~~
fn = sys.argv[1]
nameComps = fn.split('_')
month = nameComps[-1]
year = nameComps[-2]
var = nameComps[1] + " " + nameComps[2]

print("varname: ", var,
      "\nYear: ", year,
      "\nMonth: ", month)


# add ~~~~~~~~~~~
# lpj reflectances 
print("dataset: ", join(efs, 'data', fn))
lpj = xr.open_dataset(join(efs, 'data', fn)) # make this user input
print('rdn_name = ','LPJ_' + 'TOA_radiance_' + year + '_' + month)
# read wavelengths and reflectances
wl = lpj.wavelegnth.values
rfl = lpj.reflectance_resv.values.transpose(1,2,0) # transposes to row,col,band or lat,lon,wl (aka BIP)
print(rfl.shape)

# deleted ~~~~~~~~~~~
#~
#
#
#
#
#
# deleted ~~~~~~~~~~~
