# Libraries ---------------------------------------------------------------
packages <- c("tidyverse", "magrittr", "sf", "gridExtra", 'lwgeom',
              "assertthat", "purrr", "httr", 'zoo', "rvest", "lubridate", "RColorBrewer", "ggmap", "ggthemes", 'Hmisc')
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
  lapply(packages, library, character.only = TRUE, verbose = FALSE) 
} else {
  lapply(packages, library, character.only = TRUE, verbose = FALSE) 
  }

proj_ea <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"

# Raw data folders
prefix <- "data"
raw_prefix <- file.path(prefix, "raw")
us_prefix <- file.path(raw_prefix, "cb_2016_us_state_20m")
ecoregion_prefix <- file.path(raw_prefix, "ecoregions")
mtbs_prefix <- file.path(raw_prefix, "mtbs_fod_perimeter_data")

# Cleaned data output folders
bounds_crt <- file.path(prefix, "bounds")
ecoreg_crt <- file.path(bounds_crt, "ecoregions")
ecoregion_out <- file.path(ecoreg_crt, "us_eco_l3")

fire_dir <- file.path(prefix, "fire")
mtbs_dir <- file.path(fire_dir, "mtbs_fod_perimeter_data")

# Check if directory exists for all variable aggregate outputs, if not then create
var_dir <- list(prefix, raw_prefix, us_prefix, ecoregion_prefix, mtbs_prefix,
                bounds_crt, ecoreg_crt, fire_dir, ecoregion_out, fire_dir, mtbs_dir)
lapply(var_dir, function(x) if(!dir.exists(x)) dir.create(x, showWarnings = FALSE))
