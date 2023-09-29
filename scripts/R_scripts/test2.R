library(ncdf4)
library(dplyr)

# path
path <- '/efs/bcurrey/LPJ_isofit_SBG/data/'
args <- commandArgs(trailingOnly = T)
# select the month to subset
month <- as.numeric(args[1])
fn <- args[2]

# subset the data
data <- nc_open(file.path(path, 'MASTER', fn))
data
varname <- attributes(data$var)$names[1]; print(varname)

year <- 2020
paste0("LPJ_",varname,'_',year,'_',month,".nc")
