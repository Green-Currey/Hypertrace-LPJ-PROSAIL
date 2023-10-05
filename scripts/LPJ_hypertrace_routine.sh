#!/bin/bash

# Execute hypertrace for each month, as its own job.

#---------------------------------------
# load modules
#---------------------------------------
module load  anaconda/py3.9 

export isofit_scripts='/discover/nobackup/bcurrey/Hypertrace-LPJ-PROSAIL/scripts/'
export year=2015
export stream='DR'
export sims='lpjv21'
export version='Version021'
export rflName="lpj-prosail_levelC_${stream}_${version}_m_$year.nc"
export hypertraceDir='/discover/nobackup/bcurrey/Hypertrace-LPJ-PROSAIL/'
export ncdfDir="/discover/nobackup/projects/SBG-DO/bcurrey/global_run_simulations/$sims/ncdf_outputs/"
export merraDir="/discover/nobackup/projects/SBG-DO/bcurrey/MERRA2/final"
export reflectancePath="$ncdfDir/$rflName"
export configPath="$hypertraceDir/configs/LPJ_basic_config.json"
export surfacePath="$hypertraceDir/surface/LPJ_basic_surface.json"
export hypertraceOrRadiance="hypertrace" #change to anything else for just radiances


## OBTAIN MERRA2 DATA
sh $hypertraceDir/MERRA2/getMerra2-lsm_AOD_H2O_singleyear.sh

for ((month=1; month <=12; month+=1)); do

    sed -i "3s|.*|#SBATCH --job-name=HT$year|" ${isofit_scripts}/execute_LPJ_hypertrace.sh
    sbatch ${isofit_scripts}/execute_LPJ_hypertrace.sh $month
    
done

# cdo merge...

sed -i "3s|.*|#SBATCH --job-name=HT$year|" ${isofit_scripts}/hypertrace_merge.sh
sbatch --dependency=singleton $isofit_scripts/hypertrace_merge.sh
