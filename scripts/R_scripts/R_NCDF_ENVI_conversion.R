library(terra)
library(ncdf4)
'%!in%' <- function(x,y)!('%in%'(x,y))

# data
data.path <- commandArgs(trailingOnly = T)
# data.path <- "c:/Users/bryce/OneDrive/Documents/Current Projects/LPJ/output/global/test"


# all files
dirs <- list.dirs(data.path)
all.files <- list.files(data.path, full.names = T, include.dirs = F); 
all.files <- all.files[all.files %!in% dirs]; #all.files
cat('\nall files:\n'); all.files

# nc files
nc.files <- all.files[grep(all.files, pattern = '\\.nc')];
cat('\nnc files:\n'); nc.files

# envi files
envi.files <- all.files[grep(all.files, pattern = '\\.nc', invert = T)]; #envi.files
envi.files <- envi.files[grep(envi.files, pattern = '\\.hdr', invert = T)]; #envi.files
envi.files.no.ext <- envi.files[grep(envi.files, pattern = '\\.', invert = T)]; #envi.files
envi.files <- envi.files[grep(envi.files, pattern = '\\.img')]; 
envi.files <- c(envi.files, envi.files.no.ext); 
cat('\nenvi files:\n'); envi.files

# create dirs
if (!dir.exists(file.path(data.path, 'ENVI'))) {dir.create(file.path(data.path, 'ENVI'))}
if (!dir.exists(file.path(data.path, 'NCDF'))) {dir.create(file.path(data.path, 'NCDF'))}


# Creates ENVI files for all ncdf files -------------------------------------------------------
cat('\n')
if (length(nc.files)!=0) {
  for (i in nc.files) {
    # obtain the file name
    ext <- '.nc'
    f.name.no.ext <- strsplit(tail(strsplit(i,split = '/')[[1]], n=1),
                              split = "\\.nc")[[1]][1]
    # obtain the data
    data <- rast(i)
    
    # add units
    if (grepl('reflectance', i)) {units(data) <- 'Fraction'}
    if (grepl('radiance', i)) {units(data) <- 'W sr^-1 m^-2'}
    if (grepl('comp', i)) {units(data) <- 'Percent Difference'}
    
    # add names
    names(data) <- seq(400,2500,10)
  
    #export as ENVI
    writeRaster(data,
                filename = file.path(data.path, 'ENVI', f.name.no.ext), 
                gdal=c("COMPRESS=NONE"), filetype = 'ENVI',
                overwrite = T, 
                NAflag = -9999)
    cat('wrote: ', file.path(data.path, 'ENVI', f.name.no.ext),'\n')
    file.copy(i, to = file.path(data.path, 'NCDF'))
  }
  file.remove(list.files(file.path(data.path,'ENVI'), recursive = T, full.names = T, pattern = '*.aux'))
  file.remove(nc.files)
}

# Creates NCDF files for all envi files -------------------------------------------------------
cat('\n')
wavewidth <- 10
x <- ncdim_def("lon", "degrees_east",  seq(-179.75, 179.75, 0.5))
y <- ncdim_def("lat", "degrees_north", rev(seq(-89.75, 89.75, 0.5)))
bin <- ncdim_def("wavelength", paste("wavelength_by_every_", wavewidth,'_nm_from_400-2500_nm', sep=""), seq(400,2500,wavewidth))

if (length(envi.files)!=0) {
  for (i in envi.files) {
    # obtain the file name
    f.name.no.ext <- strsplit(tail(strsplit(i,split = '/')[[1]], n=1),
                              split = "\\.img")[[1]][1]
  
    # obtain the data
    data <- rast(i); print(dim(data))
    names(data) <- seq(400,2500,10)
 
    # add units
    if (grepl('retrieve', i)) {
      varNC <- ncvar_def('Retrieved reflectance', 'fraction', list(x,y,bin), prec="double")
      ncnew <- nc_create(file.path(data.path, 'NCDF', paste0(f.name.no.ext,'.nc')), varNC, force_v4=T)    
      ncvar_put(nc = ncnew, varid = varNC, vals = as.array(t(data)))
      ncatt_put(nc = ncnew, varid = 0, attname = 'project', attval = 'Simulating global imaging spectroscopy')
      ncatt_put(nc = ncnew, varid = 0, attname = 'model', attval = 'LPJ-PROSAIL')
      ncatt_put(nc = ncnew, varid = 0, attname = 'contact', attval = 'benjamin.poulter@nasa.gov & bryce.currey@montana.edu')
      ncatt_put(nc = ncnew, varid = 0, attname = 'institution', attval = 'NASA GSFC')
      nc_close(ncnew)

    } else if (grepl('reflectance', i)) {
      varNC <- ncvar_def('Reflectance', 'fraction', list(x,y,bin), prec="double")
      ncnew <- nc_create(file.path(data.path, 'NCDF', paste0(f.name.no.ext,'.nc')), varNC, force_v4=T)    
      ncvar_put(nc = ncnew, varid = varNC, vals = as.array(data))
      ncatt_put(nc = ncnew, varid = 0, attname = 'project', attval = 'Simulating global imaging spectroscopy')
      ncatt_put(nc = ncnew, varid = 0, attname = 'model', attval = 'LPJ-PROSAIL')
      ncatt_put(nc = ncnew, varid = 0, attname = 'contact', attval = 'benjamin.poulter@nasa.gov & bryce.currey@montana.edu')
      ncatt_put(nc = ncnew, varid = 0, attname = 'institution', attval = 'NASA GSFC')
      nc_close(ncnew)
}
    
    if (grepl('radiance', i)) {
      writeCDF(data,
               filename = file.path(data.path, 'NCDF', paste0(f.name.no.ext,'.nc')), 
               varname = 'TOA Radaince',
               unit = 'W sr^-1 m^-2',
               compression=NA,
		zname = 'wavelength',
               overwrite = T, 
               #missval = NaN,
               prec='double')
    }
    
    if (grepl('comp', i)) {
      writeCDF(data,
               filename = file.path(data.path, 'NCDF', paste0(f.name.no.ext,'.nc')), 
               varname = 'Percent Difference',
               unit = 'Percent',
               compression=NA,
		zname = 'wavelength',
               overwrite = T, 
               missval = NaN,
               prec='double')
    }

    cat('wrote: ', file.path(data.path, 'NCDF', paste0(f.name.no.ext,'.nc')),'\n')
    file.copy(i, to = file.path(data.path, 'ENVI'))
    file.copy(file.path(data.path, paste0(f.name.no.ext,'.hdr')), to = file.path(data.path, 'ENVI'))
  }
  file.remove(envi.files)
  file.remove(list.files(file.path(data.path), pattern = '\\.hdr', full.names = T))
}
