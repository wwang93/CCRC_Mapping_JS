# prepare_mask_polygon.R
# 目的：从 rnaturalearth 获取美国边界，并生成“世界 - 美国”的差集，用于在 Mapbox 上做掩膜

library(rnaturalearth)
library(rnaturalearthdata)
library(sf)
library(dplyr)
library(geojsonio)

# . 获取美国各州边界 (states)，并转换为 sf 格式
# ne_states() 返回全世界各国的“州/省”边界信息，我们只筛选美国
us_states <- ne_states(country = "United States of America", returnclass = "sf")



# . 将所有州合并为一个多边形（全国边界）
us_polygon <- st_union(us_states)

# . 确保坐标系为 WGS84 (EPSG:4326)，与 Mapbox 一致
us_polygon <- st_transform(us_polygon, crs = 4326)

# . 创建一个覆盖全球的多边形（世界）
coords <- matrix(c(-180, -90,
                   180, -90,
                   180, 90,
                   -180, 90,
                   -180, -90),
                 ncol = 2, byrow = TRUE)
world_polygon <- st_polygon(list(coords)) %>%
  st_sfc(crs = 4326) %>%
  st_sf()

# . 计算差集：世界 - 美国(本土48州)
mask_polygon <- st_difference(world_polygon, us_polygon)

#  导出为 GeoJSON，供前端 Mapbox 加载
geojson_write(mask_polygon, file = "mask_polygon.geojson")

cat("掩膜多边形已生成并保存到 mask_polygon.geojson。\n")
