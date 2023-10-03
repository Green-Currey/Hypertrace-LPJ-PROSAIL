#!/bin/sh
#SBATCH --job-name=ctmextract
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=2048
#SBATCH --time=12:00:00
#SBATCH -o ctmextract_out.%j
#SBATCH -e ctmextract_err.%j
#SBATCH --account=s1460
#SBATCH --mail-user=benjamin.poulter@nasa.gov

#May 2020
#Extract land surface model MERRA-2 data, create 6 hourly, daily, monthly products
#WARNING: ONLY RUN WHEN FULL MERRA-2 MONTH IS AVAILABLE so that merging/recylcing works
#WARNING: MANUALLY EDIT LINE FOR MERGING rest of 2019 w 2020

#Processing steps
#1. Extract variables for LSM
#1a. Rescale when necessary
#2a. Merge to 6 hourly x year
#2b. Merge to daily x all years
#2c. Merge to monthly x all years
#3. Create wetdays
#4. Update last year to complete 12 months using previous year data
#5. Change varnames and units and clear history
#6. Resample to 0.5 x 0.5 degree

#Land surface model inputs and corresponding MERRA2 variables name:
#  Processing variable:    MERRA-2 variable name      Aggregate 6hourly   Aggregate daily     Aggregate monthly            MERRA2 File	Remap method
# - Precipitation:         PRECTOTCORR                timselmean	  daysum              monsum                       M2T1NXFLX   	remapcon
# - Surface temperature:   TLML                       timselmean	  daymean             monmean                      M2T1NXFLX   	remapbil
# - Surface eastward wind: ULML                       timselmean          daymean             monmean                      M2T1NXFLX    remapcon
# - Surface northward wind:VLML                       timselmean          daymean             monmean                      M2T1NXFLX    remapcon
# - Specific humidity:     QLML                       timselmean          daymean             monmean                      M2T1NXFLX    remapbil
# - Snowfall               PRECSNO                    timselmean          daysum              monsum                       M2T1NXFLX    remapcon
# - Diffuse radiation:     PARDFLAND                  timselmean          daysum              monmean                      M2T1NXLND    remapcon
# - Direct radiation:      PARDRLAND                  timselmean          daysum              monmean                      M2T1NXLND    remapcon
# - Surface pressure:      PS                         timselmean          daymean             monmean                      M2T1NXSLV    remapbil
# - Shortwave radiation:   SWGDN                      timselmean          daysum              monmean                      M2T1NXRAD   	remapbil
# - Longwave radiation:    LWGAB                      timselmean          daysum              monmean                      M2T1NXRAD   	remapbil
# - Wetdays:		   WETD			      NA		  NA		      NA			   NA		NA
# - Root zone soil mois	   GWETROOT		      timselmean	  daymean	      monmean			   M2T1NXLND    remapbil

#Non LSM variables (AOD)
#			   TOTSCATAU
#			   TOTEXTTAU

#Set MERRA-2 variable list end year and end month
varList=("PRECTOTCORR" "TLML" "ULML" "VLML" "QLML" "PRECSNO" "PARDFLAND" "PARDRLAND" "PS" "SWGDN" "LWGAB" "TOTSCATAU" "TOTEXTTAU" "GWETROOT" "WETDAYS" "V850" "U850")
endyear=2021 #Use to remove end year
endmonth=08 #This is the last month of partial to full MERRA-2 data

###########################
#Set file paths to MERRA2 archive
fdirIn=/discover/nobackup/projects/gmao/merra2/data/products/
fdirOut=/archive/u/bpoulter/MERRA2/
fdirInCru=/home/bpoulter/MERRA2/LSM

#Remove the $endyear files to avoid overwriting problems
#NEVER delete $fdirOut/'prep/dailybyday'/
rm $fdirOut/'prep/6hourlybyyear'/*$endyear*
rm $fdirOut/'prep/dailybyyear'/*$endyear*
rm $fdirOut/prep/daily-allYear/*
rm $fdirOut/'prep/monthly-allYear'/*
rm $fdirOut/final/*

#Get land mask
cdo selvar,LWI $fdirIn/MERRA2_400/Y2020/M04/MERRA2_400.inst3_3d_aer_Nv.20200430.nc4 $fdirOut/MERRA2-LWI.nc4

###########################
#Process surface flux files
for flxfile in $fdirIn/MERRA2_*/Y*/M??/MERRA2*tavg1_2d_flx_Nx*
do
        #Get just the file name and strip the main file name
        fileFull=$(basename $flxfile)
        fileDate=${fileFull#*.*.*}
	fileYear=${fileDate%????????}
        echo $flxfile $fileDate

	#Extract the flx variables
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-PRECTOTCORR_'$fileDate ]]
        then
		#Select/average to 6hourly/average to daily/remove hourly
                cdo selvar,PRECTOTCORR $flxfile $fdirOut/'prep/hourlybyday'/'MERRA2-PRECTOTCORR_'$fileDate
		cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-PRECTOTCORR_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-PRECTOTCORR_'$fileDate
		cdo mulc,3600 $fdirOut/'prep/hourlybyday'/'MERRA2-PRECTOTCORR_'$fileDate $fdirOut/'prep/hourlybyday'/'MERRA2-PRECTOTCORR_tmp'$fileDate
		cdo daysum $fdirOut/'prep/hourlybyday'/'MERRA2-PRECTOTCORR_tmp'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-PRECTOTCORR_'$fileDate 
		rm $fdirOut/'prep/hourlybyday'/'MERRA2-PRECTOTCORR_'*
        fi
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-TLML_'$fileDate ]]
        then
                #Select/average to 6hourly/average to daily/remove hourly
                cdo selvar,TLML $flxfile $fdirOut/'prep/hourlybyday'/'MERRA2-TLML_'$fileDate
                cdo subc,273.15 $fdirOut/'prep/hourlybyday'/'MERRA2-TLML_'$fileDate $fdirOut/'prep/hourlybyday'/'MERRA2-TLML_tmp'$fileDate
                cdo timselmean,6  $fdirOut/'prep/hourlybyday'/'MERRA2-TLML_tmp'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-TLML_'$fileDate
                cdo daymean $fdirOut/'prep/hourlybyday'/'MERRA2-TLML_tmp'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-TLML_'$fileDate
		rm $fdirOut/'prep/hourlybyday'/'MERRA2-TLML_'*
        fi
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-ULML_'$fileDate ]]
        then
                #Select/average to 6hourly/average to daily/remove hourly
                cdo selvar,ULML $flxfile $fdirOut/'prep/hourlybyday'/'MERRA2-ULML_'$fileDate
                cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-ULML_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-ULML_'$fileDate
                cdo daymean $fdirOut/'prep/hourlybyday'/'MERRA2-ULML_'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-ULML_'$fileDate
                rm $fdirOut/'prep/hourlybyday'/'MERRA2-ULML_'$fileDate
        fi
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-VLML_'$fileDate ]]
        then
                #Select/average to 6hourly/average to daily/remove hourly
                cdo selvar,VLML $flxfile $fdirOut/'prep/hourlybyday'/'MERRA2-VLML_'$fileDate
                cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-VLML_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-VLML_'$fileDate
                cdo daymean $fdirOut/'prep/hourlybyday'/'MERRA2-VLML_'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-VLML_'$fileDate
                rm $fdirOut/'prep/hourlybyday'/'MERRA2-VLML_'$fileDate
        fi
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-QLML_'$fileDate ]]
        then
                #Select/average to 6hourly/average to daily/remove hourly
                cdo selvar,QLML $flxfile $fdirOut/'prep/hourlybyday'/'MERRA2-QLML_'$fileDate
                cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-QLML_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-QLML_'$fileDate
                cdo daymean $fdirOut/'prep/hourlybyday'/'MERRA2-QLML_'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-QLML_'$fileDate
                rm $fdirOut/'prep/hourlybyday'/'MERRA2-QLML_'$fileDate
        fi
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-PRECSNO_'$fileDate ]]
        then
                #Select/average to 6hourly/average to daily/remove hourly
                cdo selvar,PRECSNO $flxfile $fdirOut/'prep/hourlybyday'/'MERRA2-PRECSNO_'$fileDate
                cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-PRECSNO_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-PRECSNO_'$fileDate
                cdo mulc,3600 $fdirOut/'prep/hourlybyday'/'MERRA2-PRECSNO_'$fileDate $fdirOut/'prep/hourlybyday'/'MERRA2-PRECSNO_tmp'$fileDate
                cdo daysum $fdirOut/'prep/hourlybyday'/'MERRA2-PRECSNO_tmp'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-PRECSNO_'$fileDate
		rm $fdirOut/'prep/hourlybyday'/'MERRA2-PRECSNO_'*
        fi
done

#Process land surface forcing files
for lndfile in $fdirIn/MERRA2_*/Y*/M??/MERRA2*tavg1_2d_lnd_Nx*
do
        #Get just the file name and strip the main file name
        fileFull=$(basename $lndfile)
        fileDate=${fileFull#*.*.*}
        fileYear=${fileDate%????????}
        echo $lndfile $fileDate

        #Extract the lnd variables
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-PARDFLAND_'$fileDate ]]
        then
                #Select/average to 6hourly/average to daily/remove hourly
                cdo selvar,PARDFLAND $lndfile $fdirOut/'prep/hourlybyday'/'MERRA2-PARDFLAND_'$fileDate
                cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-PARDFLAND_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-PARDFLAND_'$fileDate
                cdo mulc,3600 $fdirOut/'prep/hourlybyday'/'MERRA2-PARDFLAND_'$fileDate $fdirOut/'prep/hourlybyday'/'MERRA2-PARDFLAND_tmp'$fileDate
		cdo daysum $fdirOut/'prep/hourlybyday'/'MERRA2-PARDFLAND_tmp'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-PARDFLAND_'$fileDate
                rm $fdirOut/'prep/hourlybyday'/'MERRA2-PARDFLAND_'*
        fi
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-PARDRLAND_'$fileDate ]]
        then
                #Select/average to 6hourly/average to daily/remove hourly
                cdo selvar,PARDRLAND $lndfile $fdirOut/'prep/hourlybyday'/'MERRA2-PARDRLAND_'$fileDate
                cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-PARDRLAND_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-PARDRLAND_'$fileDate
                cdo mulc,3600 $fdirOut/'prep/hourlybyday'/'MERRA2-PARDRLAND_'$fileDate $fdirOut/'prep/hourlybyday'/'MERRA2-PARDRLAND_tmp'$fileDate
		cdo daysum $fdirOut/'prep/hourlybyday'/'MERRA2-PARDRLAND_tmp'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-PARDRLAND_'$fileDate
                rm $fdirOut/'prep/hourlybyday'/'MERRA2-PARDRLAND_'*
        fi
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-GWETROOT_'$fileDate ]]
        then
                #Select/average to 6hourly/average to daily/remove hourly
                cdo selvar,GWETROOT $lndfile $fdirOut/'prep/hourlybyday'/'MERRA2-GWETROOT_'$fileDate
                cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-GWETROOT_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-GWETROOT_'$fileDate
                cdo mulc,1 $fdirOut/'prep/hourlybyday'/'MERRA2-GWETROOT_'$fileDate $fdirOut/'prep/hourlybyday'/'MERRA2-GWETROOT_tmp'$fileDate
                cdo daymean $fdirOut/'prep/hourlybyday'/'MERRA2-GWETROOT_tmp'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-GWETROOT_'$fileDate
                rm $fdirOut/'prep/hourlybyday'/'MERRA2-GWETROOT_'*
        fi
done

#Process single level diagnostics
for slvfile in $fdirIn/MERRA2_*/Y*/M??/MERRA2*tavg1_2d_slv_Nx*
do
        #Get just the file name and strip the main file name
        fileFull=$(basename $slvfile)
        fileDate=${fileFull#*.*.*}
        fileYear=${fileDate%????????}
        echo $slvfile $fileDate

        #Extract the slv variables
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-PS_'$fileDate ]]
        then
                #Select/average to 6hourly/average to daily/remove hourly
                cdo selvar,PS $slvfile $fdirOut/'prep/hourlybyday'/'MERRA2-PS_'$fileDate
                cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-PS_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-PS_'$fileDate
                cdo daymean $fdirOut/'prep/hourlybyday'/'MERRA2-PS_'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-PS_'$fileDate
                rm $fdirOut/'prep/hourlybyday'/'MERRA2-PS_'$fileDate
        fi
done

#Process radiation diagnostics
for radfile in $fdirIn/MERRA2_*/Y*/M??/MERRA2*tavg1_2d_rad_Nx*
do
        #Get just the file name and strip the main file name
        fileFull=$(basename $radfile)
        fileDate=${fileFull#*.*.*}
        fileYear=${fileDate%????????}
        echo $radfile $fileDate

        #Extract the rad variables
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-SWGDN_'$fileDate ]]
        then
                #Select/average to 6hourly/average to daily/remove hourly
                cdo selvar,SWGDN $radfile $fdirOut/'prep/hourlybyday'/'MERRA2-SWGDN_'$fileDate
                cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-SWGDN_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-SWGDN_'$fileDate
                cdo mulc,3600 $fdirOut/'prep/hourlybyday'/'MERRA2-SWGDN_'$fileDate $fdirOut/'prep/hourlybyday'/'MERRA2-SWGDN_tmp'$fileDate
		cdo daysum $fdirOut/'prep/hourlybyday'/'MERRA2-SWGDN_tmp'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-SWGDN_'$fileDate
                rm $fdirOut/'prep/hourlybyday'/'MERRA2-SWGDN_'*
        fi
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-LWGAB_'$fileDate ]]
        then
                #Select/average to 6hourly/average to daily/remote hourly
                cdo selvar,LWGAB $radfile $fdirOut/'prep/hourlybyday'/'MERRA2-LWGAB_'$fileDate
                cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-LWGAB_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-LWGAB_'$fileDate
                cdo mulc,3600 $fdirOut/'prep/hourlybyday'/'MERRA2-LWGAB_'$fileDate $fdirOut/'prep/hourlybyday'/'MERRA2-LWGAB_tmp'$fileDate
                cdo daysum $fdirOut/'prep/hourlybyday'/'MERRA2-LWGAB_tmp'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-LWGAB_'$fileDate
                rm $fdirOut/'prep/hourlybyday'/'MERRA2-LWGAB_'*
        fi
done

#Select AOD variables
for aodfile in $fdirIn/MERRA2_*/Y*/M??/MERRA2*tavg1_2d_aer_Nx*
do
        #
        fileFull=$(basename $aodfile)
        fileDate=${fileFull#*.*.*}
        echo $aodfile $fileDate
        
	#Extract the AOD variables
	if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-TOTSCATAU_'$fileDate ]]
        then
                cdo selvar,TOTSCATAU $aodfile $fdirOut/'prep/hourlybyday'/'MERRA2-TOTSCATAU_'$fileDate
		cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-TOTSCATAU_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-TOTSCATAU_'$fileDate
		cdo daymean $fdirOut/'prep/hourlybyday'/'MERRA2-TOTSCATAU_'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-TOTSCATAU_'$fileDate
        fi
        if [[ ! -f $fdirOut/'prep/dailybyday'/'MERRA2-TOTEXTTAU_'$fileDate ]]
        then
                cdo selvar,TOTEXTTAU $aodfile $fdirOut/'prep/hourlybyday'/'MERRA2-TOTEXTTAU_'$fileDate
                cdo timselmean,6 $fdirOut/'prep/hourlybyday'/'MERRA2-TOTEXTTAU_'$fileDate $fdirOut/'prep/6hourlybyday'/'MERRA2-TOTEXTTAU_'$fileDate
		cdo daymean $fdirOut/'prep/hourlybyday'/'MERRA2-TOTEXTTAU_'$fileDate $fdirOut/'prep/dailybyday'/'MERRA2-TOTEXTTAU_'$fileDate
        fi
done

#################################################
#Merge 6hourly daily files to 6hourly yearly files
for var in ${varList[@]};
do
	for (( year = 1980; year <= $endyear; year++ ));
	do
		echo $fdirOut/'prep/6hourlybyyear'/'MERRA2-'$var'_'$year'.nc4'
		if [[ ! -f $fdirOut/'prep/6hourlybyyear'/'MERRA2-'$var'_'$year'.nc4' ]]
		then
	        	cdo mergetime $fdirOut/'prep/6hourlybyday'/'MERRA2-'$var'_'$year????* $fdirOut/'prep/6hourlybyyear'/'MERRA2-'$var'_'$year'.nc4'
		fi
	done
done

#Make daily max temperature from 6 hourly file
for (( year = 1980; year <= $endyear; year++ ));
do
	echo $fdirOut/'prep/dailybyyear'/'MERRA2-TLML-MAX_'$year'.nc4'
	if [[ ! -f $fdirOut/'prep/dailybyyear'/'MERRA2-TLML-MAX_'$year'.nc4' ]]
        then
		cdo daymax $fdirOut/'prep/6hourlybyyear'/'MERRA2-TLML_'$year'.nc4' $fdirOut/'prep/dailybyyear'/'MERRA2-TLML-MAX_'$year'.nc4'
	fi
done

###################################################
#Merge daily max temperature to full 1980-endyear time series
if [[ ! -f $fdirOut/'prep/daily-allYear/MERRA2-TLML-MAX_1980-'$endyear'.nc4' ]]
then
	cdo mergetime $fdirOut/'prep/dailybyyear'/'MERRA2-TLML-MAX_'*'.nc4' $fdirOut/'prep/daily-allYear/MERRA2-TLML-MAX_1980-'$endyear'.nc4'
fi

#Merge daily by daily files to daily by yearly, then to full time series
for var in ${varList[@]};
do
	for (( year = 1980; year <= $endyear; year++ ));
	do
		echo $fdirOut/'prep/dailybyyear'/'MERRA2-'$var'_'$year'.nc4'
		if [[ ! -f $fdirOut/'prep/dailybyyear'/'MERRA2-'$var'_'$year'.nc4' ]]
		then
			cdo mergetime $fdirOut/'prep/dailybyday'/'MERRA2-'$var'_'$year????* $fdirOut/'prep/dailybyyear'/'MERRA2-'$var'_'$year'.nc4'
		fi
	done
	cdo mergetime $fdirOut/'prep/dailybyyear'/'MERRA2-'$var'_'* $fdirOut/'prep/daily-allYear'/'MERRA2-'$var'_1980-'$endyear'.nc4'
done

#Copy KBDI files to NOBACKUP so that SLURM can run on merging these w S2S
cp /archive/u/bpoulter/MERRA2/prep/daily-allYear/MERRA2-PRECTOTCORR_1980-$endyear'.nc4' /discover/nobackup/bpoulter/MERRA2/prep/daily-allYear/MERRA2-PRECTOTCORR_1980-$endyear'.nc4'
cp /archive/u/bpoulter/MERRA2/prep/daily-allYear/MERRA2-TLML_1980-$endyear'.nc4' /discover/nobackup/bpoulter/MERRA2/prep/daily-allYear/MERRA2-TLML_1980-$endyear'.nc4'
cp /archive/u/bpoulter/MERRA2/prep/daily-allYear/MERRA2-TLML-MAX_1980-$endyear'.nc4' /discover/nobackup/bpoulter/MERRA2/prep/daily-allYear/MERRA2-TLML-MAX_1980-$endyear'.nc4'

#Merge daily to monthly time series
cdo monsum $fdirOut/'prep/daily-allYear'/'MERRA2-PRECTOTCORR_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-PRECTOTCORR_1980-'$endyear'_tmp.nc4'
cdo monmean $fdirOut/'prep/daily-allYear'/'MERRA2-TLML_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-TLML_1980-'$endyear'_tmp.nc4'
cdo monmean $fdirOut/'prep/daily-allYear'/'MERRA2-ULML_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-ULML_1980-'$endyear'_tmp.nc4'
cdo monmean $fdirOut/'prep/daily-allYear'/'MERRA2-VLML_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-VLML_1980-'$endyear'_tmp.nc4'
cdo monmean $fdirOut/'prep/daily-allYear'/'MERRA2-QLML_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-QLML_1980-'$endyear'_tmp.nc4'
cdo monsum $fdirOut/'prep/daily-allYear'/'MERRA2-PRECSNO_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-PRECSNO_1980-'$endyear'_tmp.nc4'
cdo monsum $fdirOut/'prep/daily-allYear'/'MERRA2-PARDFLAND_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-PARDFLAND_1980-'$endyear'_tmp.nc4'
cdo monsum $fdirOut/'prep/daily-allYear'/'MERRA2-PARDRLAND_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-PARDRLAND_1980-'$endyear'_tmp.nc4'
cdo monmean $fdirOut/'prep/daily-allYear'/'MERRA2-PS_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-PS_1980-'$endyear'_tmp.nc4'
cdo monsum $fdirOut/'prep/daily-allYear'/'MERRA2-SWGDN_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-SWGDN_1980-'$endyear'_tmp.nc4'
cdo monsum $fdirOut/'prep/daily-allYear'/'MERRA2-LWGAB_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-LWGAB_1980-'$endyear'_tmp.nc4'
cdo monmean $fdirOut/'prep/daily-allYear'/'MERRA2-GWETROOT_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-GWETROOT_1980-'$endyear'_tmp.nc4'
cdo monmean $fdirOut/'prep/daily-allYear'/'MERRA2-TOTSCATAU_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-TOTSCATAU_1980-'$endyear'_tmp.nc4'
cdo monmean $fdirOut/'prep/daily-allYear'/'MERRA2-TOTEXTTAU_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-TOTEXTTAU_1980-'$endyear'_tmp.nc4'

#################################################
#Calculate wetdays and wetmonths
cdo gtc,0.1 $fdirOut/'prep/daily-allYear'/'MERRA2-PRECTOTCORR_1980-'$endyear'.nc4' $fdirOut/'prep/daily-allYear'/'MERRA2-RAINDAY_1980-'$endyear'.nc4'
cdo monsum $fdirOut/'prep/daily-allYear'/'MERRA2-RAINDAY_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-WETDAYS_1980-'$endyear'_prectotcorr.nc4'
cdo chname,PRECTOTCORR,wet $fdirOut/'prep/monthly-allYear'/'MERRA2-WETDAYS_1980-'$endyear'_prectotcorr.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-WETDAYS_1980-'$endyear'_tmp.nc4' 
rm $fdirOut/'prep/daily-allYear'/'MERRA2-RAINDAY_1980-'$endyear'.nc4'
rm $fdirOut/'prep/monthly-allYear'/'MERRA2-WETDAYS_1980-'$endyear'_prectotcorr.nc4'

#################################################
#Create full year for last year by recycling previous year remaining MONTHS for missing current year
#NEED TO UPDATE THIS EACH YEAR
#Monthly recycling
for var in ${varList[@]};
do
	#Leave these - selects full year, setyear to current, splitmonths to select/merge
        cdo selyear,$(($endyear-1)) $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'_tmp.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$(($endyear-1))'.nc4'
        cdo setyear,$endyear $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$(($endyear-1))'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'.nc4'
        cdo splitmon $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear

	#Cut to endmonth (includes endmonth)
	ncks -d time,1980-01-16T12:00:00,$endyear-$endmonth-16T12:00:00 $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'_tmp.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'_tmp2.nc4'
        
	#Merge previous year following months, so if endmonth = 03, then merge 04 onwards
	if [ $endmonth == '03' ]
	then
	cdo mergetime $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'_tmp2.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'04.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'05.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'06.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'07.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'08.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'09.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'10.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'11.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'12.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'.nc4'
	fi

        if [ $endmonth == '05' ]
        then
        cdo mergetime $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'_tmp2.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'06.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'07.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'08.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'09.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'10.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'11.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'12.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'.nc4'
        fi

        if [ $endmonth == '06' ]
        then
        cdo mergetime $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'_tmp2.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'07.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'08.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'09.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'10.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'11.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'12.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'.nc4'
        fi

        if [ $endmonth == '07' ]
        then
        cdo mergetime $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'_tmp2.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'08.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'09.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'10.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'11.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'12.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'.nc4'
        fi

       if [ $endmonth == '08' ]
        then
        cdo mergetime $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'_tmp2.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'09.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'10.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'11.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'12.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'.nc4'
        fi

	if [ $endmonth == '11' ]
        then
	cdo mergetime $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'_tmp2.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear'12.nc' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'.nc4'
	fi

	#Leave alone
	rm $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$(($endyear-1))'.nc4'
        rm $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_'$endyear*
	rm $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'_tmp.nc4'
	rm $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'_tmp2.nc4'
done

#################################################
#Fix units, clear history and variable names for monthly
for var in ${varList[@]};
do
	ncatted -O -h -a,global,d,, $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-'$var'_1980-'$endyear'.nc4'
done
cdo chunit,K,C $fdirOut/'prep/monthly-allYear'/'MERRA2-TLML_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-TLML_1980-'$endyear'_C.nc4'
cdo chunit,kg/m-2/s-1,mm $fdirOut/'prep/monthly-allYear'/'MERRA2-PRECTOTCORR_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-PRECTOTCORR_1980-'$endyear'_mm.nc4'
cdo chunit,kg/m-2/s-1,days $fdirOut/'prep/monthly-allYear'/'MERRA2-WETDAYS_1980-'$endyear'.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-WETDAYS_1980-'$endyear'_days.nc4'
mv $fdirOut/'prep/monthly-allYear'/'MERRA2-TLML_1980-'$endyear'_C.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-TLML_1980-'$endyear'.nc4'
mv $fdirOut/'prep/monthly-allYear'/'MERRA2-PRECTOTCORR_1980-'$endyear'_mm.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-PRECTOTCORR_1980-'$endyear'.nc4'
mv $fdirOut/'prep/monthly-allYear'/'MERRA2-WETDAYS_1980-'$endyear'_days.nc4' $fdirOut/'prep/monthly-allYear'/'MERRA2-WETDAYS_1980-'$endyear'.nc4'

#################################################
#Project monthly to 0.5 degree, and uncompress
cdo -b F32 -f nc1 remapcon,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-PRECTOTCORR_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-PRECTOTCORR_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapbil,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-TLML_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-TLML_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapbil,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-ULML_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-ULML_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapbil,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-VLML_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-VLML_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapbil,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-QLML_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-QLML_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapcon,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-PRECSNO_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-PRECSNO_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapcon,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-PARDFLAND_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-PARDFLAND_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapcon,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-PARDRLAND_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-PARDRLAND_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapbil,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-PS_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-PS_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapcon,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-SWGDN_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-SWGDN_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapcon,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-LWGAB_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-LWGAB_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapbil,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-WETDAYS_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-WETDAYS_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapbil,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-GWETROOT_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-GWETROOT_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapbil,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-TOTSCATAU_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-TOTSCATAU_1980-'$endyear'.nc'
cdo -b F32 -f nc1 remapbil,$fdirInCru/cru05deg.txt $fdirOut/'prep/monthly-allYear'/'MERRA2-TOTEXTTAU_1980-'$endyear'.nc4' $fdirOut/'final/monthly-allYear'/'MERRA2-TOTEXTTAU_1980-'$endyear'.nc'
