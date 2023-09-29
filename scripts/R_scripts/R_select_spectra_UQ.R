library(terra)
library(dplyr)
library(tidyr)
library(readr)
library(ncdf4)

#retrieve spectra
path <- 'c:/Users/bryce/onedrive/Documents/current projects/LPJ/output/global'

lats <- seq(83,-58.5, -0.5) # lats reversed, unless transposed
lons <- seq(-180, 180, 0.5)
spectra.coords <- data.frame(x = c(138, 256, 385, 428, 190, 142, 416, 141),
                             y = c(66, 184, 122, 56, 100, 90, 189, 60))
df <- data.frame()

rtr.files <- list.files(file.path(path, 'test'), pattern = '*retrieved_reflectance*');
rfl.files <- list.files(file.path(path, 'test'), pattern = 'reflectance_resv'); 
# rtr.files <- list.files(file.path(path, 'test'), pattern = 'TOA'); 

for (f in seq(length(rfl.files))) {
  file.end <- tail(strsplit(rfl.files[f], '_')[[j]], n=1)
  mon <- switch(file.end,
                '1.nc' = 'January', '2.nc' = 'February', '3.nc' = 'March', '4.nc' = 'April', 
                '5.nc' = 'May', '6.nc' = 'June', '7.nc' = 'July', '8.nc' = 'August', 
                '9.nc' = 'September', '10.nc' = 'October', '11.nc' = 'November', '12.nc' = 'December')
  for (i in seq(dim(spectra.coords)[1])) {
    y <- spectra.coords[i,2]
    x <- spectra.coords[i,1]
    lat <- lats[y]
    lon <- lons[x]
    
    rfl.nc <- nc_open(file.path(path, 'test', rfl.files[j]))
    rfl  <- ncvar_get(rfl.nc, attributes(rfl.nc$var)$names[1])
    rtr.nc <- nc_open(file.path(path, 'test', rtr.files[j]))
    rtr <- ncvar_get(rtr.nc, attributes(rtr.nc$var)$names[2])
    
    rfl.df <- cbind.data.frame(Id = i, Month = mon, lon=lon, lat=lat, Variable = 'Reflectance', t(as.numeric(rfl[x,y, ])))
    rtr.df <- cbind.data.frame(Id = i, Month = mon, lon=lon, lat=lat, Variable = 'Retrieval', t(as.numeric(rtr[,x,y])))
    df <- rbind.data.frame(df, rfl.df,rtr.df)
  }
}
names(df) <- c('ID', 'Month', 'Lon', 'Lat', 'Variable', paste0(seq(400,2500,10),'nm'))
write_csv(df, file.path(path, 'test', 'LPJ_reflectance_retrievals_for_UQ_test.csv'))
