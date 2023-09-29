library(terra)
library(dplyr)

#retrieve spectra

path <- 'c:/Users/bryce/OneDrive/Documents/Current Projects/LPJ/output/global'

rtr <- rast(file.path(path, 'LPJ_retrieved_reflectance_perm_July_2020.img'))
rfl  <- rast(file.path(path, 'LPJ_reflectance_resv_perm_July_2020'))



lats <- seq(83,-58.5, -0.5) # lats reversed
lons <- seq(-180, 180, 0.5)
spectra.coords <- data.frame(x = c(138, 256, 385, 428, 190, 142, 416, 141),
                             y = c(66, 184, 122, 56, 100, 90, 189, 60))

df <- data.frame()
for (m in c('July')) {
  for (i in seq(dim(spectra.coords)[1])) {
    y <- spectra.coords[i,2]
    x <- spectra.coords[i,1]
    lat <- lats[y]
    lon <- lons[x]
    df <- rbind.data.frame(df,
                           cbind.data.frame(Month = m, lon=rep(lon), lat=rep(lat), reflectance=as.numeric(rfl[y,x, ]), retrieved=as.numeric(rtr[y, x, ]))
    )
  }
}

