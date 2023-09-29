#!/bin/bash


# Execute hypertrace for each month, as its own job.

#---------------------------------------
# load modules
#---------------------------------------
module load  anaconda/py3.9 
module load cdo

export isofit_scripts='/discover/nobackup/bcurrey/Hypertrace-LPJ-PROSAIL/scripts/py_scripts'

for ((month=1; month <=12; month+=1)); do
    sed -i "3s|.*|#SBATCH --job-name=Hyper$month|" ${isofit_scripts}/LPJ_hypertrace_routine.sh
    sbatch ${isofit_scripts}/LPJ_hypertrace_routine.sh $month
done

# cdo mergetime...

