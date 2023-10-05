#!/bin/bash

#SBATCH --job-name=HT2015
#SBATCH --time=02:59:00
#SBATCH --account=s3673
# #SBATCH --mail-user brycecurrey93@gmail.com
# #SBATCH --mail-type=ALL

#---------------------------------------
# load modules
#---------------------------------------
module load  anaconda/py3.9 

# Chain env variables along.
export surfacePath=$surfacePath
export configPath=$configPath
export reflectancePath=$reflectancePath
export ncdfDir=$ncdfDir
export merraDir=$merraDir
export month=$1
export hypertraceOrRadiance=$hypertraceOrRadiance
export EMULATOR_PATH="/discover/nobackup/projects/SBG-DO/isofit-commons/sRTMnet_v100/"

# activate python env
eval "$(conda shell.bash hook)" # activates conda base environment
conda activate isofit_env

python ${isofit_scripts}/py_scripts/LPJ_hypertrace_loop.py ${month}

