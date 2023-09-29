# libraries
import sys
from os.path import join
import numpy as np
import isofit
import scipy
import ray

# LPJ_reflectance_resv_2020_5.nc

fn = sys.argv[1]
nameComps = fn.split('_')
month = nameComps[-1]
year = nameComps[-2]
var = nameComps[1] + " " + nameComps[2]

print(var, year, month)

