---
title: spark-R纪要
date: 2017-06-09 11:31:12
tags: 
    - spark
    - R
    - learn
toc: true
---

[TOC]

## R资源
### 主页
- http://www.r-project.com

### CRAN comprehensive R archive network

### blog
- http://www.r-bloggers.com

### books
- 数据挖掘与R语言
- R语言实战
- R语言编程艺术

### 观点
- R成为统计、预测分析和数据可视化的全球通用语言

## 使用重点积累
1. RStudio 提供的cheatsheet非常简洁高效的表达了某技术的特点
    - eg: google(keywords=filetype:pdf rstudio cheatsheet)
    - https://www.rstudio.com/wp-content/uploads/2016/03/rmarkdown-cheatsheet-2.0.pdf


## 环境准备
### 编译spark
1. 准备源码：$SPARK_SRC_HOME=
1. 执行 
    ``` shell
        cd $SPARK_SRC_HOME
        mvn -Pyarn -Phive -Phive-thriftserver -Psparkr -Pbigtop-dist -Phadoop-2.6 -Dhadoop.version=2.6.0 -DskipTests clean package -X -e
    ```
2. 得到：
    ll $SPARK_SRC_HOME/R
    ``` shell
    -rwxr-xr-x 1 elasticsearch elasticsearch 3256 Dec 16 10:02 check-cran.sh
    -rw-r--r-- 1 elasticsearch elasticsearch 3232 Dec 16 10:02 CRAN_RELEASE.md
    -rwxr-xr-x 1 elasticsearch elasticsearch 1761 Dec 16 10:02 create-docs.sh
    -rw-r--r-- 1 elasticsearch elasticsearch  474 Dec 16 10:02 DOCUMENTATION.md
    -rw-r--r-- 1 elasticsearch elasticsearch 1175 Dec 16 10:02 install-dev.bat
    -rwxr-xr-x 1 elasticsearch elasticsearch 2136 Dec 16 10:02 install-dev.sh
    drwxr-xr-x 3 root          root          4096 Jun  8 16:56 lib
    -rw-r--r-- 1 elasticsearch elasticsearch 1300 Dec 16 10:02 log4j.properties
    drwxr-xr-x 7 elasticsearch elasticsearch 4096 Dec 16 10:02 pkg
    -rw-r--r-- 1 elasticsearch elasticsearch 3735 Dec 16 10:02 README.md
    -rwxr-xr-x 1 elasticsearch elasticsearch 2311 Dec 16 10:02 run-tests.sh
    -rw-r--r-- 1 elasticsearch elasticsearch 2291 Dec 16 10:02 WINDOWS.md
    ```
3. 测试代码：$SPARK_HOME/examples/src/main/r/dataframe.R
``` r
library(SparkR)

# Initialize SparkSession
sparkR.session(appName = "SparkR-DataFrame-example")

# Create a simple local data.frame
localDF <- data.frame(name=c("John", "Smith", "Sarah"), age=c(19, 23, 18))

# Convert local data frame to a SparkDataFrame
df <- createDataFrame(localDF)

# Print its schema
printSchema(df)
# root
#  |-- name: string (nullable = true)
#  |-- age: double (nullable = true)

# 已做更改，Create a DataFrame from a JSON file
path <- "/dev/datacenter/input/r/people.json"

peopleDF <- read.json(path)
printSchema(peopleDF)
# root
#  |-- age: long (nullable = true)
#  |-- name: string (nullable = true)

# Register this DataFrame as a table.
createOrReplaceTempView(peopleDF, "people")

# SQL statements can be run by using the sql methods
teenagers <- sql("SELECT name FROM people WHERE age >= 13 AND age <= 19")

# Call collect to get a local data.frame
teenagersLocalDF <- collect(teenagers)

# Print the teenagers in our dataset
print(teenagersLocalDF)

# Stop the SparkSession now
sparkR.session.stop()

```

4. 开发案例功能测试：
    1. 准备hdfs数据文件：
    ``` shell
    hadoop dfs -put $SPARK_HOME/examples/src/main/resources/people.json /dev/datacenter/input/r
    ```
    2. 数据文件：people.json
    ``` json
    {"name":"Michael"}
    {"name":"Andy", "age":30}
    {"name":"Justin", "age":19}
    ```
    3. 运行
    ``` shell
    spark-submit ./examples/src/main/r/dataframe.R --master yarn-client
    ```
    4. 结果：
    ``` shell
    2017-06-15 17:15:07,567 INFO  [nioEventLoopGroup-2-2] codegen.CodeGenerator: Code generated in 12.78201 ms
        name
    1 Justin    
    ```


## 实践
### R加载mysql数据
#### 环境准备
- $install.packages("RMySQL") 安装RMySQL 包\
- $library(RMySQL) 
- $help(package="RMySQL")
- $con <- dbConnect(MySQL(),host="host",dbname="dbname",user="root",password="passwd")
- $summary(con)
- $dbGetInfo(con)
- $dbListTables(con)
- $dbRemoveTable(con,"test") 
- $dbDisconnect(con) #断开连接

``` r
    res <- dbGetQuery(con, "SELECT count, missing_count, unique_count FROM stats_general;")
    plot(res$unique_count, res$missing_count, xlab="unique()", ylab="missing()", main="graph_unique_missing")
    plot(res$count, res$missing_count, xlab="count()", ylab="missing()", main="graph_count_missing")
    plot(res$count, res$unique_count, xlab="count()", ylab="unique()", main="graph_count_unique")
```

- 注意RStudio 提供的compile & report功能
``` r
dataTrend <- function(tableId, con) {
  res <-
    dbGetQuery(
      con,
      paste(
        "SELECT date_format(start_date,'%m-%d') as day, count, table_id FROM vulcanus_10_13.data_load_pioneer where table_id = ",
        tableId,
        ";",
        sep = ""
      )
    )
  res$day <- as.Date(res$day, "%m-%d")
  plot(
    x = res$day,
    y = res$count,
    xlab = "day()",
    ylab = "count()",
    xlim = NULL,
    ylim = NULL,
    type = "b",
    main = paste("data lines trend for table: ", tableId, sep = "")
  )
}

library(RMySQL)
con <-
  dbConnect(
    MySQL(),
    host = "master66",
    dbname = "vulcanus_10_13",
    user = "root",
    password = "Hik12345+"
  )

tableIds = dbGetQuery(
  con,
  "select a.table_id from (select distinct table_id, count(*) as count FROM vulcanus_10_13.data_load_pioneer group by table_id) a where a.count > 3;"
)

for (table in tableIds$table_id) {
  dataTrend(table, con)
}

dbDisconnect(con)
```

- 经纬度地图可视化
``` R
data <- read.table("F:/work/newData/lalo.txt", sep = " ", head = FALSE)
data$V1 <- as.numeric(data$V1)
data$V2 <- as.numeric(data$V2)

library(ggmap)
library(mapproj)


#画图
#因为 Google map api 不能使用，只好手动加载背景图。

#中国的经纬度信息
#China <- c(left = 118, bottom = 25, right = 130, top = 32)
China <- c(left = 121, bottom = 29, right = 124, top = 31)
Map <- get_stamenmap(China, zoom = 10, maptype = "toner-lite")
ggmap(Map, extent = "device") +
  geom_point(data = data, aes(x = V2, y = V1), color = "red", alpha = 0.1) 
```

- 网络图
``` R
nodes <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18)
fromNs <- c(12, 9, 5, 10, 1, 17, 14, 6, 13, 4, 10, 10, 14, 11, 12, 7, 4, 1, 15, 10)
toNs <- c(9, 5, 10, 1, 17, 14, 7, 2, 1, 8, 16, 3, 4, 18, 4, 4, 11, 4, 2, 6)
edges <- data.frame(fromNs, toNs)

library(igraph)
net <- graph.data.frame(edges, nodes, directed=T)
plot(net, layout=layout_with_fr(net))
```

``` R
#可交互的网络图
nodes <- data.frame(id = 1:18, label = paste("n", 1:18))
from <-
  c(12, 9, 5, 10, 1, 17, 14, 6, 13, 4, 10, 10, 14, 11, 12, 7, 4, 1, 15, 10)
to <-
  c(9, 5, 10, 1, 17, 14, 7, 2, 1, 8, 16, 3, 4, 18, 4, 4, 11, 4, 2, 6)
edges <-
  data.frame(
    from,
    to,
    arrows = c("to", "from", "middle", "middle;to"),
    # smooth
    smooth = c(FALSE, TRUE),
    # shadow
    shadow = c(FALSE, TRUE, FALSE, TRUE),
    label = paste("e", 1:20)
  )

require(visNetwork, quietly = TRUE)
visNetwork(nodes,
           edges,
           height = "1000px",
           width = "100%",
           main = "Network!")
```

#### 

## 命令积累
``` r
install.packages("ISLR")

install.packages("ggplot2")
install.packages("rmarkdown")
install.packages("xtable")


install.packages('maps')
install.packages('ggmap')   #经纬度地图展现

install.packages("networkD3")
install.packages("igraph")
install.packages("ggnet2")

install.packages("threejs")

install.packages("visNetwork") #可拖动的网络图R库

install.packages("xlsx")    #excel file read        read.xlsx("datafile.xlsx", 1)
install.packages("gdata")   #xls filetype excel     read.xls("datafile.xls")
```

## 读书纪要

### R语言实战（R  in action）

#### R语言介绍


#### 创建数据集



#### 图形初阶



#### 基本数据管理



#### 高级数据管理



#### 基本图形




#### 基本统计分析



#### 回归



#### 方差分析


#### 功效分析


#### 中级绘图



#### 重抽样与自助法



#### 广义线性模型



#### 主成分和因子分析



#### 处理缺失数据的高级方法




#### 高级图形进阶



#### 附录



#### 探索R的世界





## 问题记录
1. pandoc.exe: pdflatex not found. pdflatex is needed for pdf output.
错误: pandoc document conversion failed with error 41
此外: There were 50 or more warnings (use warnings() to see the first 50)
停止执行
- 需求:R脚本通过RStudio compile&report 生成pdf格式结果文件
- 解决办法:
 


