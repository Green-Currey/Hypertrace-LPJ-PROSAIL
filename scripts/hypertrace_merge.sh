#!/bin/bash

#SBATCH --job-name=HT2015
#SBATCH --time=00:29:00
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
echo -e "Make /temp dir in $ncdfs"
tmp="$ncdfs/temp/"
mkdir $tmp

# move monthly files to tmp.
echo -e "Move files to temp dir"
mv $ncdfs/lpj-prosail_levelD_TOA-radiance_${version}_*_${year}.nc $tmp/.
mv $ncdfs/lpj-prosail_levelE_retrieved-HDR_${version}_*_${year}.nc $tmp/.

# cat the individual files
echo -e "Concatenate monthly files into annual file"
cdo cat $tmp/lpj-prosail_levelD_TOA-radiance_${version}_*_${year}.nc $tmp/temp_rad1.nc
cdo cat $tmp/lpj-prosail_levelE_retrieved-HDR_${version}_*_${year}.nc $tmp/temp_rtr1.nc

# mult by scale factor
echo -e "Add scaling factors"
cdo mulc,100 $tmp/temp_rad1.nc $tmp/temp_rad2.nc
cdo mulc,10000 $tmp/temp_rtr1.nc $tmp/temp_rtr2.nc

# set variable as integer
echo -e "Convert variables to short"
ncap2 -s 'Radiance=int(Radiance)' $tmp/temp_rad2.nc $tmp/temp_rad3.nc
ncap2 -s 'HDR=int(HDR)' $tmp/temp_rtr2.nc $tmp/temp_rtr3.nc

# set scale factor
echo -e "Set scale factor"
ncatted -a scale_factor,Radiance,o,f,0.01 $tmp/temp_rad3.nc $tmp/temp_rad4.nc 
ncatted -a scale_factor,HDR,o,f,0.0001 $tmp/temp_rtr3.nc $tmp/temp_rtr4.nc

# set time as integer
echo -e "Convert time to integer"
ncap2 -s 'time=int(time)' $tmp/temp_rad4.nc  $tmp/temp_rad5.nc 
ncap2 -s 'time=int(time)' $tmp/temp_rtr4.nc  $tmp/temp_rtr5.nc 

# update attributes for Radiances
echo -e "Update time dimension attrubutes"
ncatted -a units,time,o,c,"Months since $year-01-01" $tmp/temp_rad5.nc
ncatted -a long_name,time,o,c,"Month" $tmp/temp_rad5.nc
ncatted -a calendar,time,o,c,"standard" $tmp/temp_rad5.nc

# update attributes for Retrievals
ncatted -a units,time,o,c,"Months since $year-01-01" $tmp/temp_rtr5.nc
ncatted -a long_name,time,o,c,"Month" $tmp/temp_rtr5.nc
ncatted -a calendar,time,o,c,"standard" $tmp/temp_rtr5.nc

# add a level 5 deflate compression factor
echo -e "Deflate files"
nccopy -d5 $tmp/temp_rad5.nc $ncdfs/lpj-prosail_levelD_TOA-radiance_${version}_m_${year}.nc
nccopy -d5 $tmp/temp_rtr5.nc $ncdfs/lpj-prosail_levelE_retrieved-HDR_${version}_m_${year}.nc

# Remove monthly and temp files
echo -e "Remove /temp directory"
rm $tmp -r

echo -e "Complete."
