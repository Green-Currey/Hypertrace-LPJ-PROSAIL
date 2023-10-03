#!/bin/sh

#Mar 2023
#Extract AOD and H2O variables for a single year
# NOTE: getMerra2-lsm_AOD_H2O.sh needs to already have been run.

#Processing steps
#1. Extract variables
#1a. Rescale when necessary
#2a. Merge to 6 hourly x year
#2b. Merge to daily x all years
#2c. Merge to monthly x all years
#5. Change varnames and units and clear history
#6. Resample to 0.5 x 0.5 degree

module load cdo

#Set MERRA-2 variable list end year and end month
varList=("TOTSCATAU" "TQV")
year=$year # earliest possible year is 1980

#Set file paths to MERRA2 archive
fdirIn=/discover/nobackup/projects/gmao/merra2/data/products
fdirOut=/discover/nobackup/projects/SBG-DO/bcurrey/MERRA2
fdirInCru=/discover/nobackup/bcurrey/Hypertrace-LPJ-PROSAIL/MERRA2

#Merge daily by daily files to daily by yearly, then to full time series
for var in ${varList[@]};
do
	echo $fdirOut/'prep/dailybyyear'/'MERRA2-'$var'_'$year'.nc4'
	if [[ ! -f $fdirOut/'prep/dailybyyear'/'MERRA2-'$var'_'$year'.nc4' ]]
	then
		cdo mergetime $fdirOut/'prep/dailybyday'/'MERRA2-'$var'_'$year????* $fdirOut/'prep/dailybyyear'/'MERRA2-'$var'_'$year'.nc4'
	fi
	cdo monmean $fdirOut/'prep/dailybyyear'/'MERRA2-'$var'_'$year'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$year'.nc4'
	ncatted -O -h -a,global,d,, $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$year'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$year'.nc4'
	cdo -b F32 -f nc1 remapbil,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$year'.nc4' $fdirOut/'final'/'MERRA2-'$var'_'$year'.nc'
done
