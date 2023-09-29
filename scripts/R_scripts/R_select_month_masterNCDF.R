library(ncdf4)
library(dplyr)

# path
path <- '/discover/nobackup/bcurrey/hypertrace_simulations/data/'
args <- commandArgs(trailingOnly = T)
# select the month to subset
month <- as.numeric(args[1])
fn <- args[2]

# subset the data
data <- nc_open(file.path(path, 'MASTER', fn))
data
varname <- attributes(data$var)$names[1]; print(varname)
data.subset <- ncvar_get(data, varname)[,,,month]
print(dim(data.subset))
nc_close(data)

# Set up ncdf dims
year <- 2020
wavewidth <- 10
nbins <- 211
lon <- ncdim_def( "lon", "degrees_east", seq(-179.75, 179.75, 0.5))
lat <- ncdim_def( "lat", "degrees_north", rev(seq(-89.75, 89.75, 0.5)))
bin <- ncdim_def( "wavelength", paste0("wavelength_by_every_", wavewidth,'_nm_from_400-2500_nm'), seq(400,2500,wavewidth))
varNC <- ncvar_def(varname, 'fraction', list(lon,lat,bin), longname=varname, prec="float")


print('creating ncdf')
# creat new ncdf
ncnew <- nc_create(file.path(path, paste0("LPJ_",varname,'_',year,'_',month,".nc")), varNC, force_v4 = T)    
ncvar_put(nc = ncnew, varid = varNC, vals = data.subset)
ncatt_put(nc = ncnew, varid = 0, attname = 'project', attval = 'Simulating global imaging spectroscopy')
ncatt_put(nc = ncnew, varid = 0, attname = 'model', attval = 'LPJ-PROSAIL')
ncatt_put(nc = ncnew, varid = 0, attname = 'contact', attval = 'benjamin.poulter@nasa.gov & bryce.currey@montana.edu')
ncatt_put(nc = ncnew, varid = 0, attname = 'institution', attval = 'NASA GSFC')
nc_close(ncnew)

cat(paste0("LPJ_",varname,'_',year,'_',month,".nc"))
