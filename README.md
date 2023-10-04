# Hypertrace-LPJ-PROSAIL
### Implementation of the forward and backward ISOFIT routine on LPJ-PROSAIL data.
This procedure takes a 12-month LPJ-PROSAIL reflectance NetCDF and outputs 12-month TOA Radiance and Retrieval-HDR NetCDFs. 


Diagram for this process:
<img src="https://github.com/Green-Currey/Hypertrace-LPJ-PROSAIL/assets/57914237/dfaaa590-c257-4782-ba38-53b23e2a158d" alt="image" width="500"/>


## Pipeline:
To run, enter **sh _scripts/LPJ_hypertrace_routine.sh_**

1. _LPJ_hypertrace_routine.sh_ calls:
    1. _/MERRA2/getMerra2-lsm_AOD_H2O_singleyear.sh_ 
       - Extracts the MERRA2 AOT and H2O values for the atm correction.
    2. _execute_LPJ_hypertrace.sh_ calls:
       - This script sbatch's the Python script 12 times, one for each month
        1. **_/py_scripts/LPJ_hypertrace_loop.py_**
            - The main script that loops through each grid cell of LPJ-PROSAIL and MERRA2 to calculate the TOA radiances and retrievals
    3. _hypertrace_merge.sh_
        - This merges the monthly files and modifies the metadata. This is launched after all other jobs with the same name have finished, ensuring that it runs last using '--dependency=singleton'
**NOTE**: This process takes ~3 hours to run.

## If used anywhere other than Discover, the following files need to be changed:
1. _/configs/LPJ_basic_config.json_
2. _/surface/LPJ_basic_surface.json_
3. _/scripts/LPJ_hypertrace_routine.sh_

## TO DO/Improvements:
1. Change _getMerra2-lsm_AOD_H2O_singleyear.sh_ to extract the MERRA2 data from the nearest to the overpass time (11:00).
2. Use MODTRAN LUT.
3. Use SBG instrument file.
4. Don't cap Merra2 data based on LUT -> create larger LUT.
5. Improve metadata and data writing to netcdf in Python script (add metadata, convert to int, etc.).
