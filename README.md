# Hypertrace-LPJ-PROSAIL
Implementation of the forward and backwards ISOFIT routine on LPJ-PROSAIL data.

## Pipeline:
To run, enter **sh _scripts/LPJ_hypertrace_routine.sh_**

1. _LPJ_hypertrace_routine.sh_ calls:
    1. _MERRA2/getMerra2-lsm_AOD_H2O_singleyear.sh_ 
            - _Extracts the MERRA2 AOT and H2O values for the atm correction._
    2. _execute_LPJ_hypertrace.sh_ calls:
            - _This script sbatch's the python script 12 times, one for each month_
        1._py_scripts/LPJ_hypertrace_loop.py_
            - _The main script that loops through each gridcell of LPJ-PROSAIL and MERRA2 to calculate the TOA radiances and retrievals_
    3._hypertrace_merge.sh_
            - _This merges the monthly files and modifies the meta data


## If used anywhere other than discover, the following files need to be changed:
1. _configs/LPJ_basic_config.json_
2. _surface/LPJ_basic_surface.json_
3. _LPJ_hypertrace_routine.sh_

## TO DO:
1. Change _getMerra2-lsm_AOD_H2O_singleyear.sh_ such that it extracts the merra data from the nearest to the overpass time (11:00).
2. Use MODTRAN LUT.
3. Use SBG instrument file.
4. Don't cap Merra2 data based on LUT -> create larger LUT.
