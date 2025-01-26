library(tidycensus)

county_population <- get_acs(
  geography = "county",
  variables = "B01003_001E", # 总人口变量
  year = 2021,
  survey = "acs5"           # 5年期数据
)

head(county_population)


### fake demand data(county population data)
library(dplyr)
# 选择county_population中的变量Geo_ID和Name和estimate
counties_population <- county_population %>%
  select(GEOID, NAME, estimate) %>%
  rename(county_fips = GEOID, county_name = NAME, population = estimate)


library(sf)
library(urbnmapr)
counties_sf1 <- get_urbn_map("counties", sf = TRUE)

# 将counties_sf和counties_population合并
library(tidyverse)
counties_sf_size <- counties_sf1 %>%
  left_join(counties_population, by = c("county_fips" = "county_fips"))

counties_sf_size1 <- counties_sf_size %>%
  select(county_fips, county_name.y, population, geometry)%>%
  rename(county_name = county_name.y)

# couties_sf_size是fake demand data

counties_sf_size2 <- st_transform(counties_sf_size1, crs = 4326)


library(sf)
library(urbnmapr)
library(mapboxer)
#counties_sf_size2 <- counties_sf_size2 %>% 
  #as_mapbox_source()

counties_sf_size2 %>% write_rds("counties_sf_processed.rds")



###supply data
ipeds_green <- read_dta("raw-data/ipeds&green.dta")

ipeds_green_summed <- ipeds_green %>%
  group_by(unitid, greencat) %>%
  summarize(sum_cmplt_green = sum(cmplt_tot)) %>%
  filter(greencat != "") %>%
  spread(greencat, sum_cmplt_green)

ipeds_green_summed <- ipeds_green_summed %>% 
  pivot_longer(-unitid, names_to = "greencat", values_to = "size")

write_rds(ipeds_green_summed, "ipeds_green_summed.rds")

library(sf)
library(urbnmapr)
library(dplyr)
library(tidyverse)
library(haven)

hdallyears <- read_dta("raw-data/hdallyears.dta")

hdallyears <- hdallyears %>%
  filter(year == 2020)

write_rds(hdallyears, "hdallyears.rds")