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
    type = "o",
    main = paste("data lines trend for table: ", tableId, sep = "")
  )
}

dataQualityDistribute <- function() {
  dataQualityDist = dbGetQuery(
    con,
    "SELECT (missing_count/sample_count)*100 as rate FROM vulcanus_07_27.stats_general_attr_unique;"
  )
  
  class(dataQualityDist)
  class(dataQualityDist$rate)
  
  plot(density(na.omit(dataQualityDist$rate)), main = "dataQualityDistribute")
  
}

dataLinesDistribute <- function() {
  tableLines1H = dbGetQuery(
    con,
    "SELECT load_count FROM vulcanus_10_13.data_version_load where load_count < 100;"
  )
  tableLines1W = dbGetQuery(
    con,
    "SELECT load_count FROM vulcanus_10_13.data_version_load where load_count < 10000 and load_count >= 100;"
  )
  tableLines100W = dbGetQuery(
    con,
    "SELECT load_count FROM vulcanus_10_13.data_version_load where load_count < 1000000 and load_count >= 10000;"
  )
  tableLines10000W = dbGetQuery(
    con,
    "SELECT load_count FROM vulcanus_10_13.data_version_load where load_count < 100000000 and load_count >= 1000000;"
  )
  tableLines10000WPlus = dbGetQuery(
    con,
    "SELECT load_count FROM vulcanus_10_13.data_version_load where load_count > 100000000;"
  )
  
  plot(density(tableLines1H$load_count), main = "tableLines1H")
  
  plot(density(tableLines1W$load_count), main = "tableLines1W")
  
  plot(density(tableLines100W$load_count), main = "tableLines100W")
  
  plot(density(tableLines10000W$load_count), main = "tableLines10000W")
  
  # plot(density(na.omit(tableLines10000WPlus$load_count)), main = "tableLines10000WPlus")
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

# 解决乱码问题
dbSendQuery(con, "SET NAMES gbk;")
dbSendQuery(con, "SET CHARACTER SET gbk;")
dbSendQuery(con, "SET character_set_connection=gbk;")

dataQualityDistribute()

dataLinesDistribute()

tableIds = dbGetQuery(
  con,
  #"select a.table_id from (select distinct table_id, count(*) as count FROM vulcanus_10_13.data_load_pioneer group by table_id) a where a.count > 5;"
  "select a.table_id from (select distinct table_id, count(*) as count FROM vulcanus_10_13.data_load_pioneer group by table_id) a where a.count > 5 and a.table_id in (select distinct origin_table_id from vulcanus_10_13.o_t_table_mapping);"
)

print(paste("数据一个月条数变动5次以上，并且被目标表使用的源表有： ", tableIds, sep = ""))

for (table in tableIds$table_id) {
  dataTrend(table, con)
}

dbDisconnect(con)