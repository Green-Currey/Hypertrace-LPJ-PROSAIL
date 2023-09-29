#!/bin/sh
#SBATCH --nodes 1      # number of nodes
#SBATCH --job-name sbatch_test
#SBATCH --time 05:00:00  # time requested in hour:minute:second
#SBATCH --output outfile.txt   # send stdout to outfile
#SBATCH --error errfile.txt  # send stderr to errfile


scripts_path="/efs/bcurrey/LPJ_isofit_SBG/scripts"
# eval "$(conda shell.bash hook)" # activates conda base environment
# conda activate <isofit_env> # activates your virtual environment

python ${scripts_path}/py_scripts/py_LPJ_isofit_loop.py

