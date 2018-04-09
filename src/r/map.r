data <-
  read.table("F:/work/newData/lalo.txt", sep = " ", head = FALSE)
data$V1 <- as.numeric(data$V1)
data$V2 <- as.numeric(data$V2)

library(ggmap)
library(mapproj)


## 画图
### 因为 Google map api 不能使用，只好手动加载背景图。

### 中国的经纬度信息
China <- c(
  left = 120,
  bottom = 29,
  right = 124,
  top = 32
)
Map <- get_stamenmap(China, zoom = 8, maptype = "toner-lite")
ggmap(Map, extent = "device") +
  geom_point(data = data,
             aes(x = V2, y = V1),
             color = "green",
             alpha = 0.5)
