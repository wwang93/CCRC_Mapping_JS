
### use county population as "demand" data
library(sf)
library(urbnmapr)
library(dplyr)
library(tidyverse)
library(haven)
library(tidycensus)


#########################################################
#fake “demand” data

## county level data


### get the county population data from tidycensus
county_population <- get_acs(
  geography = "county",
  variables = "B01003_001E", # Total population variable
  year = 2021,
  survey = "acs5"           # 5-year data
)

head(county_population)


### select  Geo_ID;Name and estimate
counties_population <- county_population %>%
  select(GEOID, NAME, estimate) %>%
  rename(county_fips = GEOID, county_name = NAME, population = estimate)

### get the urban map of counties
counties_sf1 <- get_urbn_map("counties", sf = TRUE)

### join counties_sf and counties_population
library(tidyverse)
counties_sf_size <- counties_sf1 %>%
  left_join(counties_population, by = c("county_fips" = "county_fips"))

counties_sf_size


counties_sf_size1 <- counties_sf_size %>%
  select(county_fips, county_name.y, population, geometry)%>%
  rename(county_name = county_name.y)

counties_sf_size1

counties_sf_size2 <- st_transform(counties_sf_size1, crs = 4326)

counties_sf_size2

counties_sf_size2 %>% write_rds("counties_sf_processed.rds")


### Simplified geometric data for faster loading

### The parameter dTolerance is adjusted according to your data range and desired precision.
counties_sf_simplified <- st_simplify(counties_sf_size2, dTolerance = 0.05, preserveTopology = TRUE)

### save the simplified data
write_rds(counties_sf_simplified, "counties_sf_simplified.rds")



## Commuting Zone level data

### read the commuting zone data
library(readr)
CZ_2000 <- read_csv("CZ_2000.csv")
View(CZ_2000)

CZ_2000 <- CZ_2000 %>%
  rename()




#########################################################
###supply data########
ipeds_green <- read_dta("raw-data/ipeds&green.dta")

ipeds_green_summed <- ipeds_green %>%
  group_by(unitid, greencat) %>%
  summarize(sum_cmplt_green = sum(cmplt_tot)) %>%
  filter(greencat != "") %>%
  spread(greencat, sum_cmplt_green)

ipeds_green_summed <- ipeds_green_summed %>% 
  pivot_longer(-unitid, names_to = "greencat", values_to = "size")

write_rds(ipeds_green_summed, "ipeds_green_summed.rds")



hdallyears <- read_dta("raw-data/hdallyears.dta")

hdallyears <- hdallyears %>%
  filter(year == 2020)

write_rds(hdallyears, "hdallyears.rds")