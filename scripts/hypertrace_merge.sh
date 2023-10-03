#!/bin/bash

#SBATCH --job-name=Merge
#SBATCH --time=02:30:00
#SBATCH --account=s3673
#SBATCH --mail-user brycecurrey93@gmail.com
#SBATCH --mail-type=ALL

module load cdo
module load nco

# variables passed from LPJ_hypertrace_routine.sh
ncdfs=$ncdfDir
version=$version
year=$year

# Create temp folder for processing vars
tmp="$ncdfs/temp/"
mkdir tmp

# move monthly files to tmp.
mv $ncdfs/lpj-prosail_levelD_TOA-radiance_${version}_*_${year}.nc $tmp/
mv $ncdfs/lpj-prosail_levelE_retrieved-HDR_${version}_*_${year}.nc $tmp/

# cat the individual files
cdo cat $tmp/lpj-prosail_levelD_TOA-radiance_${version}_*_${year}.nc $tmp/temp_rad1.nc
cdo cat $tmp/lpj-prosail_levelE_retrieved-HDR_${version}_*_${year}.nc $tmp/temp_rtr1.nc

# mult by scale factor
cdo mulc,100 $tmp/temp_rad1.nc $tmp/temp_rad2.nc
cdo mulc,10000 $tmp/temp_rtr1.nc $tmp/temp_rtr2.nc

# set variable as integer
ncap2 -s 'Radiance=int(Radiance)' $tmp/temp_rad2.nc $tmp/temp_rad3.nc
ncap2 -s 'HDR=int(HDR)' $tmp/temp_rtr2.nc $tmp/temp_rtr3.nc

# set scale factor
ncatted -a scale_factor,Radiance,o,f,0.01 $tmp/temp_rad3.nc $tmp/temp_rad4.nc 
ncatted -a scale_factor,HDR,o,f,0.0001 $tmp/temp_rtr3.nc $tmp/temp_rtr4.nc

# set time as integer
ncap2 -s 'time=int(time)' $tmp/temp_rad4.nc 
ncap2 -s 'time=int(time)' $tmp/temp_rtr4.nc 

# update attributes for Radiances
ncatted -a units,time,o,c,"Months since $year-01-01" $tmp/temp_rad4.nc
ncatted -a long_name,time,o,c,"Month" $tmp/temp_rad4.nc
ncatted -a calendar,time,o,c,"standard" $tmp/temp_rad4.nc

# update attributes for Retrievals
ncatted -a units,time,o,c,"Months since $year-01-01" $tmp/temp_rtr4.nc
ncatted -a long_name,time,o,c,"Month" $tmp/temp_rtr4.nc
ncatted -a calendar,time,o,c,"standard" $tmp/temp_rtr4.nc

# add a level 5 deflate compression factor
nccopy -d5 $tmp/temp_rad4.nc $ncdfs/lpj-prosail_levelD_TOA-radiance_${version}_m_${year}.nc
nccopy -d5 $tmp/temp_rtr4.nc $ncdfs/lpj-prosail_levele_retrieved-HDR_${version}_m_${year}.nc

# Remove monthly and temp files
rm $tmp -r
