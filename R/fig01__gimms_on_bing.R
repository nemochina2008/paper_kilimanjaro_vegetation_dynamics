## working directory
library(Orcs)
setwdOS(path_ext = "publications/paper/detsch_et_al__ndvi_dynamics/figures/data")

## packages
lib <- c("raster", "rgdal", "plyr", "Rsenal", "OpenStreetMap", "ggplot2")
sapply(lib, function(x) library(x, character.only = TRUE))

## functions
source("../../../../../repositories/paper_kilimanjaro_scintillometer/R/visKili.R")

## gimms 8-km
fls_gimms <- "geo198107-VI3g_crp_utm_wht_aggmax.tif"
rst_gimms <- raster(fls_gimms)
template <- rasterToPolygons(rst_gimms)
template_ll <- spTransform(template, CRS("+init=epsg:4326"))

template_ll@data$id <- rownames(template_ll@data)
template_ll_points <- fortify(template_ll, region = "id")

## modis 1-km
fls_prd <- list.files("MODIS_ARC/PROCESSED/", pattern = "^MOD14A1", 
                      full.names = TRUE, recursive = TRUE)
rst_prd <- raster(fls_prd)
rst_prd <- crop(rst_prd, kiliAerial(rasterize = TRUE))

rst_prd_crp <- crop(rst_prd, template[c(53, 54, 62, 63), ], snap = "out")
template_1km_crp <- rasterToPolygons(rst_prd_crp)
template_1km_crp <- crop(template_1km_crp, template[c(53, 54, 62, 63), ])
template_1km_crp_ll <- spTransform(template_1km_crp, CRS("+init=epsg:4326"))

template_1km_crp_ll@data$id <- rownames(template_1km_crp_ll@data)
template_1km_crp_ll_points <- fortify(template_1km_crp_ll, region = "id")

## bing aerial image
ext_gimms <- projectExtent(template, "+init=epsg:4326")

kili.map <- openproj(openmap(upperLeft = c(ymax(ext_gimms), xmin(ext_gimms)), 
                             lowerRight = c(ymin(ext_gimms), xmax(ext_gimms)), 
                             type = "bing", minNumTiles = 12L), 
                             projection = "+init=epsg:4326")

# quadrant margins
ext_tmp <- extent(template_ll)
num_cntr_x <- xmin(ext_tmp) + (xmax(ext_tmp) - xmin(ext_tmp)) / 2
num_cntr_y <- ymin(ext_tmp) + (ymax(ext_tmp) - ymin(ext_tmp)) / 2

## np borders
np_old <- readOGR(dsn = "shp/", 
                  layer = "fdetsch-kilimanjaro-national-park-1420535670531", 
                  p4s = "+init=epsg:4326")
# np_old_utm <- spTransform(np_old, CRS("+init=epsg:21037"))

np_old@data$id <- rownames(np_old@data) #join id column to data slot on SpatialLinesDataFrame
np_old_df <- fortify(np_old,region="id") #create data frame from SpatialLinesDataFrame
np_old_df <- join(np_old_df, np_old@data, by="id") #add Turbity information to the data frame object

np_new <- readOGR(dsn = "shp/", layer = "fdetsch-kilimanjaro-1420532792846", 
                  p4s = "+init=epsg:4326")
# np_new_utm <- spTransform(np_new, CRS("+init=epsg:21037"))

np_new@data$id <- rownames(np_new@data) #join id column to data slot on SpatialLinesDataFrame
np_new_df <- fortify(np_new,region="id") #create data frame from SpatialLinesDataFrame
np_new_df <- join(np_new_df, np_new@data, by="id") #add Turbity information to the data frame object

## visualization
p_bing <- autoplot(kili.map) + 
  geom_polygon(aes(long, lat), data = np_new_df, colour = "grey75", 
               lwd = 1.1, fill = "transparent") + 
  geom_polygon(aes(long, lat), data = np_old_df, colour = "grey75", 
               lwd = 1, linetype = "dotted", fill = "transparent") + 
  #   geom_polygon(aes(long, lat, group = group), template_ll_points, lwd = .5, 
  #                fill = "transparent", colour = "black") + 
  #   geom_polygon(aes(long, lat, group = group), template_1km_crp_ll_points, lwd = .3,
  #                fill = "transparent", colour = "black") + 
  geom_hline(aes(yintercept = num_cntr_y), colour = "black", lty = "dashed", 
             lwd = .7) +
  geom_vline(aes(xintercept = num_cntr_x), colour = "black", lty = "dashed", 
             lwd = .7) + 
  scale_x_continuous(breaks = seq(37, 37.6, .2), expand = c(.001, 0),
                     labels = paste(seq(37, 37.6, .2), "°E")) + 
  scale_y_continuous(breaks = seq(-3.4, -3, .2), expand = c(.001, 0), 
                     labels = paste(seq(3.4, 3, -.2), "°S")) +
  labs(x = "Longitude", y = "Latitude") + 
  theme(axis.title.x = element_text(size = rel(1.2)), 
        axis.text.x = element_text(size = rel(1), colour = "black"), 
        axis.title.y = element_text(size = rel(1.2)), 
        axis.text.y = element_text(size = rel(1), colour = "black"), 
        text = element_text(family = "Arial", colour = "black"))

p_topo <- visKili()

png("vis/fig01__map_w|o_grid.png", units = "cm", width = 20, 
    height = 16, res = 300, pointsize = 18)

# satellite image
grid.newpage()
print(p_bing, newpage = FALSE)

# topo map
vp_cont <- viewport(x = .7, y = .635, just = c("left", "bottom"), 
                    width = .275, height = .325)
pushViewport(vp_cont)
print(p_topo, newpage = FALSE)

dev.off()
