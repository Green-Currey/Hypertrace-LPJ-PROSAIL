#!/bin/bash


#SBATCH --job-name=LPJ-hypertrace
#SBATCH --time=05:00:00
#SBATCH --account=s3673
#SBATCH -N 1
#SBATCH --constraint=sky

#.......................................
# print/error file (joint or by-array)
#.......................................
#SBATCH -o ./hypertrace_%j.out
#SBATCH -e ./hypertrace_%j.err

#.......................................
# for email on slurm event
#.......................................
# --mail-user bryce.currey@montan.edu
# --mail-type=END

#---------------------------------------
# load modules
#---------------------------------------
module load  anaconda/py3.9  R/4.1.0


# requires a month # between 1 and 12
if [ $# -lt 1 ]; then
    echo -e "\n\nPlease specify the month # (1-12).\n\n"
    exit 1
else
    month=$1
    MASTER_file='LPJtest_reflectance_resv_perm_monthly_2020.nc' # located in /data/MASTER # change to LPJsims location
    scripts_path='/discover/nobackup/bcurrey/hypertrace_simulations/scripts'
    data_path='/discover/nobackup/bcurrey/hypertrace_simulations/data'
    file=${data_path}/LPJ_reflectance_resv_2020_${month}.nc
    
    if test -f "$file"; then
 	echo "File: $file exists. Skipping to ISOFIT."
    else
        # step 1: select month from master dataset
        Rscript ${scripts_path}/R_scripts/R_select_month_masterNCDF.R ${month} ${MASTER_file}
        # this exports as ncdf names LPJ_reflectance_resv_2020_${month}.nc
    fi

    # activate python env
    eval "$(conda shell.bash hook)" # activates conda base environment
    conda activate /discover/nobackup/projects/SBG-DO/isofit-common/isofit_env


#    fname=($(Rscript ${scripts_path}/R_scripts/R_select_month_masterNCDF.R ${month} ${MASTER_file}))
    # step 2: run hypertrace routine
    python ${scripts_path}/py_scripts/py_hypertrace_loop_LPJ.py LPJ_reflectance_resv_2020_${month}.nc

    # convert month to ENVI/NC
    # Rscript ${scripts_path}/R_scripts/R_NCDF_ENVI_conversion.R ${data_path}
fi
