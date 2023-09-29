#!/bin/bash

eval "$(conda shell.bash hook)" # activates conda base environment
conda activate R_env # activates your virtual environment

month=3
MASTER_file='LPJtest_reflectance_resv_perm_monthly_2020.nc' # located in /data/MASTER
scripts_path='/efs/bcurrey/LPJ_isofit_SBG/scripts'
data_path='/efs/bcurrey/LPJ_isofit_SBG/data'

# step 1: select month from master dataset
Rscript ${scripts_path}/R_scripts/test2.R ${month} ${MASTER_file}
# Rscript ${scripts_path}/R_scripts/R_select_month_masterNCDF.R ${month} ${MASTER_file}
# this exports as ncdf names LPJ_reflectance_resv_2020_${month}.nc
echo "R test complete"

eval "$(conda shell.bash hook)" # activates conda base environment
conda activate isofit_env_local # activates your virtual environment

# run hypertrace routine
python ${scripts_path}/py_scripts/test2.py LPJ_reflectance_resv_2020_${month}.nc

#conver month to ENVI/NC
#Rscript ${scripts_path}/R_scripts/R_NCDF_ENVI_conversion.R ${data_path}
