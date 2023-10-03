#!/bin/sh
#SBATCH --job-name=MERRA_extract
#SBATCH --ntasks=1
#SBATCH --time=12:00:00
#SBATCH -o ctmextract_out.%j
#SBATCH -e ctmextract_err.%j
#SBATCH --account=s3673
#SBATCH --mail-user=bryce.currey@montana.edu

#Feb 2023
#Extract AOD and H2O variables

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
startyear=1980 # earliest possible year is 1980
endyear=2021 # Use only fully processed previous years (currently 2022)

#Set file paths to MERRA2 archive
fdirIn=/discover/nobackup/projects/gmao/merra2/data/products
fdirOut=/discover/nobackup/projects/SBG-DO/bcurrey/MERRA2
fdirInCru=/discover/nobackup/bcurrey/MERRA2

#Make dirs
if [ ! -d  $fdirOut/prep ]; then mkdir $fdirOut/prep; fi
#if [ ! -d  $fdirOut/prep/6hourlybyday ]; then mkdir $fdirOut/prep/6hourlybyday; fi
#if [ ! -d  $fdirOut/prep/6hourlybyyear ]; then mkdir $fdirOut/prep/6hourlybyyear; fi
if [ ! -d  $fdirOut/prep/hourlybyday ]; then mkdir $fdirOut/prep/hourlybyday; fi
if [ ! -d  $fdirOut/prep/dailybyyear ]; then mkdir $fdirOut/prep/dailybyyear; fi
if [ ! -d  $fdirOut/prep/dailybyday ]; then mkdir $fdirOut/prep/dailybyday; fi
if [ ! -d  $fdirOut/prep/daily-allYear ]; then mkdir $fdirOut/prep/daily-allYear; fi
if [ ! -d  $fdirOut/prep/monthly-allYear ]; then mkdir $fdirOut/prep/monthly-allYear; fi

if [ ! -d  $fdirOut/final ]; then mkdir $fdirOut/final; fi
if [ ! -d  $fdirOut/final/monthly-allYear ]; then mkdir $fdirOut/final/monthly-allYear; fi


# Obtains all relevant files from GMAO repository. If alread present, skips this 
for h2ofile in $fdirIn/MERRA2_all/Y*/M??/MERRA2*inst1_2d_asm_Nx* #asm
do
        #Get just the file name and strip the main file name
        fileFull=$(basename $h2ofile)
        fileDate=${fileFull#*.*.*}
        echo $h2ofile $fileDate

        #Extract the h2o variables
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-TQV_'$fileDate ]]
        then
                #Select/average to 6hourly/average to daily/remove hourly
                cdo selvar,TQV $h2ofile $fdirOut/'prep/hourlybyday'/'MERRA2-TQV_'$fileDate
#                cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-TQV_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-TQV_'$fileDate
                cdo daymean $fdirOut/'prep/hourlybyday'/'MERRA2-TQV_'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-TQV_'$fileDate
        fi
done

#Select AOD variables
for aodfile in $fdirIn/MERRA2_all/Y*/M??/MERRA2*tavg1_2d_aer_Nx*
do
        fileFull=$(basename $aodfile)
        fileDate=${fileFull#*.*.*}
        echo $aodfile $fileDate
        
	#Extract the AOD variables
	if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-TOTSCATAU_'$fileDate ]]
        then
                cdo selvar,TOTSCATAU $aodfile $fdirOut/'prep/hourlybyday'/'MERRA2-TOTSCATAU_'$fileDate
#		cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-TOTSCATAU_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-TOTSCATAU_'$fileDate
		cdo daymean $fdirOut/'prep/hourlybyday'/'MERRA2-TOTSCATAU_'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-TOTSCATAU_'$fileDate
        fi
done

#################################################
#Merge 6hourly daily files to 6hourly yearly files
#for var in ${varList[@]};
#do
#	for (( year = $startyear; year <= $endyear; year++ ));
#	do
#		echo $fdirOut/'prep/6hourlybyyear'/'MERRA2-'$var'_'$year'.nc4'
#		if [[ ! -f $fdirOut/'prep/6hourlybyyear'/'MERRA2-'$var'_'$year'.nc4' ]]
#		then
#	        	cdo mergetime $fdirOut/'prep/6hourlybyday'/'MERRA2-'$var'_'$year????* $fdirOut/'prep/6hourlybyyear'/'MERRA2-'$var'_'$year'.nc4'
#		fi
#	done
#done

#Merge daily by daily files to daily by yearly, then to full time series
for var in ${varList[@]};
do
	for (( year = $startyear; year <= $endyear; year++ ));
	do
		echo $fdirOut/'prep/dailybyyear'/'MERRA2-'$var'_'$year'.nc4'
		if [[ ! -f $fdirOut/'prep/dailybyyear'/'MERRA2-'$var'_'$year'.nc4' ]]
		then
			cdo mergetime $fdirOut/'prep/dailybyday'/'MERRA2-'$var'_'$year????* $fdirOut/'prep/dailybyyear'/'MERRA2-'$var'_'$year'.nc4'
		fi
	done
	cdo mergetime $fdirOut/'prep/dailybyyear'/'MERRA2-'$var'_'* $fdirOut/'prep/daily-allYear'/'MERRA2-'$var'_'$startyear'-'$endyear'.nc4'
done

#Merge daily to monthly time series
cdo monmean $fdirOut/'prep/daily-allYear'/'MERRA2-TQV_'$startyear'-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-TQV_'$startyear'-'$endyear'.nc4'
cdo monmean $fdirOut/'prep/daily-allYear'/'MERRA2-TOTSCATAU_'$startyear'-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-TOTSCATAU_'$startyear'-'$endyear'.nc4'

#################################################
#Fix units, clear history and variable names for monthly
for var in ${varList[@]};
do
	ncatted -O -h -a,global,d,, $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$startyear'-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$startyear'-'$endyear'.nc4'
done

#################################################
#Project monthly to 0.5 degree, and uncompress
cdo -b F32 -f nc1 remapbil,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-TQV_'$startyear'-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-TQV_'$startyear'-'$endyear'.nc'
cdo -b F32 -f nc1 remapbil,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-TOTSCATAU_'$startyear'-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-TOTSCATAU_'$startyear'-'$endyear'.nc'
