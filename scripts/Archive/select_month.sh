#!/bin/bash

#SBATCH --nodes 1 # number of nodes
#SBATCH --job-name mon1
#SBATCH --time 00:05:00  # time requested in hour:minute:second
#SBATCH --output mon3_out.txt   # send stdout to outfile
#SBATCH --error mon3_err.txt  # send stderr to errfile

month=3
scripts_path='/efs/bcurrey/LPJ_isofit_SBG/scripts'
data_path='/efs/bcurrey/LPJ_isofit_SBG/data'

eval "$(conda shell.bash hook)" # activates conda base environment:
conda activate R_env

Rscript ${scripts_path}/R_scripts/R_select_month_masterNCDF.R ${month}

Rscript ${scripts_path}/R_scripts/R_NCDF_ENVI_conversion.R ${data_path}
