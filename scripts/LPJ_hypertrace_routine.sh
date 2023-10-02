#!/bin/bash

#SBATCH --job-name=Hyper
#SBATCH --time=02:30:00
#SBATCH --account=s3673
# --mail-user brycecurrey93@gmail.com
# --mail-type=ALL

#---------------------------------------
# load modules
#---------------------------------------
module load  anaconda/py3.9 

# Add month number to the end of the bash script.

## ------ testing ------- ##
# This will typically get called from the monthly script
# run this script with the month number after it!
# also will typically be called
export isofit_scripts='/discover/nobackup/bcurrey/Hypertrace-LPJ-PROSAIL/scripts/py_scripts/'
## ------ end testing ------ ##

export year=2022
export stream='DR'
export sims=lpj_prosail_v21
export rflName="lpj-prosail_levelC_${stream}_version021_m_$year.nc"
export py_scripts=$isofit_scripts
export hypertraceDir='/discover/nobackup/bcurrey/Hypertrace-LPJ-PROSAIL/'
export ncdfDir="/discover/nobackup/projects/SBG-DO/bcurrey/global_run_simulations/$sims/ncdf_outputs/"
export month=$1
export reflectancePath="$ncdfDir/$rflName"
export configPath="$hypertraceDir/configs/LPJ_basic_config.json"
export surfacePath="$hypertraceDir/surface/LPJ_basic_surface.json"
export hypertraceOrRadiance="hypertrace" #change to anything else for just radiances


## OBTAIN MERRA2 DATA
sh $hypertraceDir/MERRA2/getMerra2-lsm_AOD_H2O_singleyear.sh

# activate python env
eval "$(conda shell.bash hook)" # activates conda base environment
conda activate isofit_env

python ${py_scripts}/run_LPJ_hypertrace.py ${month}

