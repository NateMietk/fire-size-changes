if (!exists("usa")){
  usa <- st_read(dsn = us_prefix, layer = "cb_2016_us_state_20m") %>%
    filter(!(NAME %in% c("Alaska", "Hawaii", "Puerto Rico"))) %>%
    st_transform(proj_ea) %>%  # e.g. US National Atlas Equal Area
    dplyr::select(STATEFP, STUSPS) %>%
    setNames(tolower(names(.)))
}

# Import the Level 1 Ecoregions
if (!exists('ecoreg_l1')) {
  if (!file.exists(file.path(ecoregion_out, 'us_eco_l1.gpkg'))) {
    
    ecoreg_l1 <- st_read(dsn = ecoregion_prefix, layer = "NA_CEC_Eco_Level1") %>%
      st_transform(st_crs(usa)) %>%  # e.g. US National Atlas Equal Area
      st_make_valid() %>%
      st_intersection(., st_union(usa)) %>%
      mutate(region = as.factor(if_else(NA_L1NAME %in% c("EASTERN TEMPERATE FORESTS",
                                                         "TROPICAL WET FORESTS",
                                                         "NORTHERN FORESTS"), "East",
                                        if_else(NA_L1NAME %in% c("NORTH AMERICAN DESERTS",
                                                                 "SOUTHERN SEMI-ARID HIGHLANDS",
                                                                 "TEMPERATE SIERRAS",
                                                                 "MEDITERRANEAN CALIFORNIA",
                                                                 "NORTHWESTERN FORESTED MOUNTAINS",
                                                                 "MARINE WEST COAST FOREST"), "West", "Central")))) %>%
      setNames(tolower(names(.)))
    
    st_write(ecoreg_l1, file.path(ecoregion_out, 'us_eco_l1.gpkg'),
             driver = 'GPKG', delete_layer = TRUE)
    
    # system(paste0("aws s3 sync ", prefix, " ", s3_base))
    
  } else {
    ecoreg_l1 <- sf::st_read(file.path(ecoregion_out, 'us_eco_l1.gpkg'))
  }
}

# Import the Level 3 Ecoregions
if (!exists('ecoreg_l3')) {
  if (!file.exists(file.path(ecoregion_out, 'us_eco_l3.gpkg'))) {

    ecoreg_plain <- st_read(dsn = ecoregion_prefix, layer = "us_eco_l3", quiet= TRUE) %>%
      st_transform(st_crs(usa)) %>%  # e.g. US National Atlas Equal Area
      dplyr::select(US_L3CODE, US_L3NAME, NA_L2CODE, NA_L2NAME, NA_L1CODE, NA_L1NAME) %>%
      st_make_valid() %>%
      st_intersection(., st_union(usa)) %>%
      setNames(tolower(names(.)))
    
    ecoreg_l3 <- st_read(dsn = ecoregion_prefix, layer = "us_eco_l3", quiet= TRUE) %>%
      st_transform(st_crs(usa)) %>%  # e.g. US National Atlas Equal Area
      dplyr::select(US_L3CODE, US_L3NAME, NA_L2CODE, NA_L2NAME, NA_L1CODE, NA_L1NAME) %>%
      st_make_valid() %>%
      st_intersection(., usa) %>%
      mutate(region = as.factor(if_else(NA_L1NAME %in% c("EASTERN TEMPERATE FORESTS",
                                                         "TROPICAL WET FORESTS",
                                                         "NORTHERN FORESTS"), "East",
                                        if_else(NA_L1NAME %in% c("NORTH AMERICAN DESERTS",
                                                                 "SOUTHERN SEMI-ARID HIGHLANDS",
                                                                 "TEMPERATE SIERRAS",
                                                                 "MEDITERRANEAN CALIFORNIA",
                                                                 "NORTHWESTERN FORESTED MOUNTAINS",
                                                                 "MARINE WEST COAST FOREST"), "West", "Central"))),
             regions = as.factor(if_else(region == "East" & stusps %in% c("FL", "GA", "AL", "MS", "LA", "AR", "TN", "NC", "SC", "TX", "OK"), "South East",
                                         if_else(region == "East" & stusps %in% c("ME", "NH", "VT", "NY", "PA", "DE", "NJ", "RI", "CT", "MI", "MD",
                                                                                  "MA", "WI", "IL", "IN", "OH", "WV", "VA", "KY", "MO", "IA", "MN"), "North East",
                                                 as.character(region))))) %>%
      setNames(tolower(names(.)))
    
    st_write(ecoreg_plain, file.path(ecoregion_out, 'us_eco_plain.gpkg'),
             driver = 'GPKG', delete_layer = TRUE)
    st_write(ecoreg_l3, file.path(ecoregion_out, 'us_eco_l3.gpkg'),
             driver = 'GPKG', delete_layer = TRUE)
    
    # system(paste0("aws s3 sync ", prefix, " ", s3_base))
    
  } else {
    ecoreg_plain <- sf::st_read( file.path(ecoregion_out, 'us_eco_plain.gpkg'))
    ecoreg_l3 <- sf::st_read(file.path(ecoregion_out, 'us_eco_l3.gpkg'))
  }
}

#Clean and prep the MTBS data to match the FPA database naming convention
if (!exists('mtbs_fire')) {
  if (!file.exists(file.path(mtbs_dir, "mtbs_conus.gpkg"))) {
    mtbs_fire <- st_read(dsn = mtbs_prefix,
                         layer = "mtbs_perims_DD", quiet= TRUE) %>%
      st_transform(st_crs(usa)) %>%
      st_make_valid()
    
    st_write(mtbs_fire, file.path(mtbs_dir, "mtbs_conus.gpkg"),
             driver = "GPKG", update=TRUE)
    
    # system(paste0("aws s3 sync ", fire_crt, " ", s3_fire_prefix))
  } else {
    mtbs_fire <- st_read(dsn = file.path(mtbs_dir, "mtbs_conus.gpkg"))
  }
}

# Intersect the ecoregions with the MTBS data
if (!exists('mtbs_ecoreg')) {
  if (!file.exists(file.path(mtbs_dir, "mtbs_ecoreg.gpkg"))) {
    mtbs_ecoreg <- mtbs_fire %>%
      st_intersection(., ecoreg_l1) %>%
      st_intersection(., ecoreg_l3)  %>%
      mutate(fire_km2 = as.numeric(st_area(geom))/1000000)
    
    st_write(mtbs_ecoreg, file.path(mtbs_dir, "mtbs_ecoreg.gpkg"),
             driver = "GPKG", delete_layer=TRUE)
    
    # system(paste0("aws s3 sync ", fire_crt, " ", s3_fire_prefix))
  } else {
    mtbs_ecoreg <- st_read(dsn = file.path(mtbs_dir, "mtbs_ecoreg.gpkg"))
    }
}

