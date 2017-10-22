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
    main = paste("data lines tread for table: ", tableId, sep = "")
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
  "select a.table_id from (select distinct table_id, count(*) as count FROM vulcanus_10_13.data_load_pioneer group by table_id) a where a.count > 5;"
)

for (table in tableIds$table_id) {
  dataTrend(table, con)
}

dbDisconnect(con)